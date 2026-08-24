import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/services/routine_service.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class PlanDetailsPage extends StatelessWidget {
  final Map<String, dynamic> routine;
final bool isActive;

  const PlanDetailsPage({super.key, required this.routine, required this.isActive,});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = scheme.brightness == Brightness.dark;

    final days = List<Map<String, dynamic>>.from(routine["days"] ?? []);
    final schedule = routine["schedule"] ?? {};
    final scheduleType = (schedule["type"] ?? "CYCLE").toString().toUpperCase();
    final isCycle = scheduleType == "CYCLE";

    Future<void> startSessionAndOpenLogger(
      BuildContext context, {
      String? userWorkoutId,
    }) async {
      try {
        final session = await SessionService().startSession(
          userWorkoutId: userWorkoutId,
        );
        final sessionId = session["id"]?.toString();
        if (sessionId == null || sessionId.isEmpty) return;
        if (context.mounted) {
          context.push('/workout/logger', extra: sessionId);
        }
      } catch (e) {
      }
    }

    final sessions = days.map<_Session>((d) {
      String title;
      int exercises = 0;
      String? workoutId;
      final dayIndex = (d["dayIndex"] ?? 0) as int;
      final type = (d["type"] ?? "WORKOUT").toString();

      if (d["template"] != null) {
        final t = Map<String, dynamic>.from(d["template"]);
        title = t["title"] ?? "Workout";
        workoutId = t["id"];
        exercises = (t["exercises"] as List?)?.length ?? 0;
      } else if (d["userWorkout"] != null) {
        final u = Map<String, dynamic>.from(d["userWorkout"]);
        title = u["title"] ?? "Workout";
        workoutId = u["id"];
        exercises = (u["exercises"] as List?)?.length ?? 0;
      } else if (type == "REST") {
        title = "Rest";
      } else {
        title = d["title"] ?? "Session ${dayIndex + 1}";
      }

      return _Session(
        title: title,
        exercises: exercises,
        duration: exercises * 5,
        workoutId: workoutId,
        dayIndex: dayIndex,
        isRest: type == "REST",
      );
    }).toList();

    int nextIndex = 0;
    if (sessions.isNotEmpty) {
      if (isCycle) {
        nextIndex = (routine["cycleIndex"] ?? 0) % sessions.length;
      } else {
        final today = DateTime.now().weekday - 1; // 0=Mon … 6=Sun
        nextIndex = today.clamp(0, sessions.length - 1);
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutralDark : AppColors.neutralLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Bar ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      0,
                    ),
                    child: Row(
                      children: [
                        _NavButton(
                          icon: PhosphorIconsRegular.arrowLeft,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          routine["title"] ?? "Plan",
                          style: tt.titleMedium?.copyWith(
                            fontWeight: AppTypography.wSemibold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                     _MoreMenuButton(
  isActive: isActive,
 onSetActive: () async {
  try {
    await RoutineService().setActiveRoutine(routine["id"]);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          content: const Row(
            children: [
              Icon(
                PhosphorIconsRegular.checkCircle,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  "Plan set as active.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: AppTypography.wMedium,
                    fontSize: AppTypography.body,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
     Navigator.pop(context, true);
  } catch (e) {
  }
},
  onEdit: () {
    context.push(
      "/workout/plan-builder",
      extra: {"mode": "edit", "routineId": routine["id"]},
    );
  },
  onDelete: () async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Delete plan?"),
      content: const Text(
        "This will permanently delete this plan.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (ok != true) return;

  try {
    await RoutineService().deleteRoutinePermanently(
      routineId: routine["id"],
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        dismissDirection: DismissDirection.horizontal,
        content: const Row(
          children: [
            Icon(
              PhosphorIconsRegular.trash,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                "Plan deleted.",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: AppTypography.wMedium,
                  fontSize: AppTypography.body,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 400));

  if (context.mounted) {
  Navigator.pop(context, true); // 🔥 trigger refresh
}
  } catch (e) {
  }
},
),
                      
                      
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Hero: Next Session Card ───────────────────────
                  if (sessions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: _NextSessionCard(
                        session: sessions[nextIndex],
                        onStart: () {
                          final s = sessions[nextIndex];
                          if (s.workoutId == null) return;
                          startSessionAndOpenLogger(
                            context,
                            userWorkoutId: s.workoutId!,
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Plan Info Card ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: _PlanInfoCard(
                      sessions: sessions,
                      isCycle: isCycle,
                      cycleIndex: nextIndex,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Schedule View: CYCLE or WEEKLY ────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: isCycle
                        ? _CycleScheduleView(
                            sessions: sessions,
                            nextIndex: nextIndex,
                          )
                        : _WeeklyScheduleView(
                            sessions: sessions,
                            todayIndex: nextIndex,
                          ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Adjust ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: _AdjustTile(
                      onTap: () => _openAdjustSheet(
                        context,
                        sessions,
                        nextIndex,
                        routine["id"],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Motivation ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: const _MotivationBanner(),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAdjustSheet(
    BuildContext context,
    List<_Session> sessions,
    int nextIndex,
    String routineId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AdjustSheet(
        onTrainToday: () {
          Navigator.pop(context);

          _openSessionPicker(context, sessions, nextIndex);
        },

        onSkip: () async {
          Navigator.pop(context);

          try {
            await RoutineService().skipRoutine(routineId);

            if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(AppSpacing.sm),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    backgroundColor: AppColors.primary,
    duration: const Duration(seconds: 2),
    dismissDirection: DismissDirection.horizontal,
    content: Row(
      children: [
        const Icon(
          PhosphorIconsRegular.skipForward,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.xs),
        const Expanded(
          child: Text(
            "Session skipped. Next workout is ready.",
            style: TextStyle(
              color: Colors.white,
              fontWeight: AppTypography.wMedium,
              fontSize: AppTypography.body,
            ),
          ),
        ),
      ],
    ),
  ),
);
Navigator.pop(context, true);
            }
          } catch (e) {
          }
        },

        onRealign: () {
          Navigator.pop(context);

          _openRealignPicker(context, sessions, routineId);
        },

        onPause: () async {
          Navigator.pop(context);

          try {
            await RoutineService().pauseRoutine(routineId);
          } catch (e) {
          }
        },

        onEdit: () {
          Navigator.pop(context);

          context.push(
            "/workout/plan-builder",
            extra: {"mode": "edit", "routineId": routineId},
          );
        },
      ),
    );
  }
}

void _openSessionPicker(
  BuildContext context,
  List<_Session> sessions,
  int recommendedIndex,
) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) {
      return _SessionPicker(
        sessions: sessions,
        recommendedIndex: recommendedIndex,
      );
    },
  );
}

void _openRealignPicker(
  BuildContext context,
  List<_Session> sessions,
  String routineId,
) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,

    builder: (_) {
      return _RealignPicker(
        sessions: sessions,
        routineId: routineId,
        parentContext: context,
      );
    },
  );
}
// ─────────────────────────────────────────────────────────────────────────────
// Next Session Hero Card
// ─────────────────────────────────────────────────────────────────────────────

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({required this.session, required this.onStart});
  final _Session session;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isRest = session.isRest;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRest
              ? [AppColors.secondary.withValues(alpha: 0.85), AppColors.primary]
              : [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -32,
            right: -32,
            child: _DecorCircle(size: 130, opacity: 0.07),
          ),
          Positioned(
            bottom: -16,
            right: 48,
            child: _DecorCircle(size: 72, opacity: 0.05),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBadge(
                  label: isRest ? "REST DAY" : "UP NEXT",
                  icon: isRest
                      ? PhosphorIconsRegular.moon
                      : PhosphorIconsRegular.play,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  session.title,
                  style: tt.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.wBold,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (!isRest) ...[
                  Row(
                    children: [
                      _HeroStat(
                        icon: PhosphorIconsRegular.barbell,
                        label: "${session.exercises} exercises",
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _HeroStat(
                        icon: PhosphorIconsRegular.clock,
                        label: "~${session.duration} min",
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HeroCTA(label: "Start Workout", onTap: onStart),
                ] else ...[
                  Text(
                    "Take it easy today. You've earned it.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: AppTypography.caption,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(AppRadii.xs),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: AppTypography.wSemibold,
            letterSpacing: 1.3,
          ),
        ),
      ],
    ),
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.6)),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: AppTypography.caption,
          fontWeight: AppTypography.wMedium,
        ),
      ),
    ],
  );
}

class _HeroCTA extends StatelessWidget {
  const _HeroCTA({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.whiteUtility,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            PhosphorIconsRegular.play,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          const Text(
            "Start Workout",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: AppTypography.wSemibold,
              fontSize: AppTypography.body,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanInfoCard extends StatelessWidget {
  const _PlanInfoCard({
    required this.sessions,
    required this.isCycle,
    required this.cycleIndex,
  });

  final List<_Session> sessions;
  final bool isCycle;
  final int cycleIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final workoutCount = sessions.where((s) => !s.isRest).length;
    final restCount = sessions.where((s) => s.isRest).length;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeBadge(isCycle: isCycle),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  isCycle ? "Rotating cycle" : "Fixed weekly schedule",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: AppTypography.wMedium,
                    color: scheme.onSurface.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: "${sessions.length}",
                    label: "Total days",
                    icon: PhosphorIconsRegular.calendarBlank,
                  ),
                ),
                _VertDivider(),
                Expanded(
                  child: _StatTile(
                    value: "$workoutCount",
                    label: "Workouts",
                    icon: PhosphorIconsRegular.barbell,
                  ),
                ),
                _VertDivider(),
                Expanded(
                  child: _StatTile(
                    value: isCycle
                        ? "${cycleIndex + 1}/${sessions.length}"
                        : "$restCount",
                    label: isCycle ? "Position" : "Rest days",
                    icon: isCycle
                        ? PhosphorIconsRegular.arrowsClockwise
                        : PhosphorIconsRegular.moon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.isCycle});
  final bool isCycle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: isCycle
          ? AppColors.primary.withValues(alpha: 0.10)
          : AppColors.secondary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadii.xs),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCycle
              ? PhosphorIconsRegular.arrowsClockwise
              : PhosphorIconsRegular.calendarDots,
          size: 11,
          color: isCycle ? AppColors.primary : AppColors.secondary,
        ),
        const SizedBox(width: 4),
        Text(
          isCycle ? "CYCLE" : "WEEKLY",
          style: TextStyle(
            fontSize: 10,
            fontWeight: AppTypography.wSemibold,
            letterSpacing: 1.1,
            color: isCycle ? AppColors.primary : AppColors.secondary,
          ),
        ),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: AppTypography.wSemibold,
              color: scheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: scheme.outline.withValues(alpha: 0.4),
      indent: 4,
      endIndent: 4,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CYCLE Schedule View
// ─────────────────────────────────────────────────────────────────────────────

class _CycleScheduleView extends StatelessWidget {
  const _CycleScheduleView({required this.sessions, required this.nextIndex});

  final List<_Session> sessions;
  final int nextIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel("Rotation"),
        const SizedBox(height: AppSpacing.xs),
        _CycleProgressBar(
          total: sessions.length,
          current: nextIndex,
          scheme: scheme,
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
            boxShadow: AppShadows.e1(scheme),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Column(
              children: List.generate(sessions.length, (i) {
                return _CycleSessionRow(
                  session: sessions[i],
                  position: i + 1,
                  isNext: i == nextIndex,
                  isDone: i < nextIndex,
                  isLast: i == sessions.length - 1,
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _CycleProgressBar extends StatelessWidget {
  const _CycleProgressBar({
    required this.total,
    required this.current,
    required this.scheme,
  });

  final int total;
  final int current;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return Row(
      children: List.generate(total, (i) {
        final isActive = i == current;
        final isDone = i < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : isActive
                  ? AppColors.primary
                  : scheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
          ),
        );
      }),
    );
  }
}

class _CycleSessionRow extends StatelessWidget {
  const _CycleSessionRow({
    required this.session,
    required this.position,
    required this.isNext,
    required this.isDone,
    required this.isLast,
  });

  final _Session session;
  final int position;
  final bool isNext;
  final bool isDone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = scheme.brightness == Brightness.dark;

    Color avatarBg;
    Color avatarFg;
    if (isNext) {
      avatarBg = AppColors.primary;
      avatarFg = AppColors.whiteUtility;
    } else if (isDone) {
      avatarBg = AppColors.primary.withValues(alpha: 0.12);
      avatarFg = AppColors.primary;
    } else {
      avatarBg = scheme.surfaceContainerHighest;
      avatarFg = scheme.onSurface.withValues(alpha: AppOpacities.secondary);
    }

    return Container(
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.primary.withValues(alpha: isDark ? 0.10 : 0.05)
            : Colors.transparent,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: scheme.outline.withValues(alpha: 0.35),
                ),
              ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: avatarBg,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: isDone
              ? Icon(
                  PhosphorIconsRegular.checkCircle,
                  size: 16,
                  color: AppColors.primary,
                )
              : Text(
                  "$position",
                  style: TextStyle(
                    fontWeight: AppTypography.wSemibold,
                    fontSize: 13,
                    color: avatarFg,
                  ),
                ),
        ),
        title: Text(
          session.title,
          style: tt.bodyMedium?.copyWith(
            fontWeight: isNext
                ? AppTypography.wSemibold
                : AppTypography.wRegular,
            color: isNext
                ? AppColors.primary
                : scheme.onSurface.withValues(
                    alpha: isDone ? AppOpacities.secondary : 1.0,
                  ),
          ),
        ),
        subtitle: session.isRest
            ? null
            : Text(
                "${session.exercises} exercises · ~${session.duration} min",
                style: tt.bodySmall?.copyWith(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),
        trailing: isNext
            ? _NextBadge()
            : Icon(
                PhosphorIconsRegular.caretRight,
                size: 15,
                color: scheme.onSurface.withValues(
                  alpha: AppOpacities.tertiary,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEKLY Schedule View
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyScheduleView extends StatelessWidget {
  const _WeeklyScheduleView({required this.sessions, required this.todayIndex});

  final List<_Session> sessions;
  final int todayIndex;

  static const _dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel("This Week"),
        const SizedBox(height: AppSpacing.xs),

        // 7-bubble day strip
        Row(
          children: List.generate(7, (i) {
            final hasSession = i < sessions.length;
            final session = hasSession ? sessions[i] : null;
            final isToday = i == todayIndex;
            final isRest = session?.isRest ?? true;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 6 ? 5 : 0),
                child: _WeekDayBubble(
                  day: _dayAbbr[i],
                  isToday: isToday,
                  isRest: isRest,
                  hasSession: hasSession,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: AppSpacing.sm),

        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
            boxShadow: AppShadows.e1(scheme),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Column(
              children: List.generate(sessions.length, (i) {
                return _WeeklySessionRow(
                  session: sessions[i],
                  dayAbbr: i < 7 ? _dayAbbr[i] : "D${i + 1}",
                  isToday: i == todayIndex,
                  isLast: i == sessions.length - 1,
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekDayBubble extends StatelessWidget {
  const _WeekDayBubble({
    required this.day,
    required this.isToday,
    required this.isRest,
    required this.hasSession,
  });

  final String day;
  final bool isToday;
  final bool isRest;
  final bool hasSession;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;
    Color dotColor;

    if (isToday) {
      bgColor = AppColors.primary;
      textColor = AppColors.whiteUtility;
      dotColor = AppColors.whiteUtility;
    } else if (!hasSession || isRest) {
      bgColor = scheme.surfaceContainerHighest.withValues(alpha: 0.5);
      textColor = scheme.onSurface.withValues(alpha: AppOpacities.tertiary);
      dotColor = scheme.onSurface.withValues(alpha: AppOpacities.disabled);
    } else {
      bgColor = AppColors.secondary.withValues(alpha: 0.12);
      textColor = AppColors.secondary;
      dotColor = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday
                  ? AppTypography.wSemibold
                  : AppTypography.wMedium,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor.withValues(
                alpha: (isRest || !hasSession) ? 0.3 : 0.8,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySessionRow extends StatelessWidget {
  const _WeeklySessionRow({
    required this.session,
    required this.dayAbbr,
    required this.isToday,
    required this.isLast,
  });

  final _Session session;
  final String dayAbbr;
  final bool isToday;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withValues(alpha: isDark ? 0.10 : 0.05)
            : Colors.transparent,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: scheme.outline.withValues(alpha: 0.35),
                ),
              ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        leading: Container(
          width: 42,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primary
                : session.isRest
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
                : AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Text(
            dayAbbr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: AppTypography.wSemibold,
              color: isToday
                  ? AppColors.whiteUtility
                  : session.isRest
                  ? scheme.onSurface.withValues(alpha: AppOpacities.secondary)
                  : AppColors.secondary,
            ),
          ),
        ),
        title: Text(
          session.title,
          style: tt.bodyMedium?.copyWith(
            fontWeight: isToday
                ? AppTypography.wSemibold
                : AppTypography.wRegular,
            color: isToday ? AppColors.primary : null,
          ),
        ),
        subtitle: session.isRest
            ? null
            : Text(
                "${session.exercises} exercises · ~${session.duration} min",
                style: tt.bodySmall?.copyWith(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),
        trailing: isToday
            ? _NextBadge()
            : Icon(
                PhosphorIconsRegular.caretRight,
                size: 15,
                color: scheme.onSurface.withValues(
                  alpha: AppOpacities.tertiary,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NextBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadii.full),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
    ),
    child: const Text(
      "Today",
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: AppTypography.wSemibold,
        letterSpacing: 0.1,
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: AppTypography.wSemibold,
        color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adjust Tile
// ─────────────────────────────────────────────────────────────────────────────

class _AdjustTile extends StatelessWidget {
  const _AdjustTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(
              PhosphorIconsRegular.slidersHorizontal,
              size: 18,
              color: AppColors.secondary,
            ),
          ),
          title: const Text(
            "Adjust Plan",
            style: TextStyle(
              fontWeight: AppTypography.wMedium,
              fontSize: AppTypography.body,
            ),
          ),
          subtitle: Text(
            "Rest, skip, or edit sessions",
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            ),
          ),
          trailing: Icon(
            PhosphorIconsRegular.caretRight,
            size: 16,
            color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Motivation Banner
// ─────────────────────────────────────────────────────────────────────────────

class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(
              PhosphorIconsRegular.lightningA,
              size: 15,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Consistency beats intensity.",
                  style: tt.bodySmall?.copyWith(
                    fontWeight: AppTypography.wSemibold,
                    color: AppColors.secondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Even a shorter session counts toward your progress.",
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.secondary.withValues(alpha: 0.70),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adjust Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AdjustSheet extends StatelessWidget {
  const _AdjustSheet({
    required this.onTrainToday,
    required this.onSkip,
    required this.onRealign,
    required this.onPause,
    required this.onEdit,
  });

  final VoidCallback onTrainToday;
  final VoidCallback onSkip;
  final VoidCallback onRealign;
  final VoidCallback onPause;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.xxl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.outline,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
            ),
          ),
          const Text(
            "Adjust",
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: AppTypography.wSemibold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          _SheetRow(
            "Train today",
            PhosphorIconsRegular.play,
            color: AppColors.primary,
            onTap: onTrainToday,
          ),

          _SheetRow(
            "Skip session",
            PhosphorIconsRegular.skipForward,
            color: AppColors.secondary,
            onTap: onSkip,
          ),

          _SheetRow(
            "Realign plan",
            PhosphorIconsRegular.arrowsClockwise,
            color: AppColors.secondary,
            onTap: onRealign,
          ),

          // _SheetRow(
          //   "Pause plan",
          //   PhosphorIconsRegular.pause,
          //   color: AppColors.secondary,
          //   onTap: onPause,
          // ),
          Divider(
            height: AppSpacing.sm,
            color: scheme.outline.withValues(alpha: 0.4),
          ),

          _SheetRow(
            "Edit plan",
            PhosphorIconsRegular.pencilSimple,
            color: AppColors.accent,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow(
    this.label,
    this.icon, {
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: AppTypography.wMedium,
          fontSize: AppTypography.body,
        ),
      ),
      trailing: Icon(
        PhosphorIconsRegular.caretRight,
        size: 15,
        color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Nav buttons
// ─────────────────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _MoreMenuButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onSetActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MoreMenuButton({
    required this.isActive,
    required this.onSetActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, size: 18),

        onSelected: (value) {
          switch (value) {
            case "active":
              onSetActive();
              break;
            case "edit":
              onEdit();
              break;
            case "delete":
              onDelete();
              break;
          }
        },

        itemBuilder: (_) {
          final items = <PopupMenuEntry<String>>[];

          if (!isActive) {
            items.add(
              const PopupMenuItem(
                value: "active",
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.checkCircle, size: 18),
                    SizedBox(width: 10),
                    Text("Set Active"),
                  ],
                ),
              ),
            );
          }

          items.add(
            const PopupMenuItem(
              value: "edit",
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                  SizedBox(width: 10),
                  Text("Edit Plan"),
                ],
              ),
            ),
          );

          items.add(const PopupMenuDivider());

          items.add(
            const PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.trash,
                    size: 18,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Delete Plan",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );

          return items;
        },
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _Session {
  final String title;
  final int exercises;
  final int duration;
  final String? workoutId;
  final int dayIndex;
  final bool isRest;

  const _Session({
    required this.title,
    required this.exercises,
    required this.duration,
    required this.workoutId,
    required this.dayIndex,
    required this.isRest,
  });
}

class _SessionPicker extends StatelessWidget {
  const _SessionPicker({
    required this.sessions,
    required this.recommendedIndex,
  });

  final List<_Session> sessions;
  final int recommendedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Choose Session",
              style: TextStyle(
                fontSize: AppTypography.title,
                fontWeight: AppTypography.wSemibold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            ...List.generate(sessions.length, (i) {
              final s = sessions[i];
              final isRecommended = i == recommendedIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _SessionCard(session: s, isRecommended: isRecommended),
              );
            }),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.isRecommended});

  final _Session session;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () async {
        if (session.workoutId == null) return;

        try {
          final sessionData = await SessionService().startSession(
            userWorkoutId: session.workoutId!,
          );

          final sessionId = sessionData["id"]?.toString();

          if (!context.mounted) return;

          Navigator.pop(context);

          if (sessionId != null) {
            context.push('/workout/logger', extra: sessionId);
          }
        } catch (e) {
        }
      },

      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isRecommended
                ? AppColors.primary
                : scheme.outline.withValues(alpha: 0.5),
          ),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: session.isRest
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                session.isRest
                    ? PhosphorIconsRegular.moon
                    : PhosphorIconsRegular.barbell,
                color: session.isRest ? AppColors.secondary : AppColors.primary,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: const TextStyle(
                      fontWeight: AppTypography.wSemibold,
                      fontSize: AppTypography.body,
                    ),
                  ),
                  if (!session.isRest)
                    Text(
                      "${session.exercises} exercises · ~${session.duration} min",
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: const Text(
                  "Recommended",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: AppTypography.wSemibold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RealignPicker extends StatelessWidget {
  const _RealignPicker({
    required this.sessions,
    required this.routineId,
    required this.parentContext,
  });

  final List<_Session> sessions;
  final String routineId;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Realign Plan",
                style: TextStyle(
                  fontSize: AppTypography.title,
                  fontWeight: AppTypography.wSemibold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "Choose which session should come next.",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              ...List.generate(sessions.length, (i) {
                final s = sessions[i];

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _RealignSessionCard(
                    session: s,
                    index: i,
                    routineId: routineId,
                    parentContext: parentContext,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _RealignSessionCard extends StatelessWidget {
  const _RealignSessionCard({
    required this.session,
    required this.index,
    required this.routineId,
    required this.parentContext,
  });

  final _Session session;
  final int index;
  final String routineId;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () async {
        Navigator.pop(context, true);

        try {
          await RoutineService().realignRoutine(routineId, index);

          if (parentContext.mounted) {
           ScaffoldMessenger.of(parentContext).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(AppSpacing.sm),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    backgroundColor: AppColors.primary,
    duration: const Duration(seconds: 2),
    content: Row(
      children: [
        const Icon(
          PhosphorIconsRegular.checkCircle,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            "Next session updated to ${session.title}.",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: AppTypography.wMedium,
              fontSize: AppTypography.body,
            ),
          ),
        ),
      ],
    ),
  ),
);
          }
        } catch (e) {
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: session.isRest
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                session.isRest
                    ? PhosphorIconsRegular.moon
                    : PhosphorIconsRegular.barbell,
                color: session.isRest ? AppColors.secondary : AppColors.primary,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: const TextStyle(
                      fontWeight: AppTypography.wSemibold,
                      fontSize: AppTypography.body,
                    ),
                  ),

                  if (!session.isRest)
                    Text(
                      "${session.exercises} exercises · ~${session.duration} min",
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: const Text(
                "Set as Next",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: AppTypography.wSemibold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
