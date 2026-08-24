import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:reptran_app/features/workout/presentation/state/active_workout_controller.dart';
import '../services/session_service.dart';

class ActiveSessionRestore {
  static Future<void> restore(BuildContext context) async {
    try {
      final res = await SessionService().getActiveSession();

      if (res == null) return;

      final startedAt = DateTime.parse(res["startedAt"]).toLocal();

      final exercises = (res["exercises"] ?? []) as List;

      // Same normalization logic as logger
      for (final ex in exercises) {
        final map = ex as Map<String, dynamic>;

        map["notes"] ??= "";

        if (map["restSeconds"] is! int || map["restSeconds"] < 5) {
          map["restSeconds"] = null;
        } else {
          map["restSeconds"] = (map["restSeconds"] as int).clamp(5, 300);
        }
      }

      

      final active = context.read<ActiveWorkoutController>();

      if (active.isActive) return;

      active.start(
        sessionId: res["id"],
        startedAt: startedAt,
        workoutName: "Workout",
        exercises: exercises.cast<Map<String, dynamic>>(),
      );

    } catch (e) {
    }
  }
}
