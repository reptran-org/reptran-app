import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/presentation/pages/custom_exercises_modal.dart';
import 'package:reptran_app/features/workout/services/routine_service.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';
import 'package:reptran_app/features/workout/services/user_workout_service.dart';
import 'package:reptran_app/shared/widgets/app_scaffold.dart';
import 'package:reptran_app/shared/widgets/tab_item.dart';
import 'package:go_router/go_router.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});
  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

Future<void> createWorkoutAndOpenBuilder(BuildContext context) async {
  try {
    final workout = await UserWorkoutService().createWorkout();

    final workoutId = workout['id'];

    if (workoutId == null || workoutId.toString().isEmpty) {

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create workout. Try again.")),
        );
      }
      return;
    }


    if (context.mounted) {
      context.push(
        '/workout/user-workout',
        extra: {"workoutId": workoutId, "isNew": true},
      );
    }
  } catch (e) {

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error creating workout: $e")));
    }
  }
}

class _WorkoutPageState extends State<WorkoutPage> {
  // ===== Workouts =====
  List<dynamic> _workouts = [];
  bool _loadingWorkouts = true;
  String? _activeRoutineId;
  List<Map<String, dynamic>> _plans = [];

  List<dynamic> _recentSessions = [];
  bool _loadingRecent = true;

  // ===== Plans (Routines) =====
  bool _loadingPlans = true;

  Future<void> startSessionAndOpenLogger(
    BuildContext context, {
    String? userWorkoutId,
  }) async {
    try {
      final session = await SessionService().startSession(
        userWorkoutId: userWorkoutId,
      );

      final sessionId = session["id"]?.toString();

      if (sessionId == null || sessionId.isEmpty) {
        return;
      }

      if (context.mounted) {
        context.push('/workout/logger', extra: sessionId);
      }
    } catch (e) {
    }
  }

