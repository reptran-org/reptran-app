import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';

class NudgeSessionService {
  static Future<void> startFromNudge(
    BuildContext context, {
    String? userWorkoutId,
    String? templateId,
  }) async {
    try {
      final session = await SessionService().startSession(
        userWorkoutId: userWorkoutId,
        templateId: templateId,
      );

      final sessionId = session['id']?.toString();


      if (!context.mounted) return;

      // ✅ Nudge always opens logger directly
      context.push(
        '/workout/logger',
        extra: sessionId,
      );
    } catch (e) {
    }
  }

  
}
