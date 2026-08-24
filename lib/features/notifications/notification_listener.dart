import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:reptran_app/features/home/presentation/pages/micro_nudge_modal.dart';
import 'package:reptran_app/features/home/presentation/pages/snooze_modal.dart';
import 'package:reptran_app/features/notifications/services/local_notification_service.dart';
import 'package:reptran_app/features/notifications/services/nudge_intent_handler.dart';
import 'package:reptran_app/features/notifications/services/trigger_service.dart';
import 'package:reptran_app/features/notifications/services/nudge_notification_service.dart';

class NotificationListenerWidget extends StatefulWidget {
  final Widget child;
  const NotificationListenerWidget({required this.child, super.key});

  @override
  State<NotificationListenerWidget> createState() =>
      _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState
    extends State<NotificationListenerWidget> {
  bool _nudgeVisible = false;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // void _handleForegroundMessage(RemoteMessage message) {
  //   if (_nudgeVisible) return;

  //   final rootContext = NudgeIntentHandler.navigatorKey.currentContext;
  //   if (rootContext == null) return;

  //   final data = message.data;
  //   final notif = message.notification;

  //   _nudgeVisible = true;
  //   SystemSound.play(SystemSoundType.alert);

  //   showDialog(
  //     context: rootContext,
  //     barrierDismissible: true,
  //     builder: (_) {
  //       return MicroNudgeModal(
  //         notificationId: data['notificationId'] ?? '',
  //         title: notif?.title ?? data['title'] ?? '',
  //         body: notif?.body ?? data['body'] ?? '',
  //         templateId: data['templateId'],
  //         userWorkoutId: data['userWorkoutId'],
  //         routineDayId: data['routineDayId'],
  //         onClose: _reset,
  //         onStart: () {
  //           _reset();
  //           _startFromNudge(data);
  //         },
  //         onSnooze: (ctx) {
  //           _reset();
  //           _openSnooze(ctx);
  //         },
  //       );
  //     },
  //   ).whenComplete(_reset);
  // }

  void _handleForegroundMessage(RemoteMessage message) {
    final rootContext = NudgeIntentHandler.navigatorKey.currentContext;
    if (rootContext == null) return;

    final data = message.data;
    final notif = message.notification;

    final type = data['type'];

    // 🔥 1. Handle workout nudge (existing)
    if (type == 'trigger.workout_nudge') {
      if (_nudgeVisible) return;

      _nudgeVisible = true;
      SystemSound.play(SystemSoundType.alert);

      showDialog(
        context: rootContext,
        barrierDismissible: true,
        builder: (_) {
          return MicroNudgeModal(
            notificationId: data['notificationId'] ?? '',
            title: notif?.title ?? data['title'] ?? '',
            body: notif?.body ?? data['body'] ?? '',
            templateId: data['templateId'],
            userWorkoutId: data['userWorkoutId'],
            routineDayId: data['routineDayId'],
            onClose: _reset,
            onStart: () {
              _reset();
              _startFromNudge(data);
            },
            onSnooze: (ctx) {
              _reset();
              _openSnooze(ctx);
            },
          );
        },
      ).whenComplete(_reset);

      return;
    }

    // 🔥 2. Handle reaction notification
    if (type == 'social.reaction') {
      _handleReactionNotification(message);
      return;
    }

    if (type == 'social.follow') {
  _handleFollowNotification(message);
  return;
}
  }

  void _handleFollowNotification(RemoteMessage message) async {
  final data = message.data;
  final notif = message.notification;

  final int notificationId =
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

  await LocalNotificationService.showSimpleNotification(
    id: notificationId,
    title: notif?.title ?? data['title'] ?? 'New follower 🎉',
    body: notif?.body ?? data['body'] ?? 'Someone followed you',
    payload: data,
  );
}

  void _handleReactionNotification(RemoteMessage message) async {
    final data = message.data;
    final notif = message.notification;

    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      2147483647,
    );

    final title =
    notif?.title ??
    data['title'] ??
    'New reaction 🔥';

final body =
    notif?.body ??
    data['body'] ??
    'Someone reacted to your activity';

    await LocalNotificationService.showSimpleNotification(
      id: notificationId,
      title:title,
      body:body,
      payload: data,
    );
  }

  void _reset() {
    _nudgeVisible = false;
  }

  /* ---------------- Start workout ---------------- */

  void _startFromNudge(Map<String, dynamic> data) {
    NudgeSessionService.startFromNudge(
      NudgeIntentHandler.navigatorKey.currentContext!,
      userWorkoutId: data['userWorkoutId'],
      templateId: data['templateId'],
    );
  }

  /* ---------------- Snooze handling ---------------- */

  Future<void> _openSnooze(BuildContext context) async {
    final int? result = await showDialog<int>(
      context: context,
      builder: (_) => const SnoozeModal(),
    );

    if (result == null) return;

    switch (result) {
      case 0:
        await TriggerService().snoozeMyTrigger(
          minutes: 2,
          overrideWindows: true,
          source: 'NUDGE',
        );
        break;

      case 1:
        break;

      case 2:
        await TriggerService().snoozeMyTrigger(
          minutes: _minutesUntilEndOfDay(),
          source: 'SKIP',
        );
        break;
    }
  }

  int _minutesUntilEndOfDay() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return end.difference(now).inMinutes.clamp(1, 1440);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