  Future<void> _fetchRecentSessions() async {
    try {
      final data = await SessionService().getRecentSessions();

      setState(() {
        _recentSessions = data;
      });
    } catch (e) {
    } finally {
      setState(() {
        _loadingRecent = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPlans();
    _fetchWorkouts();
    _fetchRecentSessions();
  }

  Future<void> _fetchPlans() async {
    try {
      final data = await RoutineService().getMyRoutines();

      setState(() {
        _plans = List<Map<String, dynamic>>.from(data["routines"]);
        _activeRoutineId = data["activeRoutineId"]?.toString();
      });
    } catch (e) {
    } finally {
      setState(() {
        _loadingPlans = false;
      });
    }
  }

  Future<void> _fetchWorkouts() async {
    try {
      final data = await UserWorkoutService().getMyWorkouts();
      setState(() {
        _workouts = data;
      });
    } catch (e) {
    } finally {
      setState(() {
        _loadingWorkouts = false;
      });
    }
  }

  int _estimateMinutesFromExerciseCount(int exerciseCount) {
    return (5 + (exerciseCount * 6)).clamp(15, 999);
  }

  String _getPlanTypeLabel(Map<String, dynamic> plan) {
    final schedule = plan["schedule"];

    // schedule may be Json or string depending on backend serialization
    if (schedule is Map) {
      final type = schedule["type"]?.toString().toUpperCase();
      if (type == "CYCLE") return "Rotation Plan";
      if (type == "WEEKLY") return "Weekly Plan";
    }

    final planType = plan["planType"]?.toString().toUpperCase();
    if (planType == "CYCLE") return "Rotation Plan";
    if (planType == "WEEKLY") return "Weekly Plan";

    return "Plan";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      current: TabItem.workout,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(cs: cs)),

          // 🔥 Actions row
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      title: "New Routine",
                      icon: PhosphorIconsRegular.plus,
                      onTap: () => createWorkoutAndOpenBuilder(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      title: "Templates",
                      icon: PhosphorIconsRegular.sparkle,
                      onTap: () {
                        context.push('/workout/templates');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==========================
          // ✅ My Plans section
          // ==========================
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                cs: cs,
                title: 'My Plans',
                actionLabel: 'View All',
                onTap: () {
                  context.push('/workout/plan-builder');
                },
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: _loadingPlans
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                : (_plans.isEmpty
                      ? SliverToBoxAdapter(
                          child: _NoPlansFallback(
                            cs: cs,
                            onCreate: () =>
                                context.push('/workout/plan-builder'),
                          ),
                        )
                      : SliverList.separated(
                          itemCount: _plans.length,
                          itemBuilder: (ctx, i) {
                            final p = Map<String, dynamic>.from(
                              _plans[i] as Map,
                            );

                            final routineId = (p["id"] ?? "").toString();
                            final isActive = routineId == _activeRoutineId;
                            final title = (p["title"] ?? "Plan").toString();
                            final desc = p["description"]?.toString();

                            final days = List<Map<String, dynamic>>.from(
                              p["days"] ?? [],
                            ).where((d) => d["type"] == "WORKOUT").toList();

                            final List<String> sessions = days.map<String>((d) {
                              if (d["template"] != null) {
                                return (d["template"]["title"] ?? "Workout")
                                    .toString();
                              }

                              if (d["userWorkout"] != null) {
                                return (d["userWorkout"]["title"] ?? "Workout")
                                    .toString();
                              }

                              return (d["title"] ??
                                      "Day ${(d["dayIndex"] ?? 0) + 1}")
                                  .toString();
                            }).toList();
                            final sessionCount = sessions.length;

                            final nextSession = sessionCount > 0
                                ? sessions[(p["cycleIndex"] ?? 0) %
                                      sessionCount]
                                : null;

                            return PlanCard(
                              cs: cs,
                              title: title,
                              planType: _getPlanTypeLabel(p),
                              sessionCount: sessionCount,
                              sessions: sessions,
                              nextSession: nextSession,
                              description: desc,
                              isActive: isActive,
                              onSetActive: () async {
                                await RoutineService().setActiveRoutine(
                                  routineId,
                                );
                                await _fetchPlans();
                              },
                           onTap: () async {
  final shouldRefresh = await context.pushNamed(
    "planDetails",
    extra: {"routine": p, "isActive": isActive},
  );

  if (shouldRefresh == true) {
    await _fetchPlans();
  }
},

                            onView: () async {
  final shouldRefresh = await context.pushNamed(
    "planDetails",
    extra: {"routine": p, "isActive": isActive},
  );

  if (shouldRefresh == true) {
    await _fetchPlans();
  }
},
                              onEdit: () {
                                context.push(
                                  '/workout/plan-builder',
                                  extra: {
                                    "mode": "edit",
                                    "routineId": routineId,
                                  },
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
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );

                                if (ok != true) return;

                                await RoutineService().deleteRoutinePermanently(
                                  routineId: routineId,
                                );

                                if (!mounted) return;
                                await _fetchPlans();
                              },
                            );
                          
                          
                          },

                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                        )),
          ),

          // ==========================
          // My Routines (Workouts)
          // ==========================
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                cs: cs,
                title: 'My Routines',
                // actionLabel: 'View All',
                onTap: () {
                  context.push('/workout/plan-builder');
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: _loadingWorkouts
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                : (_workouts.isEmpty
                      ? SliverToBoxAdapter(
                          child: _NoRoutinesFallback(
                            cs: cs,
                            onCreate: () =>
                                createWorkoutAndOpenBuilder(context),
                          ),
                        )
                      : SliverList.separated(
                          itemCount: _workouts.length,
                          itemBuilder: (ctx, i) {
                            final w = _workouts[i] as Map<String, dynamic>;
                            final workoutId = w["id"].toString();

                            final title = (w["title"] ?? "Workout").toString();
                            final exercises = (w["exercises"] ?? []) as List;

                            final exerciseCount = exercises.length;
                            final estMinutes =
                                _estimateMinutesFromExerciseCount(
                                  exerciseCount,
                                );

                            final routine = Routine(
                              title: title,
                              durationMins: estMinutes,
                              exercisesCount: exerciseCount,
                              chips: exercises
                                  .map(
                                    (x) => x["exercise"]?["name"]?.toString(),
                                  )
                                  .whereType<String>()
                                  .take(4)
                                  .toList(),
                            );

                            return RoutineCard(
                              routine: routine,
                              cs: cs,
                              workoutId: workoutId,
                              onStart: () {
                                startSessionAndOpenLogger(
                                  context,
                                  userWorkoutId: workoutId,
                                );
                              },
                              onEdit: () {
                                context.push(
                                  '/workout/user-workout',
                                  extra: {
                                    "workoutId": workoutId,
                                    "isNew": false,
                                  },
                                );
                              },
                              onDelete: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Delete routine?"),
                                    content: const Text(
                                      "This will permanently delete this workout.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );

                                if (ok != true) return;

                                await UserWorkoutService().deleteWorkout(
                                  workoutId: workoutId,
                                );
                                await _fetchWorkouts();
                              },
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                        )),
          ),

          // Recent Workouts
          if (!_loadingRecent && _recentSessions.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  cs: cs,
                  title: 'Recent Workouts',
                  actionLabel: 'View All',
                  onTap: () {
                    context.push('/workout/workout-history');
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentSessions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (ctx, i) {
                    final session = Map<String, dynamic>.from(
                      _recentSessions[i],
                    );

                    final item = _mapSessionToRecentWorkout(session);

                    return GestureDetector(
                      onTap: () {
                        context.push(
                          '/workout/session-summary',
                          extra: session["id"],
                        );
                      },
                      child: RecentWorkoutChip(item: item, cs: cs),
                    );
                  },
                ),
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            sliver: const SliverToBoxAdapter(child: _ToolsRow()),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// Header
// =======================================================

class _Header extends StatelessWidget {
  final ColorScheme cs;
  const _Header({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workouts',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ).copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to crush your goals? 💪',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.6),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _GradientButton(
                  cs: cs,
                  height: 56,
                  radius: 16,
                  colors: [cs.primary, cs.secondary],
                  icon: Icon(
                    PhosphorIconsFill.play,
                    size: 22,
                    color: Colors.white,
                  ),
                  gap: 8,
                  label: const Text(
                    'Start Workout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final session = await SessionService().startSession();
                      final sessionId = session['id'];

                      if (sessionId == null || sessionId.toString().isEmpty) {
                       
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Failed to start workout. Please try again.",
                            ),
                          ),
                        );
                        return;
                      }

                      context.push('/workout/logger', extra: sessionId);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error starting workout: $e")),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),

              // OutlinedButton.icon(
              //   onPressed: () {
              //     showDialog(
              //       context: context,
              //       builder: (_) => const CustomExerciseModal(),
              //     );
              //   },
              //   icon: Icon(
              //     PhosphorIconsRegular.plus,
              //     color: cs.primary,
              //     size: 20,
              //   ),
              //   label: Text(
              //     'New',
              //     style: TextStyle(
              //       fontSize: 16,
              //       fontWeight: FontWeight.w600,
              //       color: cs.primary,
              //     ),
              //   ),
              //   style: OutlinedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(horizontal: 16),
              //     minimumSize: const Size(0, 56),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(16),
              //     ),
              //     side: BorderSide(color: cs.primary, width: 1),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple gradient button
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.cs,
    this.onPressed,
    required this.label,
    this.icon,
    this.gap = 8,
    this.height = 48,
    this.radius = 16,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    Key? key,
  }) : super(key: key);

  final ColorScheme cs;
  final VoidCallback? onPressed;
  final Widget label;
  final Widget? icon;
  final double gap;
  final double height;
  final double radius;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: Ink(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: AppBorders.boxCard(cs),
          boxShadow: AppShadows.e1(cs),
          gradient: LinearGradient(begin: begin, end: end, colors: colors),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) icon!,
                if (icon != null) SizedBox(width: gap),
                label,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================
// Section header
// =======================================================

class _SectionHeader extends StatelessWidget {
  final ColorScheme cs;
  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.cs,
    required this.title,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: cs.onSurface,
    );

    final actionStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: cs.primary);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: text),

        // ✅ Only show action when label exists
        if (actionLabel != null && actionLabel!.isNotEmpty)
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(actionLabel!, style: actionStyle),
            ),
          ),
      ],
    );
  }
}

