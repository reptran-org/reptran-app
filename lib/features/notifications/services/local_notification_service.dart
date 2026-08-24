import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:reptran_app/features/notifications/services/nudge_intent_handler.dart';
import 'notification_image_cache.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const int activeWorkoutNotificationId = 999;

  /// 🔔 NUDGE CHANNEL
  static const AndroidNotificationChannel _workoutChannel =
      AndroidNotificationChannel(
        'trigger_nudges',
        'Workout Nudges',
        description: 'Workout reminders with actions',
        importance: Importance.max,
      );

  /// 💪 ACTIVE WORKOUT CHANNEL
  static const AndroidNotificationChannel _activeWorkoutChannel =
      AndroidNotificationChannel(
        'active_workout',
        'Active Workout',

        description: 'Shows current workout progress',
        importance: Importance.low,
      );

  static const AndroidNotificationChannel _generalChannel =
      AndroidNotificationChannel(
        'general_notifications',
        'General Notifications',
        description: 'Social and general updates',
        importance: Importance.high,
      );

  /// INIT
  static Future<void> init() async {
    const android = AndroidInitializationSettings('ic_notification');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_workoutChannel);
    await androidPlugin?.createNotificationChannel(_activeWorkoutChannel);
    await androidPlugin?.createNotificationChannel(_generalChannel);
  }

  static Future<void> showActiveSet({
    required String sessionId,
    required String exercise,
    required int set,
    required int totalSets,
    required String valueText,
    String? imageUrl,
  }) async {
    String? imagePath;

    if (imageUrl != null) {
      try {
        imagePath = await NotificationImageCache.getImagePath(imageUrl);
      } catch (e) {}
    } else {}

    final androidDetails = AndroidNotificationDetails(
      'active_workout',
      'Active Workout',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
      icon: 'ic_notification',

      actions: const [
        AndroidNotificationAction(
          'COMPLETE_SET',
          'Complete Set',
          showsUserInterface: true,
          cancelNotification: false,
          allowGeneratedReplies: false,
        ),
      ],
    );

    await _plugin.show(
      id: activeWorkoutNotificationId,
      title: exercise,
      body: "Set $set/$totalSets • $valueText",
      payload: jsonEncode({"sessionId": sessionId}),
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> showNoExercise({required String sessionId}) async {
    final androidDetails = AndroidNotificationDetails(
      'active_workout',
      'Active Workout',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: 'ic_notification',
      actions: const [
        AndroidNotificationAction(
          'ADD_EXERCISE',
          'Add Exercise',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    await _plugin.show(
      id: activeWorkoutNotificationId,
      title: "Workout Started",
      body: "No exercises selected",
      payload: jsonEncode({"sessionId": sessionId}),
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> showRecovery({
    required String exercise,
    required int nextSet,
    required int totalSets,
    required String weight,
    required int reps,
    required int remaining,
    required int total,
    String? imageUrl,
  }) async {
    String? imagePath;

    if (imageUrl != null) {
      imagePath = await NotificationImageCache.getImagePath(imageUrl);
    }

    final androidDetails = AndroidNotificationDetails(
      'active_workout',
      'Active Workout',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      showProgress: true,
      autoCancel: false,
      maxProgress: total,
      progress: remaining,
      largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
      icon: 'ic_notification',
      actions: const [
        AndroidNotificationAction(
          'SKIP',
          'Skip',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'MINUS_15',
          '-15s',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'PLUS_15',
          '+15s',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;

    final time = minutes > 0
        ? "$minutes:${seconds.toString().padLeft(2, '0')}"
        : "0:${seconds.toString().padLeft(2, '0')}";

    await _plugin.show(
      id: activeWorkoutNotificationId,
      title: exercise,
      body: "Next: Set $nextSet/$totalSets ($weight × $reps)\nRest $time",
      payload: jsonEncode({"sessionId": "active"}),
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  /// STOP WORKOUT NOTIFICATION
  static Future<void> stopActiveWorkout() async {
    // FIX: Added named parameter id
    await _plugin.cancel(id: activeWorkoutNotificationId);
  }

  /// HANDLE ACTION TAPS
  @pragma('vm:entry-point')
  // In LocalNotificationService._onTap
  static void _onTap(NotificationResponse response) {
    Map<String, dynamic> payload = {};
    try {
      if (response.payload != null && response.payload!.isNotEmpty) {
        payload = jsonDecode(response.payload!);
      }
    } catch (e) {}

    // This will now actually be reached!
    NudgeIntentHandler.handle(
      action: response.actionId ?? '',
      payload: payload,
    );
  }

  static Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_notifications', // ✅ new channel
      'General Notifications',
      channelDescription: 'Social and general updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: jsonEncode(payload),
    );
  }

  /// WORKOUT NUDGE
  static Future<void> showWorkoutNudge({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'trigger_nudges',
      'Workout Nudges',
      channelDescription: 'Workout reminders with actions',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
      actions: [
        AndroidNotificationAction(
          'START_NOW',
          'Start',
          showsUserInterface: true,
        ),
        AndroidNotificationAction('SNOOZE', 'Snooze', showsUserInterface: true),
      ],
    );

    // FIX: Added named parameters id, title, body, notificationDetails, and payload
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: jsonEncode(payload),
    );
  }
}

// import 'dart:convert';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:reptran_app/features/notifications/services/nudge_intent_handler.dart';

// class LocalNotificationService {
//   static final _plugin = FlutterLocalNotificationsPlugin();

//   // 🔔 ANDROID CHANNEL (MUST BE CREATED ONCE)
//   static const AndroidNotificationChannel _workoutChannel =
//       AndroidNotificationChannel(
//         'trigger_nudges', // MUST match AndroidNotificationDetails.channelId
//         'Workout Nudges',
//         description: 'Workout reminders with actions',
//         importance: Importance.max,
//       );

//       static const AndroidNotificationChannel _activeWorkoutChannel =
//     AndroidNotificationChannel(
//   'active_workout',
//   'Active Workout',
//   description: 'Shows current workout progress',
//   importance: Importance.low,
// );

// static Future<void> showActiveSet({
//   required String exercise,
//   required int set,
//   required int totalSets,
//   required String weight,
//   required int reps,
//   String? imagePath,
// }) async {
//   final androidDetails = AndroidNotificationDetails(
//     'active_workout',
//     'Active Workout',
//     importance: Importance.low,
//     priority: Priority.low,
//     ongoing: true,
//     onlyAlertOnce: true, // Good choice to avoid constant pinging on updates
//     largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
//     actions: const [
//       AndroidNotificationAction(
//         'COMPLETE_SET',
//         'Complete Set',
//         showsUserInterface: false,
//       ),
//     ],
//   );

//   await _plugin.show(
//     id: 999, // Label added
//     title: exercise, // Label added
//     body: "Set $set/$totalSets • $weight × $reps", // Label added
//     notificationDetails: NotificationDetails(android: androidDetails), // Label added
//   );
// }


// static Future<void> showRecovery({
//   required String exercise,
//   required int nextSet,
//   required int totalSets,
//   required String weight,
//   required int reps,
//   required int remaining,
//   required int total,
//   String? imagePath,
// }) async {
//   final androidDetails = AndroidNotificationDetails(
//     'active_workout',
//     'Active Workout',
//     importance: Importance.low,
//     priority: Priority.low,
//     ongoing: true,
//     onlyAlertOnce: true,
//     showProgress: true,
//     maxProgress: total,
//     progress: total - remaining,
//     largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
//     actions: const [
//       AndroidNotificationAction('SKIP', 'Skip'),
//       AndroidNotificationAction('MINUS_15', '-15s'),
//       AndroidNotificationAction('PLUS_15', '+15s'),
//     ],
//   );

//   await _plugin.show(
//     id: 999, // Added 'id:'
//     title: exercise, // Added 'title:'
//     body: "Next: Set $nextSet/$totalSets ($weight × $reps)", // Added 'body:'
//     notificationDetails: NotificationDetails(android: androidDetails), // Added 'notificationDetails:'
//   );
// }


// static Future<void> updateActiveWorkout({
//   required String title,
//   required String body,
// }) async {
//   await showActiveWorkout(title: title, body: body);
// }

// static Future<void> stopActiveWorkout() async {
//   // Add 'id:' here
//   await _plugin.cancel(id: 999); 
// }

//   static Future<void> init() async {
//     const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const settings = InitializationSettings(android: android);

//     await _plugin.initialize(
//       settings: settings,
//       onDidReceiveNotificationResponse: _onTap,
//     );

//     // ✅ CREATE ANDROID CHANNEL EXPLICITLY
//     final androidPlugin = _plugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >();

//     await androidPlugin?.createNotificationChannel(_workoutChannel);
//   }

//   @pragma('vm:entry-point')
//   static void _onTap(NotificationResponse response) {
//     final String action = response.actionId ?? '';
//     final Map<String, dynamic> payload = response.payload != null
//         ? jsonDecode(response.payload!)
//         : <String, dynamic>{};

//     NudgeIntentHandler.handle(action: action, payload: payload);
//   }

//   static Future<void> showWorkoutNudge({
//     required int id,
//     required String title,
//     required String body,
//     required Map<String, dynamic> payload,
//   }) async {
//     const androidDetails = AndroidNotificationDetails(
//       'trigger_nudges',
//       'Workout Nudges',
//       channelDescription: 'Workout reminders with actions',
//       importance: Importance.max,
//       priority: Priority.high,
//       actions: [
//         AndroidNotificationAction(
//           'START_NOW',
//           'Start',
//           showsUserInterface: true,
//         ),
//         AndroidNotificationAction('SNOOZE', 'Snooze', showsUserInterface: true),
//       ],
//     );

//     await _plugin.show(
//       id: id,
//       title: title,
//       body: body,
//       notificationDetails: const NotificationDetails(android: androidDetails),
//       payload: jsonEncode(payload), // ✅ JSON ONLY
//     );
//   }
// }
