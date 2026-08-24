// workout_routes.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'package:reptran_app/features/workout/presentation/pages/execise_details_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/exercise_search_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/plan_details_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/progress_tracker_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/session_summary_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/user_workout_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/workout_complete_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/workout_history_details_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/workout_history_page.dart';

import 'package:reptran_app/features/workout/presentation/pages/workout_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/workout_logger_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/workout_plan_builder_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/workout_templates_page.dart';
import 'package:reptran_app/features/workout/presentation/pages/workout_template_details_page.dart';

class WorkoutRoutes {
  static const String path = '/workout';

  /// Parent route renders the WorkoutPage for "/workout"
  static GoRoute route() => GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: const WorkoutPage(),
      transitionsBuilder: _transition,
    ),
    routes: [
      // /workout/logger -> WorkoutLoggerPage
      GoRoute(
        name: 'workoutLogger',
        path: 'logger',
        pageBuilder: (context, state) {
          final sessionId = state.extra as String;

          return CustomTransitionPage(
            key: state.pageKey,
            child: WorkoutLoggerPage(sessionId: sessionId),
            transitionsBuilder: _transition,
          );
        },
      ),

     GoRoute(
  name: 'workoutComplete',
  path: 'workout-complete',
  pageBuilder: (context, state) {
    final extra = state.extra;

    String sessionId;
    Map<String, dynamic>? preview;

    if (extra is String) {
      // ✅ backward compatibility
      sessionId = extra;
    } else if (extra is Map<String, dynamic>) {
      sessionId = extra["sessionId"];
      preview = extra["preview"];
    } else {
      throw Exception("Invalid navigation data");
    }

    return CustomTransitionPage(
      key: state.pageKey,
      child: WorkoutCompletePage(
        sessionId: sessionId,
        preview: preview, // ✅ pass preview
      ),
      transitionsBuilder: _transition,
    );
  },
),
      GoRoute(
        name: 'sessionSummary',
        path: 'session-summary',
        pageBuilder: (context, state) {
          final sessionId = state.extra as String;

          return CustomTransitionPage(
            key: state.pageKey,
            child: SessionSummaryPage(sessionId: sessionId),
            transitionsBuilder: _transition,
          );
        },
      ),


GoRoute(
  name: 'exerciseSearch',
  path: 'exercise-search',
  pageBuilder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;

    final type = extra?["type"] as String? ?? "catalog";
    final id = extra?["id"] as String? ?? "";

    final mode = extra?["mode"] as String?;
    final replaceExerciseId = extra?["replaceExerciseId"] as String?;

    return CustomTransitionPage(
      key: state.pageKey,
      child: ExerciseSearchPage(
        targetType: type,
        targetId: id,
        mode: mode,
        replaceExerciseId: replaceExerciseId,
      ),
      transitionsBuilder: _transition,
    );
  },
),
      GoRoute(
        name: 'progressTracker',
        path: 'progress-tracker',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProgressTrackerPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'workoutHistory',
        path: 'workout-history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WorkoutHistoryPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'planBuilder',
        path: 'plan-builder',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: WorkoutPlanBuilderPage(
              mode: extra?["mode"]?.toString(),
              routineId: extra?["routineId"]?.toString(),
            ),
            transitionsBuilder: _transition,
          );
        },
      ),
GoRoute(
  name: 'planDetails',
  path: 'plan-details',
  pageBuilder: (context, state) {
    final data = state.extra as Map<String, dynamic>;

    final routine = data["routine"] as Map<String, dynamic>;
    final isActive = data["isActive"] as bool;

    return CustomTransitionPage(
      key: state.pageKey,
      child: PlanDetailsPage(
        routine: routine,
        isActive: isActive,
      ),
      transitionsBuilder: _transition,
    );
  },
),
      GoRoute(
        name: 'workoutTemplate',
        path: 'templates',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WorkoutTemplatesPage(),
          transitionsBuilder: _transition,
        ),
      ),
GoRoute(
  name: 'userWorkout',
  path: 'user-workout',
  pageBuilder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;

    final workoutId = extra["workoutId"] as String;
    final isNew = extra["isNew"] as bool? ?? false;

    return CustomTransitionPage(
      key: state.pageKey,
      child: UserWorkoutBuilderPage(
        workoutId: workoutId,
        isNew: isNew,
      ),
      transitionsBuilder: _transition,
    );
  },
),

      GoRoute(
        name: 'workoutTemplateDetails',
        path: 'templates/:templateId',
        pageBuilder: (context, state) {
          final templateId = state.pathParameters['templateId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: WorkoutTemplateDetailsPage(templateId: templateId),
            transitionsBuilder: _transition,
          );
        },
      ),

      GoRoute(
  name: 'workoutHistoryDetails',
  path: 'workout-history/:sessionId',
  pageBuilder: (context, state) {
    final sessionId = state.pathParameters['sessionId']!;

    return CustomTransitionPage(
      key: state.pageKey,
      child: WorkoutHistoryDetailsPage(sessionId: sessionId),
      transitionsBuilder: _transition,
    );
  },
),
      GoRoute(
  path: '/exercise/:exerciseId',
  builder: (context, state) {
    final id = state.pathParameters['exerciseId']!;
    return ExerciseDetailsPage(exerciseId: id);
  },
),
    ],
  );

  /// Registerable list for GoRouter
  static List<GoRoute> routes() => [route()];

  /// Shared transition animation
  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeScaleTransition(animation: animation, child: child);
}