// =======================================================
// My Plans Card
// =======================================================

class PlanCard extends StatelessWidget {
  final ColorScheme cs;

  final String title;
  final String planType;
  final int sessionCount;
  final List<String> sessions;
  final bool isActive;

  final String? nextSession;
  final String? description;

  final VoidCallback? onTap;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetActive;

  const PlanCard({
    super.key,
    required this.cs,
    required this.title,
    required this.planType,
    required this.sessionCount,
    required this.sessions,
    this.nextSession,
    this.description,
    this.onTap,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.isActive = false,
    this.onSetActive,
  });

  void _openActionsSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Show only if NOT active
                if (!isActive)
                  ListTile(
                    leading: Icon(
                      Icons.check_circle_outline,
                      color: cs.primary,
                    ),
                    title: const Text("Set Active"),
                    onTap: () {
                      Navigator.pop(context);
                      onSetActive?.call();
                    },
                  ),

                if (!isActive) const SizedBox(height: 8),

                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Edit"),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit?.call();
                  },
                ),

                const SizedBox(height: 8),

                ListTile(
                  leading: Icon(Icons.delete, color: cs.error),
                  title: Text("Delete", style: TextStyle(color: cs.error)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: onTap ?? onView,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: AppBorders.boxCard(cs),
          boxShadow: AppShadows.e1(cs),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      if (isActive) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: .20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "ACTIVE",
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  onTap: () => _openActionsSheet(context),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: PhosphorIcon(
                      PhosphorIconsRegular.dotsThreeVertical,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xs),

            /// Plan type
            Text(
              planType,
              style: tt.bodySmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            /// Meta row
            Row(
              children: [
                Icon(
                  PhosphorIconsRegular.stack,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  "$sessionCount sessions",
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),

                const SizedBox(width: 16),

                Icon(
                  PhosphorIconsRegular.repeat,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  planType,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            /// Session chips
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: sessions.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    s,
                    style: tt.labelSmall?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

            if (nextSession != null) ...[
              const SizedBox(height: AppSpacing.sm),

              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cs.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  children: [
                    const PhosphorIcon(
                      PhosphorIconsRegular.arrowRight,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Next: $nextSession",
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            /// View plan button
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: onView ?? onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Text(
                    "View Plan",
                    style: tt.labelMedium?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// Existing models/widgets (unchanged)
// =======================================================

class Routine {
  final String title;
  final int durationMins;
  final int exercisesCount;
  final List<String> chips;
  const Routine({
    required this.title,
    required this.durationMins,
    required this.exercisesCount,
    required this.chips,
  });
}

class RoutineCard extends StatelessWidget {
  final ColorScheme cs;
  final Routine routine;

  // ✅ needed for starting session
  final String workoutId;

  // actions
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  // ✅ start workout action
  final VoidCallback? onStart;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.cs,
    required this.workoutId,
    this.onEdit,
    this.onDelete,
    this.onStart,
  });

  void _openActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Edit"),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit?.call();
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text("Delete"),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.e1(cs),
        border: AppBorders.boxCard(cs),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Title row + 3 dots
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  routine.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _openActionsSheet(context),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: PhosphorIcon(
                    PhosphorIconsRegular.dotsThreeVertical,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _RoutineMeta(
            cs: cs,
            duration: routine.durationMins,
            exercises: routine.exercisesCount,
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 16,
            children: routine.chips.map((c) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.neutralDark
                      : AppColors.neutralLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  c,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // ✅ Start Workout Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFFFF6B5A), Color(0xFFEB4335)],
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      boxShadow: AppShadows.e1(cs),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onStart, // ✅ call parent start logic
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Text(
                            'Start Workout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutineMeta extends StatelessWidget {
  final ColorScheme cs;

  final int duration;
  final int exercises;
  const _RoutineMeta({
    required this.duration,
    required this.exercises,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: cs.onSurface.withValues(alpha: 0.60),
    );
    return Row(
      children: [
        Icon(
          PhosphorIconsRegular.clock,
          size: 22,
          color: cs.onSurface.withValues(alpha: 0.60),
        ),
        const SizedBox(width: 4),
        Text('$duration mins', style: muted),
        const SizedBox(width: 16),
        Icon(
          PhosphorIconsFill.barbell,
          size: 22,
          color: cs.onSurface.withValues(alpha: 0.60),
        ),
        const SizedBox(width: 4),
        Text('$exercises exercises', style: muted),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.black87,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class RecentWorkout {
  final String title;
  final DateTime date;
  final int durationMins;
  final String note;
  final String emojis;
  const RecentWorkout({
    required this.title,
    required this.date,
    required this.durationMins,
    required this.note,
    required this.emojis,
  });
}

class RecentWorkoutChip extends StatelessWidget {
  final ColorScheme cs;
  final RecentWorkout item;

  const RecentWorkoutChip({super.key, required this.item, required this.cs});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final formattedDate = formatShortDate(item.date);
    final relative = timeAgo(item.date);

    return Container(
      width: 240,
      height: 100,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// DATE ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: text.labelSmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                relative,
                style: text.labelSmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// TITLE
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          /// META ROW (duration + emoji + note)
          Row(
            children: [
              Text(
                '${item.durationMins} mins',
                style: text.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.85),
                ),
              ),

              const SizedBox(width: 10),

              Text(item.emojis, style: const TextStyle(fontSize: 18)),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  item.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.75),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolsRow extends StatelessWidget {
  const _ToolsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight( // ✅ KEY FIX
      child: Row(
        children: const [
          Expanded(
            child: _ToolCard(
              icon: Icons.search,
              title: 'Exercise Database',
              subtitle: 'Browse exercises',
              route: '/workout/exercise-search',
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _ToolCard(
              icon: Icons.trending_up,
              title: 'Progress Tracker',
              subtitle: 'View your PRs',
              route: '/workout/progress-tracker',
            ),
          ),
        ],
      ),
    );
  }
}


class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route; // ⬅️ add this

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route, // ⬅️ add this
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.e1(cs),
        border: AppBorders.boxCard(cs),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(route), // ⬅️ navigate
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [cs.primary, cs.secondary],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: cs.onPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 52,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: AppBorders.boxCard(cs),
          boxShadow: AppShadows.e1(cs),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoRoutinesFallback extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onCreate;

  const _NoRoutinesFallback({required this.cs, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "No routines yet",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Create your first workout routine and it’ll show here.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 14),
          _ActionButton(
            title: "Create Routine",
            icon: PhosphorIconsRegular.plus,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

class _NoPlansFallback extends StatelessWidget {
  final ColorScheme cs;
  final VoidCallback onCreate;

  const _NoPlansFallback({required this.cs, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "No plans yet",
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Create a weekly or rotation plan to stay consistent — even on low-energy days.",
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [cs.primary, cs.secondary],
                      ),
                      boxShadow: AppShadows.e1(cs),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onCreate,
                      child: const Center(
                        child: Text(
                          "Create Plan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _moodToEmoji(String? mood) {
  switch (mood) {
    case "GREAT":
      return "🔥";
    case "GOOD":
      return "😌";
    case "OKAY":
      return "🙂";
    case "TOUGH":
      return "😮‍💨";
    default:
      return "💪";
  }
}

RecentWorkout _mapSessionToRecentWorkout(Map<String, dynamic> s) {
  final duration = s["durationMin"] ?? 0;

  final completedAt = s["completedAt"];

  final date = completedAt != null
      ? DateTime.tryParse(completedAt) ?? DateTime.now()
      : DateTime.now();

  final reflection = s["reflection"];

  final note = reflection?["note"] ?? "Workout completed";

  final emoji = _moodToEmoji(reflection?["mood"]);

  final workoutTitle =
      s["userWorkout"]?["title"] ?? s["routine"]?["title"] ?? "Workout";

  return RecentWorkout(
    title: workoutTitle,
    date: date,
    durationMins: duration,
    note: note,
    emojis: emoji,
  );
}

String formatShortDate(DateTime date) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return "${months[date.month]} ${date.day}";
}

String timeAgo(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inDays >= 7) {
    final weeks = (diff.inDays / 7).floor();
    return weeks == 1 ? "1 week ago" : "$weeks weeks ago";
  }

  if (diff.inDays >= 1) {
    return diff.inDays == 1 ? "1 day ago" : "${diff.inDays} days ago";
  }

  if (diff.inHours >= 1) {
    return diff.inHours == 1 ? "1 hour ago" : "${diff.inHours} hours ago";
  }

  return "Today";
}
