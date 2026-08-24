import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:reptran_app/features/notifications/services/nudge_notification_service.dart';
import 'package:reptran_app/features/home/presentation/pages/snooze_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:reptran_app/features/workout/presentation/state/active_workout_controller.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';

class NudgeIntentHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

static void handle({
  required String action,
  required Map<String, dynamic> payload,
}) {

  /// Actions that DO NOT require UI context
  switch (action) {
    case 'COMPLETE_SET':
      _completeSet();
      return;

    case 'SKIP':
      _skipRest();
      return;

    case 'PLUS_15':
      _adjustRest(15);
      return;

    case 'MINUS_15':
      _adjustRest(-15);
      return;
  }

  /// Actions that REQUIRE UI context
  final navigator = navigatorKey.currentState;
  final context = navigator?.context ?? navigatorKey.currentContext;

  if (context == null) {
    return;
  }

  switch (action) {
    case 'START_NOW':
      _start(context, payload);
      break;

    case 'SNOOZE':
      _snooze(context);
      break;

    case 'ADD_EXERCISE':
      _openExerciseSearch(context, payload);
      break;
  }
}

  /// SKIP REST
static void _skipRest() {
  final controller = ActiveWorkoutController.instance;
  if (controller == null) return;

  controller.skipRest();
}
  /// ADJUST REST (+15 / -15)
static void _adjustRest(int delta) {
  final controller = ActiveWorkoutController.instance;
  if (controller == null) return;

  controller.adjustRest(delta);
}

  static Future<void> _completeSet() async {
    final controller = ActiveWorkoutController.instance;
    if (controller == null) return;

    await controller.completeNextSet();
  }

  static void _start(BuildContext context, Map<String, dynamic> data) {
    NudgeSessionService.startFromNudge(
      context,
      userWorkoutId: data['userWorkoutId'],
      templateId: data['templateId'],
    );
  }

  static void _openExerciseSearch(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    GoRouter.of(context).push(
      '/workout/exercise-search',
      extra: {"type": "session", "id": data["sessionId"]},
    );
  }

  static void _snooze(BuildContext context) {
    showDialog(context: context, builder: (_) => const SnoozeModal());
  }
}


//  static void handle({
//   required String action,
//   required Map<String, dynamic> payload,
// }) {
//   final context = navigatorKey.currentContext;
//   if (context == null) return;

//   switch (action) {
//     case 'START_NOW':
//       _start(context, payload);
//       break;

//     case 'SNOOZE':
//       _snooze(context);
//       break;

//     /// WORKOUT ACTIONS
//     case 'ADD_EXERCISE':
//       _openExerciseSearch(context, payload);
//       break;

//     // case 'COMPLETE_SET':
//     //   _completeSet(payload);
//     //   break;

//     // case 'PLUS_15':
//     //   _adjustRest(payload, 15);
//     //   break;

//     // case 'MINUS_15':
//     //   _adjustRest(payload, -15);
//     //   break;

//     // case 'SKIP':
//     //   _skipRest(payload);
//     //   break;

//     default:
//       break;
//   }
// }
  