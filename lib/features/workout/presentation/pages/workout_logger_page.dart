import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:reptran_app/features/workout/services/session_service.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/active_workout_controller.dart';
import 'dart:ui';


class WorkoutLoggerPage extends StatefulWidget {
  final String sessionId;

  const WorkoutLoggerPage({super.key, required this.sessionId});

  @override
  State<WorkoutLoggerPage> createState() => _WorkoutLoggerPageState();
}

class _WorkoutLoggerPageState extends State<WorkoutLoggerPage> {
  Timer? _timer;

  final ScrollController _scrollController = ScrollController();
bool _showFloatingStats = false;

final GlobalKey _statsKey = GlobalKey();

  final Map<String, TextEditingController> _weightCtrls = {};
  final Map<String, TextEditingController> _repsCtrls = {};

  TextEditingController _getWeightCtrl(String setId, double? initial) {
    return _weightCtrls.putIfAbsent(setId, () {
      return TextEditingController(text: initial?.toString() ?? "");
    });
  }

  TextEditingController _getRepsCtrl(String setId, int? initial) {
    return _repsCtrls.putIfAbsent(setId, () {
      return TextEditingController(text: initial?.toString() ?? "");
    });
  }

  @override
  void initState() {
    super.initState();

    if (!context.read<ActiveWorkoutController>().isActive) {
      _fetchSession();
    }

    // Workout duration timer (unchanged)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

   _scrollController.addListener(() {
  final ctx = _statsKey.currentContext;
  if (ctx == null) return;

  final box = ctx.findRenderObject() as RenderBox;
  final position = box.localToGlobal(Offset.zero);

  // 🔥 buffer delay (tweak this)
  const double triggerOffset = -60;

  final shouldShow = position.dy < triggerOffset;

  if (shouldShow && !_showFloatingStats) {
    setState(() => _showFloatingStats = true);
  } else if (!shouldShow && _showFloatingStats) {
    setState(() => _showFloatingStats = false);
  }
});
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final c in _weightCtrls.values) {
      c.dispose();
    }
    for (final c in _repsCtrls.values) {
      c.dispose();
    }

    super.dispose();
  }

  Map<String, num> _computeStats(List<Map<String, dynamic>> exercises) {
    double volumeKg = 0;
    int totalSets = 0;

    for (final ex in exercises) {
      final sets = (ex["sets"] ?? []) as List;

      for (final s in sets) {
        final set = s as Map<String, dynamic>;
        final completed = set["completed"] == true;
        if (!completed) continue;

        totalSets++;

        final reps = (set["reps"] as int?) ?? 0;
        final weightKg = (set["weightKg"] as num?)?.toDouble() ?? 0.0;

        volumeKg += weightKg * reps;
      }
    }

    return {"volumeKg": volumeKg, "sets": totalSets};
  }

  String _formatDuration(DateTime? startedAt) {
    if (startedAt == null) return "00:00";

    final diff = DateTime.now().difference(startedAt);
    final totalSeconds = diff.inSeconds;

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      final h = hours.toString().padLeft(2, '0');
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return "$h:$m:$s";
    }

    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _fetchSession() async {
    try {
      final res = await SessionService().getSession(widget.sessionId);
      context.read<ActiveWorkoutController>().setSessionMeta(res);

      final startedAt = DateTime.parse(res["startedAt"]).toLocal();

      final exercises = (res["exercises"] ?? []) as List;

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

      active.start(
        sessionId: widget.sessionId,
        startedAt: startedAt,
        workoutName: "Workout",
        exercises: exercises.cast<Map<String, dynamic>>(),
      );
    } catch (e) {}
  }

  String _formatRest(dynamic seconds) {
    if (seconds == null || seconds == 0) {
      return "OFF";
    }

    if (seconds is! int || seconds < 5) {
      return "OFF";
    }

    final int s = seconds.clamp(5, 300);

    final m = s ~/ 60;
    final r = s % 60;

    if (m == 0) return "${r}s";
    if (r == 0) return "${m}m";
    return "${m}m ${r}s";
  }

Widget _buildStickyStatsBar({
  required ColorScheme scheme,
  required TextTheme textTheme,
  required bool isLight,
  required double volumeKg,
  required int setsCount,
  required ActiveWorkoutController active,
}) {
  return ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // 🔥 blur
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface.withOpacity(0.85), // 🔥 translucent
          border: Border(
            bottom: BorderSide(
              color: scheme.outline.withOpacity(0.2),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, // ✅ unchanged
          vertical: AppSpacing.xs,   // ✅ unchanged
        ),
        child: Row(
          children: [
            // Duration
            Expanded(
              child: _miniStat(
                "Duration",
                _formatDuration(active.startedAt),
                textTheme,
                scheme,
                isLight,
                align: CrossAxisAlignment.start,
              ),
            ),

            // Divider
            Container(
              height: 40, // ✅ same as original card
              width: 1,
              color: scheme.outline.withOpacity(0.2),
            ),

            // Volume
            Expanded(
              child: _miniStat(
                "Volume",
                "${volumeKg.toStringAsFixed(1)} kg",
                textTheme,
                scheme,
                isLight,
                align: CrossAxisAlignment.center,
              ),
            ),

            // Divider
            Container(
              height: 40,
              width: 1,
              color: scheme.outline.withOpacity(0.2),
            ),

            // Sets
            Expanded(
              child: _miniStat(
                "Sets",
                setsCount.toString(),
                textTheme,
                scheme,
                isLight,
                align: CrossAxisAlignment.end,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}



Widget _miniStat(
  String label,
  String value,
  TextTheme textTheme,
  ColorScheme scheme,
  bool isLight, {
  CrossAxisAlignment align = CrossAxisAlignment.center,
}) {
  return Column(
    crossAxisAlignment: align,
    children: [
      Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: scheme.onSurface.withOpacity(0.6),
        ),
      ),
      const SizedBox(height: 2),

      // 🔥 Smooth value update
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: Text(
          value,
          key: ValueKey(value),
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isLight ? scheme.primary : scheme.onSurface,
          ),
        ),
      ),
    ],
  );
}
 
 
 
 
 
 
 
  Widget _buildStatsCard({
  required ColorScheme scheme,
  required TextTheme textTheme,
  required bool isLight,
  required double volumeKg,
  required int setsCount,
  required ActiveWorkoutController active,
}) {
  return _Card(
    scheme: scheme,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duration', style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatDuration(active.startedAt),
                style: textTheme.titleMedium!.copyWith(
                  color: isLight ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Container(height: 40, width: 1, color: scheme.outline),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Volume', style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${volumeKg.toStringAsFixed(1)} kg',
                style: textTheme.titleMedium!.copyWith(
                  color: isLight ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Container(height: 40, width: 1, color: scheme.outline),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Sets', style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                setsCount.toString(),
                style: textTheme.titleMedium!.copyWith(
                  color: isLight ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    background: isLight
        ? AppColors.neutralLight
        : AppColors.neutralDark,
    radius: AppRadii.lg,
  );
}

  Future<void> finishWorkoutSession({
    required BuildContext context,
    required String sessionId,
  }) async {
    try {
      final result = await SessionService().endSession(sessionId: sessionId);

      context.read<ActiveWorkoutController>().clear();

     if (context.mounted) {
      context.go(
        '/workout/workout-complete',
        extra: {
          "sessionId": sessionId,
          "preview": result["rewardPreview"], // ✅ IMPORTANT
        },
      );
    }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to finish workout. Try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ActiveWorkoutController>();

    final sessionMeta = active.sessionMeta ?? {};

    final rawName = sessionMeta["user"]?["name"];
final name = _getDisplayName(rawName);
final title = sessionMeta["title"];
final weeklyIntent = sessionMeta["identity"]?["weeklyIntent"];
final archetype = sessionMeta["identity"]?["archetype"];

    final exercises = active.exercises.cast<Map<String, dynamic>>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;

    final stats = _computeStats(exercises);
    final volumeKg = stats["volumeKg"] as double;
    final setsCount = stats["sets"] as int;

    return Stack(
      children: [
        Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SafeArea(
              child:SingleChildScrollView(
  controller: _scrollController,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top framing
                      // const SizedBox(height: AppSpacing.xxl),

                      // FIRST SECTION (hasBg: true)
                      // DO NOT add horizontal padding at page root.
                      Container(
                        color: scheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xxl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: chevron (left), time + Finish button (right)
                              Row(
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      context.pop(); // minimize only
                                    },
                                    child: PhosphorIcon(
                                      PhosphorIconsRegular.caretDown,
                                      size: 24,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const Spacer(),

                                  // Time + icon
                                  Row(
                                    children: [
                                      PhosphorIcon(
                                        PhosphorIconsRegular.clock,
                                        size: 18,
                                        color: scheme.onSurface.withValues(
                                          alpha: AppOpacities.secondary,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xxs),
                                      Text(
                                        _formatDuration(active.startedAt),
                                        style: textTheme.bodySmall,
                                      ),

                                      const SizedBox(width: AppSpacing.sm),
                                      // Finish button (primary)
                                      GestureDetector(
                                        onTap: () async {
                                          await finishWorkoutSession(
                                            context: context,
                                            sessionId: widget.sessionId,
                                          );
                                        },

                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: scheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.md,
                                            ),
                                            boxShadow: AppShadows.e1(scheme),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                          ),
                                          constraints: const BoxConstraints(
                                            minHeight: 48,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Finish',
                                            style: textTheme.bodyMedium!
                                                .copyWith(
                                                  color: scheme.onSecondary,
                                                  fontWeight:
                                                      AppTypography.wBold,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Heading + Subheading
                              Text(
  name != null ? 'Keep building, $name 💪' : 'Keep building 💪',
  style: textTheme.headlineSmall!.copyWith(height: 1.2),
),
                              const SizedBox(height: AppSpacing.xs),
                             Text(
  '${title ?? "Workout"} in progress'
  '${weeklyIntent != null && archetype != null ? ' · I am a $weeklyIntent $archetype' : ''}',
  style: textTheme.bodyMedium!.copyWith(
    color: scheme.onSurface.withOpacity(AppOpacities.secondary),
  ),
),
                              const SizedBox(height: AppSpacing.sm),

                              // // Info alert card (soft tone)
                              // _Card(
                              //   scheme: scheme,
                              //   child: Row(
                              //     children: [
                              //       const PhosphorIcon(
                              //         PhosphorIconsRegular.fire,
                              //         size: 24,
                              //         color: AppColors.accent,
                              //       ),
                              //       const SizedBox(width: AppSpacing.xs),
                              //       Expanded(
                              //         child: Text(
                              //           'This workout keeps your 5-day streak alive · 1 more for Bronze Badge',
                              //           style: textTheme.bodyMedium!.copyWith(
                              //             color: AppColors.accent,
                              //           ),
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              //   background: AppColors.accent.withValues(alpha: 0.10),
                              //   radius: AppRadii.lg,
                              // ),
                              const SizedBox(height: AppSpacing.sm),

Container(
  key: _statsKey,
  child: _buildStatsCard(
    scheme: scheme,
    textTheme: textTheme,
    isLight: isLight,
    volumeKg: volumeKg,
    setsCount: setsCount,
    active: active,
  ),
),
                              // Stats card: Duration | Volume | Sets
                              // _Card(
                              //   scheme: scheme,
                              //   child: Row(
                              //     children: [
                              //       // Duration
                              //       Expanded(
                              //         child: Column(
                              //           crossAxisAlignment:
                              //               CrossAxisAlignment.start,
                              //           children: [
                              //             Text(
                              //               'Duration',
                              //               style: textTheme.bodySmall,
                              //             ),
                              //             const SizedBox(height: AppSpacing.xs),
                              //             Text(
                              //               _formatDuration(active.startedAt),
                              //               style: textTheme.titleMedium!
                              //                   .copyWith(
                              //                     color: isLight
                              //                         ? scheme.primary
                              //                         : scheme.onSurface,
                              //                   ),
                              //             ),
                              //           ],
                              //         ),
                              //       ),

                              //       // Divider
                              //       Container(
                              //         height: 40,
                              //         width: 1,
                              //         color: scheme.outline,
                              //       ),

                              //       // Volume
                              //       Expanded(
                              //         child: Column(
                              //           crossAxisAlignment:
                              //               CrossAxisAlignment.center,
                              //           children: [
                              //             Text(
                              //               'Volume',
                              //               style: textTheme.bodySmall,
                              //             ),
                              //             const SizedBox(height: AppSpacing.xs),
                              //             Text(
                              //               '${volumeKg.toStringAsFixed(1)} kg',
                              //               style: textTheme.titleMedium!
                              //                   .copyWith(
                              //                     color: isLight
                              //                         ? scheme.primary
                              //                         : scheme.onSurface,
                              //                   ),
                              //             ),
                              //           ],
                              //         ),
                              //       ),

                              //       // Divider
                              //       Container(
                              //         height: 40,
                              //         width: 1,
                              //         color: scheme.outline,
                              //       ),

                              //       // Sets
                              //       Expanded(
                              //         child: Column(
                              //           crossAxisAlignment:
                              //               CrossAxisAlignment.end,
                              //           children: [
                              //             Text(
                              //               'Sets',
                              //               style: textTheme.bodySmall,
                              //             ),
                              //             const SizedBox(height: AppSpacing.xs),
                              //             Text(
                              //               setsCount.toString(),
                              //               style: textTheme.titleMedium!
                              //                   .copyWith(
                              //                     color: isLight
                              //                         ? scheme.primary
                              //                         : scheme.onSurface,
                              //                   ),
                              //             ),
                              //           ],
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              //   background: isLight
                              //       ? AppColors.neutralLight
                              //       : AppColors.neutralDark,
                              //   radius: AppRadii.lg,
                              // ),
                            
                            
                            ],
                          ),
                        ),
                      ),

                      // Gap between sections
                      const SizedBox(height: AppSpacing.md),

                      // REST OF PAGE: apply horizontal padding normally
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Repeat workout cards (5 more cards requested)
                            const SizedBox(height: AppSpacing.xs),
                            if (exercises.isEmpty) ...[
                              _EmptyWorkoutState(),
                            ] else ...[
                              ...List.generate(exercises.length, (index) {
                                final ex =
                                    exercises[index] as Map<String, dynamic>;

                                final supersetGroup = ex["supersetGroup"];
                                final showSupersetChip = supersetGroup != null;
                                final sessionExerciseId = ex["id"].toString();

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    /// SUPerset chip
                                    if (showSupersetChip)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.xs,
                                          left: AppSpacing.xs,
                                        ),
                                        child: _SupersetChip(
                                          group: supersetGroup,
                                        ),
                                      ),

                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: _WorkoutCard(
                                        key: ValueKey(ex["id"]),
                                        scheme: scheme,
                                        textTheme: textTheme,
                                        exercise: ex,
                                        sessionId: widget.sessionId,
                                        onRefresh: () => context
                                            .read<ActiveWorkoutController>()
                                            .refreshFromBackend(),
                                        getWeightCtrl: _getWeightCtrl,
                                        getRepsCtrl: _getRepsCtrl,
                                        onLongPressSet: (setId) {
                                          _showSetActionsSheet(
                                            context,
                                            sessionId: widget.sessionId,
                                            sessionExerciseId:
                                                sessionExerciseId,
                                            setId: setId,
                                          );
                                        },

                                        onOpenExerciseMenu: () {
                                          _showExerciseActionsSheet(
                                            sessionId: widget.sessionId,
                                            sessionExerciseId:
                                                sessionExerciseId,
                                          );
                                        },
                                        onAddSet: () async {
                                          await SessionService().addSet(
                                            sessionId: widget.sessionId,
                                            sessionExerciseId:
                                                sessionExerciseId,
                                          );

                                          if (mounted) {
                                            await context
                                                .read<ActiveWorkoutController>()
                                                .refreshFromBackend();
                                          }
                                        },
                                        onUpdateSet:
                                            (setId, kg, reps, completed) async {
                                              await SessionService().updateSet(
                                                sessionId: widget.sessionId,
                                                sessionExerciseId:
                                                    sessionExerciseId,
                                                setId: setId,
                                                weightKg: kg,
                                                reps: reps,
                                                completed: completed,
                                              );

                                              if (mounted) {
                                                await context
                                                    .read<
                                                      ActiveWorkoutController
                                                    >()
                                                    .refreshFromBackend();
                                              }
                                            },
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],

                            // After cards: action area (Add Exercise + Settings / Discard)
                            const SizedBox(height: AppSpacing.md),

                            // Add Exercise full-width primary pill
                            //                      Container(
                            //   decoration: BoxDecoration(
                            //     gradient: LinearGradient(
                            //       colors: [scheme.primary, scheme.secondary],
                            //       begin: Alignment.centerLeft,
                            //       end: Alignment.centerRight,
                            //     ),
                            //     borderRadius: BorderRadius.circular(AppRadii.lg),
                            //     boxShadow: AppShadows.e2(scheme),
                            //   ),
                            //   padding: const EdgeInsets.symmetric(
                            //     vertical: AppSpacing.sm,
                            //     horizontal: AppSpacing.md,
                            //   ),
                            //   alignment: Alignment.center,
                            //   child: Row(
                            //     mainAxisAlignment: MainAxisAlignment.center,
                            //     children: [
                            //       const PhosphorIcon(
                            //         PhosphorIconsRegular.plus,
                            //         size: 24,
                            //         color: AppColors.whiteUtility,
                            //       ),
                            //       const SizedBox(width: AppSpacing.xs),
                            //       Text(
                            //         'Add Exercise',
                            //         style: textTheme.bodyMedium!.copyWith(
                            //           color: AppColors.whiteUtility,
                            //           fontWeight: AppTypography.wSemibold // ✅ force pure white for better contrast
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            InkWell(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              onTap: () async {
                                final didAdd = await context.push(
                                  '/workout/exercise-search',
                                  extra: {
                                    "type": "session",
                                    "id": widget.sessionId,
                                  },
                                );

                                if (didAdd == true) {
                                  if (didAdd == true) {
                                    await context
                                        .read<ActiveWorkoutController>()
                                        .refreshFromBackend();
                                  }
                                }
                              },

                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [scheme.primary, scheme.secondary],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.lg,
                                  ),
                                  boxShadow: AppShadows.e2(scheme),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                  horizontal: AppSpacing.md,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const PhosphorIcon(
                                      PhosphorIconsRegular.plus,
                                      size: 24,
                                      color: AppColors.whiteUtility,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Add Exercise',
                                      style: textTheme.bodyMedium!.copyWith(
                                        color: AppColors.whiteUtility,
                                        fontWeight: AppTypography.wSemibold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            // Settings and Discard row
                            Row(
                              children: [
                                // Settings (40%)
                                // Expanded(
                                //   flex: 4, // 40% width
                                //   child: Container(
                                //     decoration: BoxDecoration(
                                //       color: Colors.transparent,
                                //       borderRadius: BorderRadius.circular(
                                //         AppRadii.md,
                                //       ),
                                //       border: Border.all(
                                //         color:
                                //             scheme.outline, // tokenized border color
                                //         width: 1,
                                //       ),
                                //     ),
                                //     padding: const EdgeInsets.symmetric(
                                //       vertical: AppSpacing.sm,
                                //     ),
                                //     alignment: Alignment.center,
                                //     child: Text(
                                //       'Settings',
                                //       style: textTheme.bodyMedium!.copyWith(
                                //         color: scheme.onSurface,
                                //         fontWeight: AppTypography.wMedium,
                                //       ),
                                //     ),
                                //   ),
                                // ),

                                // const SizedBox(width: AppSpacing.sm),

                                // Discard Workout (60%)
                                Expanded(
                                  flex: 6,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                    onTap: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Discard workout?"),
                                          content: const Text(
                                            "This will delete the session and all logged sets.",
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
                                              child: const Text("Discard"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (ok != true) return;

                                      await SessionService().discardSession(
                                        sessionId: widget.sessionId,
                                      );

                                      context
                                          .read<ActiveWorkoutController>()
                                          .clear();

                                      if (context.mounted)
                                        context.go("/workout");
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(
                                          0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.md,
                                        ),
                                        boxShadow: AppShadows.e1(scheme),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.sm,
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const PhosphorIcon(
                                            PhosphorIconsRegular.trash,
                                            size: 24,
                                            color: AppColors.accent,
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            'Discard Workout',
                                            style: textTheme.bodyMedium!
                                                .copyWith(
                                                  color: AppColors.accent,
                                                  fontWeight:
                                                      AppTypography.wMedium,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Bottom framing
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        if (_showFloatingStats)
 AnimatedPositioned(
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeOut,
  top: _showFloatingStats ? 0 : -80, // slide from top
  left: 0,
  right: 0,
  child: SafeArea(
    bottom: false,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _showFloatingStats ? 1 : 0,
      child: _buildStickyStatsBar(
        scheme: scheme,
        textTheme: textTheme,
        isLight: isLight,
        volumeKg: volumeKg,
        setsCount: setsCount,
        active: active,
      ),
    ),
  ),
),
        if (active.isResting) _buildFloatingRestBar(active),
      ],
    );
  }

  Widget _buildFloatingRestBar(ActiveWorkoutController active) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isLight = scheme.brightness == Brightness.light;

    final accentColor = isLight ? scheme.primary : scheme.secondary;
    final mainTextColor = scheme.onSurface;

    String formatRest(int seconds) {
      if (seconds < 60) {
        return "${seconds}s";
      }

      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;

      return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          elevation: 6,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(color: scheme.outline.withOpacity(0.12)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔽 TRUE SMOOTH PROGRESS
                SizedBox(
                  height: 4,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: active,
                    builder: (context, child) {
                      final progress = active.restTotal == 0
                          ? 0.0
                          : active.restRemaining / active.restTotal;

                      return Stack(
                        children: [
                          Container(color: accentColor.withOpacity(0.15)),
                          FractionallySizedBox(
                            widthFactor: progress,
                            alignment: Alignment.centerRight,
                            child: Container(color: accentColor),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      // -15
                      GestureDetector(
                        onTap: () => active.adjustRest(-15),
                        child: Text(
                          "-15s",
                          style: textTheme.bodySmall!.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // SMOOTH COUNTDOWN DISPLAY
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.95,
                                end: 1.0,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          formatRest(active.restRemaining),
                          key: ValueKey(active.restRemaining),
                          style: textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: mainTextColor,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // +15
                      GestureDetector(
                        onTap: () => active.adjustRest(15),
                        child: Text(
                          "+15s",
                          style: textTheme.bodySmall!.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // SKIP
                      GestureDetector(
                        onTap: active.skipRest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Skip",
                            style: textTheme.bodyMedium!.copyWith(
                              color: isLight
                                  ? scheme.onPrimary
                                  : scheme.onSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openReorderSheet() {
    final exercises = context
        .read<ActiveWorkoutController>()
        .exercises
        .cast<Map<String, dynamic>>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReorderExercisesSheet(
        sessionId: widget.sessionId,
        exercises: exercises,
      ),
    );
  }

  void _showExerciseActionsSheet({
    required String sessionId,
    required String sessionExerciseId,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final errorColor = scheme.error;

    final active = context.read<ActiveWorkoutController>();

    final exercise = active.exercises.firstWhere(
      (e) => e["id"].toString() == sessionExerciseId,
    );

    final isInSuperset = exercise["supersetGroup"] != null;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, index) {
                switch (index) {
                  /// REORDER
                  case 0:
                    return ListTile(
                      leading: const PhosphorIcon(
                        PhosphorIconsRegular.arrowsVertical,
                      ),
                      title: const Text("Reorder Exercises"),
                      onTap: () {
                        Navigator.pop(context);
                        _openReorderSheet();
                      },
                    );

                  /// REPLACE
                  case 1:
                    return ListTile(
                      leading: const PhosphorIcon(PhosphorIconsRegular.swap),
                      title: const Text("Replace Exercise"),
                      onTap: () async {
                        Navigator.pop(context);

                        final replaced = await context.push(
                          '/workout/exercise-search',
                          extra: {
                            "type": "session",
                            "id": sessionId,
                            "mode": "replace",
                            "replaceExerciseId": sessionExerciseId,
                          },
                        );

                        if (replaced == true && mounted) {
                          /// clear controllers before reload
                          _weightCtrls.clear();
                          _repsCtrls.clear();

                          await context
                              .read<ActiveWorkoutController>()
                              .refreshFromBackend();
                        }
                      },
                    );

                  /// SUPERSET TOGGLE
                  case 2:
                    return ListTile(
                      leading: PhosphorIcon(
                        isInSuperset
                            ? PhosphorIconsRegular.linkBreak
                            : PhosphorIconsRegular.link,
                      ),
                      title: Text(
                        isInSuperset
                            ? "Remove from Superset"
                            : "Add to Superset",
                      ),
                      onTap: () async {
                        Navigator.pop(context);

                        if (isInSuperset) {
                          /// REMOVE SUPERSET (backend)
                          await SessionService().removeSuperset(
                            sessionId: sessionId,
                            exerciseId: sessionExerciseId,
                          );

                          if (mounted) {
                            await context
                                .read<ActiveWorkoutController>()
                                .refreshFromBackend();
                          }
                        } else {
                          /// OPEN SUPERSET SHEET
                          final active = context
                              .read<ActiveWorkoutController>();

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            builder: (_) {
                              return _SupersetSheet(
                                sessionId: sessionId,
                                currentExerciseId: sessionExerciseId,
                                currentExerciseName:
                                    exercise["name"] ?? "Exercise",
                                currentExerciseImage:
                                    exercise["exercise"]?["mediaUrl"]
                                        ?.toString(),
                                exercises: active.exercises,
                              );
                            },
                          );
                        }
                      },
                    );

                  /// REMOVE EXERCISE
                  case 3:
                    return ListTile(
                      leading: const PhosphorIcon(PhosphorIconsRegular.trash),
                      title: Text(
                        "Remove Exercise",
                        style: TextStyle(color: errorColor),
                      ),
                      onTap: () async {
                        Navigator.pop(context);

                        await SessionService().removeExercise(
                          sessionId: sessionId,
                          sessionExerciseId: sessionExerciseId,
                        );

                        if (mounted) {
                          await context
                              .read<ActiveWorkoutController>()
                              .refreshFromBackend();
                        }

                        if (mounted) setState(() {});
                      },
                    );

                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSetActionsSheet(
    BuildContext context, {
    required String sessionId,
    required String sessionExerciseId,
    required String setId,
  }) async {
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
                ListTile(
                  leading: const PhosphorIcon(PhosphorIconsRegular.arrowDown),
                  title: const Text("Add Drop Set"),
                  onTap: () async {
                    Navigator.pop(context);

                    await SessionService().addDropSet(
                      sessionId: sessionId,
                      sessionExerciseId: sessionExerciseId,
                      parentSetId: setId,
                    );

                    if (mounted) {
                      await context
                          .read<ActiveWorkoutController>()
                          .refreshFromBackend();
                    }
                  },
                ),

                const SizedBox(height: 8),

                ListTile(
                  leading: const PhosphorIcon(PhosphorIconsRegular.trash),
                  title: const Text("Delete set"),
                  onTap: () async {
                    Navigator.pop(context);

                    await SessionService().deleteSet(
                      sessionId: sessionId,
                      sessionExerciseId: sessionExerciseId,
                      setId: setId,
                    );

                    if (mounted) {
                      await context
                          .read<ActiveWorkoutController>()
                          .refreshFromBackend();
                    }
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SupersetSheet extends StatefulWidget {
  final String sessionId;
  final String currentExerciseId;
  final String currentExerciseName;
  final String? currentExerciseImage;
  final List exercises;

  const _SupersetSheet({
    required this.sessionId,
    required this.currentExerciseId,
    required this.currentExerciseName,
    required this.currentExerciseImage,
    required this.exercises,
  });

  @override
  State<_SupersetSheet> createState() => _SupersetSheetState();
}

class _SupersetSheetState extends State<_SupersetSheet> {
  String? _loadingExerciseId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final available = widget.exercises
        .where((e) => e["id"].toString() != widget.currentExerciseId)
        .toList();

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              /// Title
              Text("Create Superset", style: textTheme.titleMedium),

              const SizedBox(height: AppSpacing.xs),

              Text(
                "Alternate exercises without resting between sets.",
                style: textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              _CurrentExerciseCard(
                name: widget.currentExerciseName,
                image: widget.currentExerciseImage,
              ),

              const SizedBox(height: AppSpacing.md),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Select exercise to link",
                  style: textTheme.bodySmall!.copyWith(
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              /// Scrollable list
              Expanded(
                child: available.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        itemCount: available.length,
                        itemBuilder: (context, index) {
                          final ex = available[index];
                          final exId = ex["id"].toString();

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _ExerciseOptionCard(
                              exercise: ex,
                              loading: _loadingExerciseId == exId,
                              onTap: () async {
                                if (_loadingExerciseId != null) return;

                                setState(() {
                                  _loadingExerciseId = exId;
                                });

                                await SessionService().createSuperset(
                                  sessionId: widget.sessionId,
                                  exerciseIds: [widget.currentExerciseId, exId],
                                );

                                if (!mounted) return;

                                HapticFeedback.mediumImpact();

                                Navigator.pop(context);

                                context
                                    .read<ActiveWorkoutController>()
                                    .refreshFromBackend();
                              },
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentExerciseCard extends StatelessWidget {
  final String name;
  final String? image;

  const _CurrentExerciseCard({required this.name, this.image});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: scheme.primary.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          _ExerciseImage(image),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  "Linking from",
                  style: textTheme.bodySmall!.copyWith(color: scheme.primary),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "BASE",
              style: textTheme.labelSmall!.copyWith(color: scheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseOptionCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final bool loading;
  final VoidCallback onTap;

  const _ExerciseOptionCard({
    required this.exercise,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final imageUrl = exercise["exercise"]?["mediaUrl"]?.toString();

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: loading ? scheme.surface.withOpacity(0.5) : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: scheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            _ExerciseImage(imageUrl),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: Text(
                exercise["name"] ?? "Exercise",
                style: textTheme.bodyMedium,
              ),
            ),

            loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const PhosphorIcon(PhosphorIconsRegular.arrowRight, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ExerciseImage extends StatelessWidget {
  final String? imageUrl;

  const _ExerciseImage(this.imageUrl);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(imageUrl!, fit: BoxFit.cover)
          : const Icon(Icons.fitness_center, size: 20),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 28,
            color: scheme.onSurface.withOpacity(0.4),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text("Add another exercise first", style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Generic card wrapper matching tokens
class _Card extends StatelessWidget {
  final Widget child;
  final Color? background;
  final double radius;
  final ColorScheme scheme;

  const _Card({
    required this.child,
    required this.scheme,
    this.background,
    this.radius = AppRadii.lg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background ?? scheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: child,
    );
  }
}

class _WorkoutCard extends StatefulWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  final Map<String, dynamic> exercise;
  final String sessionId;
  final VoidCallback onRefresh;
  final VoidCallback onAddSet;
  final void Function(String setId) onLongPressSet;
  final VoidCallback onOpenExerciseMenu;

  final TextEditingController Function(String setId, double? initial)
  getWeightCtrl;
  final TextEditingController Function(String setId, int? initial) getRepsCtrl;
  final void Function(int seconds)? onStartRest;

  final Future<void> Function(
    String setId,
    double? kg,
    int? reps,
    bool? completed,
  )
  onUpdateSet;

  const _WorkoutCard({
    super.key,
    required this.scheme,
    required this.textTheme,
    required this.exercise,
    required this.onAddSet,
    required this.onUpdateSet,
    required this.sessionId,
    required this.onRefresh,
    required this.onLongPressSet,
    required this.onOpenExerciseMenu,
    required this.getWeightCtrl,
    required this.getRepsCtrl,
    this.onStartRest,
  });

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard> {
  String? _activeSetId;
  late TextEditingController _notesController;
  late FocusNode _notesFocusNode;

  final Map<String, FocusNode> _weightFocusNodes = {};
  final Map<String, FocusNode> _repsFocusNodes = {};

  bool _notesExpanded = false;
  bool _savingNotes = false;

  Color get _neutralBg => widget.scheme.brightness == Brightness.light
      ? AppColors.neutralLight
      : AppColors.neutralDark;

  // ─── Responsive helpers ───────────────────────────────────────────────────

  /// Returns true when the card is rendered on a narrow screen (< 360 dp).
  bool _isNarrow(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  /// Column-header / row flex values that adapt to screen width.
  ({
    int setFlex,
    int prevFlex,
    int kgFlex,
    int repsFlex,
    int timeFlex,
    int repsOnlyFlex,
    double prevFontSize,
  })
  _flexes(BuildContext context) {
    if (_isNarrow(context)) {
      return (
        setFlex: 2,
        prevFlex: 2,      // narrowed so "PREVIOUS" fits
        kgFlex: 2,
        repsFlex: 2,
        timeFlex: 4,
        repsOnlyFlex: 2,
        prevFontSize: 10, // slightly smaller text for previous column
      );
    }
    return (
      setFlex: 2,
      prevFlex: 3,
      kgFlex: 2,
      repsFlex: 2,
      timeFlex: 4,
      repsOnlyFlex: 2,
      prevFontSize: 12,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(covariant _WorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldExerciseId = oldWidget.exercise["exercise"]?["id"];
    final newExerciseId = widget.exercise["exercise"]?["id"];

    if (oldExerciseId != newExerciseId) {
      _notesController.text = widget.exercise["notes"] ?? "";
    }
  }

  FocusNode _getWeightFocus(String setId) {
    return _weightFocusNodes.putIfAbsent(setId, () {
      final node = FocusNode();

      node.addListener(() {
        if (!node.hasFocus) {
          _saveSet(setId);
        }
      });

      return node;
    });
  }

  FocusNode _getRepsFocus(String setId) {
    return _repsFocusNodes.putIfAbsent(setId, () {
      final node = FocusNode();

      node.addListener(() {
        if (!node.hasFocus) {
          _saveSet(setId);
        }
      });

      return node;
    });
  }

  bool _isSaving = false;

  Future<void> _saveSet(String setId) async {
    if (_isSaving || !mounted) return;

    final weightCtrl = widget.getWeightCtrl(setId, null);
    final repsCtrl = widget.getRepsCtrl(setId, null);

    final weightKg = double.tryParse(weightCtrl.text);
    final repsVal = int.tryParse(repsCtrl.text);

    // Optional guard: nothing entered
    if (weightKg == null && repsVal == null) return;

    _isSaving = true;

    try {
      await widget.onUpdateSet(setId, weightKg, repsVal, null);

      widget.onRefresh();
    } finally {
      _isSaving = false;
    }
  }

  @override
  void initState() {
    super.initState();

    _notesController = TextEditingController(
      text: widget.exercise["notes"]?.toString() ?? "",
    );

    _notesFocusNode = FocusNode(debugLabel: 'notesFocus');

    _notesFocusNode.addListener(() {
      if (!_notesFocusNode.hasFocus) {
        _saveNotes();
      }
    });

    if (_notesController.text.isNotEmpty) {
      _notesExpanded = true;
    }
  }

  @override
  void dispose() {
    _notesFocusNode.unfocus();
    _notesController.dispose();
    _notesFocusNode.dispose();
    for (final node in _weightFocusNodes.values) {
      node.dispose();
    }

    for (final node in _repsFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _saveNotes() async {
    final newText = _notesController.text.trim();
    if (newText == widget.exercise["notes"]) return;

    setState(() => _savingNotes = true);

    await SessionService().updateExerciseNotes(
      sessionId: widget.sessionId,
      sessionExerciseId: widget.exercise["id"],
      notes: newText,
    );

    setState(() {
      _savingNotes = false;
      widget.exercise["notes"] = newText;
      if (newText.isEmpty) _notesExpanded = false;
    });
  }

  Future<void> _addDropSet(String parentSetId) async {
    await SessionService().addDropSet(
      sessionId: widget.sessionId,
      sessionExerciseId: widget.exercise["id"],
      parentSetId: parentSetId,
    );

    if (mounted) {
      await context.read<ActiveWorkoutController>().refreshFromBackend();
    }
  }

  bool _hasDropSets(String parentSetId) {
    final allSets = (widget.exercise["sets"] ?? []) as List;

    return allSets.any(
      (s) =>
          s["isDropSet"] == true && s["dropOfSetId"]?.toString() == parentSetId,
    );
  }

  bool _isLastDropSet(String setId) {
    final allSets = (widget.exercise["sets"] ?? []) as List;

    final current = allSets.firstWhere((s) => s["id"].toString() == setId);

    if (current["isDropSet"] != true) return false;

    final parentId = current["dropOfSetId"];

    final siblings = allSets
        .where((s) => s["isDropSet"] == true && s["dropOfSetId"] == parentId)
        .toList();

    final last = siblings.last;

    return last["id"].toString() == setId;
  }

  String _formatRest(dynamic seconds) {
    if (seconds == null || seconds == 0) return "OFF";
    if (seconds is! int || seconds < 5) return "OFF";

    final s = seconds.clamp(5, 300);
    final m = s ~/ 60;
    final r = s % 60;

    if (m == 0) return "${r}s";
    if (r == 0) return "${m}m";
    return "${m}m ${r}s";
  }

  void _openSupersetSheet(BuildContext context) {
    final active = context.read<ActiveWorkoutController>();
    final exercises = active.exercises;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return _SupersetSheet(
          sessionId: widget.sessionId,
          currentExerciseId: widget.exercise["id"].toString(),
          currentExerciseName: widget.exercise["name"] ?? "Exercise",
          currentExerciseImage: widget.exercise["exercise"]?["mediaUrl"]
              ?.toString(),
          exercises: exercises,
        );
      },
    );
  }

  void _openRestTimerSheet(
    BuildContext context,
    String title,
    String sessionExerciseId,
  ) {
    FocusManager.instance.primaryFocus?.unfocus();
    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    final isLight = scheme.brightness == Brightness.light;
    final highlightColor = isLight ? AppColors.primary : AppColors.secondary;

    int? initialSeconds =
        (widget.exercise["restSeconds"] is int &&
            widget.exercise["restSeconds"] >= 5)
        ? (widget.exercise["restSeconds"] as int).clamp(5, 300)
        : null;

    int selectedIndex = initialSeconds == null ? 0 : (initialSeconds ~/ 5);

    final controller = FixedExtentScrollController(initialItem: selectedIndex);

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: 330,
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  /// Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outline.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Section label
                  Text(
                    "Rest Timer",
                    style: textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// Exercise name
                  Text(title, style: textTheme.titleMedium),

                  const SizedBox(height: 20),

                  /// Wheel
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ListWheelScrollView.useDelegate(
                          controller: controller,
                          itemExtent: 56,
                          diameterRatio: 1.8,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              selectedIndex = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 61,
                            builder: (_, index) {
                              final isSelected = index == selectedIndex;

                              final label = index == 0
                                  ? "OFF"
                                  : _formatRest(index * 5);

                              return Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                  style: textTheme.titleMedium!.copyWith(
                                    fontSize: isSelected ? 22 : 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? highlightColor
                                        : scheme.onSurface.withOpacity(0.35),
                                  ),
                                  child: Text(label),
                                ),
                              );
                            },
                          ),
                        ),

                        /// Center highlight background
                        Positioned(
                          child: Container(
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: highlightColor.withOpacity(0.08),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    ).then((_) async {
      // 👇 force clear focus AFTER modal closes
      FocusManager.instance.primaryFocus?.unfocus();
      int? finalSeconds = selectedIndex == 0 ? null : selectedIndex * 5;

      if (finalSeconds != initialSeconds) {
        await SessionService().updateRestTime(
          sessionId: widget.sessionId,
          sessionExerciseId: sessionExerciseId,
          restSeconds: finalSeconds,
        );

        widget.exercise["restSeconds"] = finalSeconds;
        widget.onRefresh();
      }
    });
  }

  void _openDurationPicker(BuildContext context, Map<String, dynamic> set) {
    FocusManager.instance.primaryFocus?.unfocus();

    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    final isLight = scheme.brightness == Brightness.light;
    final highlightColor = isLight ? AppColors.primary : AppColors.secondary;

    final setId = set["id"].toString();
    final sessionExerciseId = widget.exercise["id"].toString();

    /// 🟢 Stop timer if running
    final active = context.read<ActiveWorkoutController>();

    if (active.isTimerRunning(setId)) {
      active.stopSetTimer(sessionExerciseId: sessionExerciseId, setId: setId);
    }

    int initial = set["durationSec"] ?? 0;

    int hours = initial ~/ 3600;
    int minutes = (initial % 3600) ~/ 60;
    int seconds = initial % 60;

    final hourCtrl = FixedExtentScrollController(initialItem: hours);
    final minCtrl = FixedExtentScrollController(initialItem: minutes);
    final secCtrl = FixedExtentScrollController(initialItem: seconds);

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildWheel({
              required int count,
              required int selected,
              required FixedExtentScrollController controller,
              required Function(int) onChanged,
              required String suffix,
            }) {
              return Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ListWheelScrollView.useDelegate(
                      controller: controller,
                      itemExtent: 56,
                      diameterRatio: 1.8,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        HapticFeedback.selectionClick();

                        setModalState(() {
                          onChanged(index);
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: count,
                        builder: (_, index) {
                          final isSelected = index == selected;

                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              style: textTheme.titleMedium!.copyWith(
                                fontSize: isSelected ? 28 : 18,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? highlightColor
                                    : scheme.onSurface.withOpacity(0.35),
                              ),
                              child: Text("$index$suffix"),
                            ),
                          );
                        },
                      ),
                    ),

                    /// center highlight
                    Positioned(
                      child: Container(
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: highlightColor.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 340,
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  /// drag handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// title
                  Text(
                    "Set Duration",
                    style: textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// exercise name
                  Text(
                    widget.exercise["name"],
                    style: textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// wheels
                  Expanded(
                    child: Row(
                      children: [
                        buildWheel(
                          count: 24,
                          selected: hours,
                          controller: hourCtrl,
                          suffix: "h",
                          onChanged: (i) {
                            hours = i;
                          },
                        ),

                        buildWheel(
                          count: 60,
                          selected: minutes,
                          controller: minCtrl,
                          suffix: "m",
                          onChanged: (i) {
                            minutes = i;
                          },
                        ),

                        buildWheel(
                          count: 60,
                          selected: seconds,
                          controller: secCtrl,
                          suffix: "s",
                          onChanged: (i) {
                            seconds = i;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// done button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Done"),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    ).then((_) async {
      final total = hours * 3600 + minutes * 60 + seconds;

      final current = set["durationSec"] ?? 0;

      /// 🟢 only update if changed
      if (current != total) {
        await SessionService().updateSet(
          sessionId: widget.sessionId,
          sessionExerciseId: sessionExerciseId,
          setId: setId,
          durationSec: total,
        );

        if (mounted) {
          final active = context.read<ActiveWorkoutController>();

          active.resetSetTimer(setId, total);
          await context.read<ActiveWorkoutController>().refreshFromBackend();
        }
      }
    });
  }

  Widget _weightField(String setId, TextEditingController controller) {
    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    return Container(
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Center(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: TextField(
            controller: controller,
            focusNode: _getWeightFocus(setId),
            expands: true,
            maxLines: null,
            minLines: null,
            onTap: () {
              setState(() {
                _activeSetId = setId;
              });
            },
            onSubmitted: (_) async {
              await _saveSet(setId);
            },
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.wSemibold,
            ),
            decoration: const InputDecoration(
              hintText: "--",
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _repsField(String setId, TextEditingController controller) {
    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    return Container(
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Center(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: TextField(
            controller: controller,
            focusNode: _getRepsFocus(setId),
            expands: true,
            maxLines: null,
            minLines: null,
            onTap: () {
              setState(() {
                _activeSetId = setId;
              });
            },
            onSubmitted: (_) async {
              await _saveSet(setId);
            },
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: textTheme.bodyMedium!.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.wSemibold,
            ),
            decoration: const InputDecoration(
              hintText: "--",
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _durationField(
    Map<String, dynamic> set,
    String setId,
    int displayDuration,
    bool isTimerRunning,
  ) {
    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    final sessionExerciseId = widget.exercise["id"].toString();

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          /// PLAY / PAUSE BUTTON
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.xs),
            onTap: () {
              final active = context.read<ActiveWorkoutController>();

              active.toggleSetTimer(
                sessionExerciseId: sessionExerciseId,
                setId: setId,
                initialDuration: active.getDisplayDuration(setId),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: PhosphorIcon(
                isTimerRunning
                    ? PhosphorIconsFill.pause
                    : PhosphorIconsFill.play,
                size: 18,
                color: scheme.primary,
              ),
            ),
          ),

          const SizedBox(width: 6),

          /// TIME TEXT → OPENS PICKER
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.xs),
              onTap: () {
                _openDurationPicker(context, set);
              },
              child: Center(
                child: Text(
                  _formatDuration(displayDuration),
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: AppTypography.wSemibold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkButton(
    String setId,
    TextEditingController weightController,
    TextEditingController repsController,
    bool isTicked,
  ) {
    final scheme = widget.scheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.xs),
      onTap: () async {
        setState(() {
          _activeSetId = setId;
        });
        final weightKg = double.tryParse(weightController.text);
        final repsVal = int.tryParse(repsController.text);

        final willBeCompleted = !isTicked;

        await context.read<ActiveWorkoutController>().toggleSetCompletion(
          sessionExerciseId: widget.exercise["id"],
          setId: setId,
          completed: willBeCompleted,
          weightKg: weightKg,
          reps: repsVal,
        );

        /// REST TIMER LOGIC
        if (willBeCompleted) {
          final restSeconds = widget.exercise["restSeconds"];

          if (restSeconds != null && restSeconds is int && restSeconds >= 5) {
            final allSets = (widget.exercise["sets"] ?? []) as List;

            final currentSet = allSets.firstWhere(
              (s) => s["id"].toString() == setId,
            );

            final isDropSet = currentSet["isDropSet"] == true;

            /// PARENT SET
            if (!isDropSet) {
              final hasDrops = allSets.any(
                (s) =>
                    s["isDropSet"] == true &&
                    s["dropOfSetId"]?.toString() == setId,
              );
            }
            /// DROP SET
            else {
              final parentId = currentSet["dropOfSetId"];

              final siblings = allSets
                  .where(
                    (s) =>
                        s["isDropSet"] == true && s["dropOfSetId"] == parentId,
                  )
                  .toList();

              final lastDrop = siblings.last;
            }
          }
        }

        widget.onRefresh();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: isTicked
              ? AppColors.positive.withOpacity(0.15)
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        child: PhosphorIcon(
          PhosphorIconsRegular.check,
          size: 24,
          color: isTicked
              ? AppColors.positive
              : scheme.onSurface.withOpacity(AppOpacities.secondary),
        ),
      ),
    );
  }

  Widget _buildDropRow(
    Map<String, dynamic> set,
    int dropNumber,
    int totalDrops,
  ) {
    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    final setId = set["id"].toString();

    final active = context.watch<ActiveWorkoutController>();
    final isTimerRunning = active.isTimerRunning(setId);
    final displayDuration = active.getDisplayDuration(setId);

    final weightKg = (set["weightKg"] as num?)?.toDouble();
    final reps = set["reps"] as int?;
    final isTicked = set["completed"] == true;

    final weightController = widget.getWeightCtrl(setId, weightKg);
    final repsController = widget.getRepsCtrl(setId, reps);

    final trackingType =
        widget.exercise["exercise"]?["trackingType"]?.toString() ??
        "REPS_WEIGHT";

    final isTime = trackingType == "TIME";
    final isRepsOnly = trackingType == "REPS";

    // ── responsive ──
    final f = _flexes(context);

    String _getPreviousText(Map<String, dynamic> set) {
      final prev = set["previous"];

      if (prev == null) return "--";

      final weight = prev["weightKg"];
      final reps = prev["reps"];
      final duration = prev["durationSec"];

      if (duration != null && duration > 0) {
        return formatDuration(duration);
      }

      if (weight != null && reps != null) {
        final w = (weight as num).toDouble();
        return "${w % 1 == 0 ? w.toInt() : w} × $reps";
      }

      if (reps != null) {
        return "$reps";
      }

      return "--";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          /// BRANCH CONNECTOR
          SizedBox(
            width: 20,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 1.5,
                height: 40,
                color: scheme.outline.withOpacity(0.18),
              ),
            ),
          ),

          /// CONTENT
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.md),
              onTap: () {
                setState(() {
                  _activeSetId = setId;
                });
              },
              onLongPress: () => widget.onLongPressSet(setId),
              child: Container(
                decoration: BoxDecoration(
                  color: _neutralBg.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: _activeSetId == setId
                      ? Border.all(
                          color: widget.scheme.onSurface.withOpacity(0.20),
                          width: 1.2,
                        )
                      : null,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    /// SET LABEL
                    Expanded(
                      flex: f.setFlex,
                      child: Text(
                        "D$dropNumber",
                        style: textTheme.bodyMedium!.copyWith(
                          color: AppColors.accent,
                          fontWeight: AppTypography.wSemibold,
                        ),
                      ),
                    ),

                    /// PREVIOUS
                    Expanded(
                      flex: f.prevFlex,
                      child: Text(
                        _getPreviousText(set),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall!.copyWith(
                          fontSize: f.prevFontSize,
                          color: _getPreviousText(set) == "--"
                              ? scheme.onSurface.withOpacity(0.35)
                              : scheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.xs),

                    /// TIME / REPS / WEIGHT+REPS
                    if (isTime)
                      Expanded(
                        flex: f.timeFlex,
                        child: _durationField(
                          set,
                          setId,
                          displayDuration,
                          isTimerRunning,
                        ),
                      )
                    else if (isRepsOnly)
                      Expanded(
                        flex: f.repsOnlyFlex,
                        child: _repsField(setId, repsController),
                      )
                    else ...[
                      Expanded(
                        flex: f.kgFlex,
                        child: _weightField(setId, weightController),
                      ),

                      const SizedBox(width: AppSpacing.xs),

                      Expanded(
                        flex: f.repsFlex,
                        child: _repsField(setId, repsController),
                      ),
                    ],

                    const SizedBox(width: AppSpacing.xs),

                    /// CHECK BUTTON
                    _checkButton(
                      setId,
                      weightController,
                      repsController,
                      isTicked,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    // ── responsive ──
    final f = _flexes(context);

    final title = widget.exercise["name"]?.toString() ?? "Exercise";

    final trackingType =
        widget.exercise["exercise"]?["trackingType"]?.toString() ??
        "REPS_WEIGHT";

    final bool isTime = trackingType == "TIME";
    final bool isRepsOnly = trackingType == "REPS";

    final sessionExerciseId = widget.exercise["id"].toString();
    final selectedMood = widget.exercise["howHard"];

    final isInSuperset = widget.exercise["supersetGroup"] != null;

    final allSets =
        ((widget.exercise["sets"] ?? []) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList()
          ..sort(
            (a, b) => (a["setIndex"] as int).compareTo(b["setIndex"] as int),
          );

    final normalSets = <Map<String, dynamic>>[];
    final Map<String, List<Map<String, dynamic>>> dropSets = {};

    for (final s in allSets) {
      final set = s as Map<String, dynamic>;

      if (set["isDropSet"] == true && set["dropOfSetId"] != null) {
        final parentId = set["dropOfSetId"].toString();

        dropSets.putIfAbsent(parentId, () => []);
        dropSets[parentId]!.add(set);
      } else {
        normalSets.add(set);
      }
    }
    final hasSets = normalSets.isNotEmpty;

    final imageUrl = widget.exercise["exercise"]?["mediaUrl"]?.toString();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// HEADER
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.push(
                    '/workout/exercise/${widget.exercise["exerciseId"] ?? widget.exercise["exercise"]?["id"]}',
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: AppBorders.boxCard(scheme),
                    boxShadow: AppShadows.e1(scheme),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(scheme),
                        )
                      : _imageFallback(scheme),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(title, style: textTheme.titleMedium, maxLines: 2),
              ),
              InkWell(
                onTap: widget.onOpenExerciseMenu,
                child: const PhosphorIcon(
                  PhosphorIconsRegular.dotsThreeVertical,
                  size: 24,
                ),
              ),
            ],
          ),

          /// INLINE NOTES
          const SizedBox(height: AppSpacing.sm),

          TextField(
            controller: _notesController,
            focusNode: _notesFocusNode,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            cursorColor: widget.scheme.primary,
            style: widget.textTheme.bodySmall,
            decoration: const InputDecoration(
              hintText: "Add notes...",
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          /// REST
          const SizedBox(height: AppSpacing.sm),

          InkWell(
            onTap: () {
              FocusScope.of(context).unfocus();
              _openRestTimerSheet(context, title, sessionExerciseId);
            },
            child: Row(
              children: [
                const PhosphorIcon(PhosphorIconsRegular.clock, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  "Rest Timer : ${_formatRest(widget.exercise["restSeconds"])}",
                  style: textTheme.bodyMedium!.copyWith(
                    color: widget.exercise["restSeconds"] == null
                        ? scheme.onSurface.withOpacity(0.5)
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Column header ─────────────────────────────────────────────────
          if (hasSets) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    flex: f.setFlex,
                    child: Text(
                      'SET',
                      style: textTheme.bodySmall!.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                  ),

                  Expanded(
                    flex: f.prevFlex,
                    child: Text(
                      'PREVIOUS',  // shortened on all screens — no wrapping risk
                      style: textTheme.bodySmall!.copyWith(
                        fontWeight: AppTypography.wMedium,
                        fontSize: f.prevFontSize,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  if (isTime)
                    Expanded(
                      flex: f.timeFlex,
                      child: Center(
                        child: Text(
                          'TIME',
                          style: textTheme.bodySmall!.copyWith(
                            fontWeight: AppTypography.wMedium,
                          ),
                        ),
                      ),
                    )
                  else if (isRepsOnly)
                    Expanded(
                      flex: f.repsOnlyFlex,
                      child: Center(
                        child: Text(
                          'REPS',
                          style: textTheme.bodySmall!.copyWith(
                            fontWeight: AppTypography.wMedium,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Flexible(
                      flex: f.kgFlex,
                      fit: FlexFit.tight,
                      child: Center(
                        child: Text('KG', style: textTheme.bodySmall),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      flex: f.repsFlex,
                      fit: FlexFit.loose,
                      child: Center(
                        child: Text('REPS', style: textTheme.bodySmall),
                      ),
                    ),
                  ],

                  const SizedBox(width: AppSpacing.xs),

                  SizedBox(
                    width: 48,
                    child: Center(
                      child: PhosphorIcon(
                        PhosphorIconsRegular.check,
                        size: 24,
                        color: scheme.onSurface.withOpacity(
                          AppOpacities.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Set rows ──────────────────────────────────────────────────────
          if (hasSets) ...[
            const SizedBox(height: AppSpacing.xs),

            Column(
              children: List.generate(normalSets.length, (index) {
                final set = normalSets[index];

                final setId = set["id"].toString();
                final weightKg = (set["weightKg"] as num?)?.toDouble();
                final reps = set["reps"] as int?;
                final isTicked = set["completed"] == true;

                final active = context.watch<ActiveWorkoutController>();

                final isTimerRunning = active.isTimerRunning(setId);

                final displayDuration = active.getDisplayDuration(setId);

                final weightController = widget.getWeightCtrl(setId, weightKg);
                final repsController = widget.getRepsCtrl(setId, reps);

                final parentId = setId;
                final drops = dropSets[parentId] ?? [];

                String _getPreviousText(Map<String, dynamic> set) {
                  final prev = set["previous"];

                  if (prev == null) return "--";

                  final weight = prev["weightKg"];
                  final reps = prev["reps"];
                  final duration = prev["durationSec"];

                  if (duration != null && duration > 0) {
                    return formatDuration(duration);
                  }

                  if (weight != null && reps != null) {
                    final w = (weight as num).toDouble();
                    return "${w % 1 == 0 ? w.toInt() : w} × $reps";
                  }

                  if (reps != null) {
                    return "$reps";
                  }

                  return "--";
                }

                return Column(
                  children: [
                    /// NORMAL SET ROW
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        onTap: () {
                          setState(() {
                            _activeSetId = setId;
                          });
                        },
                        onLongPress: () => widget.onLongPressSet(setId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: _neutralBg,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: isTicked
                                ? Border.all(
                                    color: AppColors.positive.withOpacity(0.45),
                                    width: 1.2,
                                  )
                                : null,
                            boxShadow: _activeSetId == setId
                                ? [
                                    BoxShadow(
                                      color: widget.scheme.onSurface
                                          .withOpacity(0.10),
                                      blurRadius: 0,
                                      spreadRadius: 1.2,
                                    ),
                                  ]
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                            horizontal: AppSpacing.sm,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: f.setFlex,
                                child: Text(
                                  '${index + 1}',
                                  style: textTheme.titleMedium,
                                ),
                              ),

                              Expanded(
                                flex: f.prevFlex,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _getPreviousText(set),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall!.copyWith(
                                      fontSize: f.prevFontSize,
                                      fontWeight: AppTypography.wMedium,
                                      color: _getPreviousText(set) == "--"
                                          ? scheme.onSurface.withOpacity(0.35)
                                          : scheme.onSurface.withOpacity(
                                              AppOpacities.secondary,
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: AppSpacing.xs),

                              if (isTime)
                                Expanded(
                                  flex: f.timeFlex,
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.xs,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        InkWell(
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.xs,
                                          ),
                                          onTap: () {
                                            final active = context
                                                .read<ActiveWorkoutController>();

                                            active.toggleSetTimer(
                                              sessionExerciseId:
                                                  sessionExerciseId,
                                              setId: setId,
                                              initialDuration: active
                                                  .getDisplayDuration(setId),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: PhosphorIcon(
                                              isTimerRunning
                                                  ? PhosphorIconsFill.pause
                                                  : PhosphorIconsFill.play,
                                              size: 18,
                                              color: scheme.primary,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 6),

                                        Expanded(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.xs,
                                            ),
                                            onTap: () {
                                              _openDurationPicker(context, set);
                                            },
                                            child: Center(
                                              child: Text(
                                                _formatDuration(
                                                  displayDuration,
                                                ),
                                                style: textTheme.bodyMedium!
                                                    .copyWith(
                                                      fontWeight: AppTypography
                                                          .wSemibold,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (isRepsOnly)
                                Expanded(
                                  flex: f.repsOnlyFlex,
                                  child: Container(
                                    height: 40,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.xs,
                                      ),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: TextField(
                                          controller: repsController,
                                          expands: true,
                                          maxLines: null,
                                          minLines: null,
                                          focusNode: _getRepsFocus(setId),
                                          onTap: () {
                                            setState(() {
                                              _activeSetId = setId;
                                            });
                                          },
                                          onSubmitted: (_) async {
                                            await _saveSet(setId);
                                          },
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: false,
                                              ),
                                          textAlign: TextAlign.center,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          style: textTheme.bodyMedium!.copyWith(
                                            color: scheme.onSurface,
                                            fontWeight: AppTypography.wSemibold,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: "--",
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else ...[
                                Expanded(
                                  flex: f.kgFlex,
                                  child: Container(
                                    height: 40,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.xs,
                                      ),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: TextField(
                                          controller: weightController,
                                          expands: true,
                                          maxLines: null,
                                          minLines: null,
                                          focusNode: _getWeightFocus(setId),
                                          onTap: () {
                                            setState(() {
                                              _activeSetId = setId;
                                            });
                                          },
                                          onSubmitted: (_) async {
                                            await _saveSet(setId);
                                          },
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          textAlign: TextAlign.center,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          style: textTheme.bodyMedium!.copyWith(
                                            color: scheme.onSurface,
                                            fontWeight: AppTypography.wSemibold,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: "--",
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: AppSpacing.xs),

                                Expanded(
                                  flex: f.repsFlex,
                                  child: Container(
                                    height: 40,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.xs,
                                      ),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: TextField(
                                          controller: repsController,
                                          expands: true,
                                          maxLines: null,
                                          minLines: null,
                                          focusNode: _getRepsFocus(setId),
                                          onTap: () {
                                            setState(() {
                                              _activeSetId = setId;
                                            });
                                          },
                                          onSubmitted: (_) async {
                                            await _saveSet(setId);
                                          },
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: false,
                                              ),
                                          textAlign: TextAlign.center,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          style: textTheme.bodyMedium!.copyWith(
                                            color: scheme.onSurface,
                                            fontWeight: AppTypography.wSemibold,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: "--",
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: AppSpacing.xs),

                              /// CHECK BUTTON
                              InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.xs,
                                ),
                                onTap: () async {
                                  final weightKg = double.tryParse(
                                    weightController.text,
                                  );
                                  final repsVal = int.tryParse(
                                    repsController.text,
                                  );

                                  final willBeCompleted = !isTicked;

                                  await context
                                      .read<ActiveWorkoutController>()
                                      .toggleSetCompletion(
                                        sessionExerciseId: sessionExerciseId,
                                        setId: setId,
                                        completed: willBeCompleted,
                                        weightKg: weightKg,
                                        reps: repsVal,
                                      );

                                  if (willBeCompleted) {
                                    final restSeconds =
                                        widget.exercise["restSeconds"];

                                    if (restSeconds != null &&
                                        restSeconds is int &&
                                        restSeconds >= 5) {
                                      final allSets =
                                          (widget.exercise["sets"] ?? [])
                                              as List;

                                      final hasDropSets = allSets.any(
                                        (s) =>
                                            s["isDropSet"] == true &&
                                            s["dropOfSetId"]?.toString() ==
                                                setId,
                                      );
                                    }
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: isTicked
                                        ? AppColors.positive.withOpacity(0.15)
                                        : scheme.surface,
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.xs,
                                    ),
                                  ),
                                  child: PhosphorIcon(
                                    PhosphorIconsRegular.check,
                                    size: 24,
                                    color: isTicked
                                        ? AppColors.positive
                                        : scheme.onSurface.withOpacity(
                                            AppOpacities.secondary,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// DROP SETS
                    ...drops.asMap().entries.map((entry) {
                      final dropIndex = entry.key;
                      final dropSet = entry.value;

                      return _buildDropRow(
                        dropSet,
                        dropIndex + 1,
                        drops.length,
                      );
                    }),
                  ],
                );
              }),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Add Set full-width
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _neutralBg,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.md),
              onTap: widget.onAddSet,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.plus,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Add Set',
                      style: textTheme.bodyMedium!.copyWith(
                        color: scheme.primary,
                        fontWeight: AppTypography.wSemibold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Drop Set & Super Set
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    onTap: () async {
                      if (_activeSetId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Select a set first")),
                        );
                        return;
                      }

                      final allSets = (widget.exercise["sets"] ?? []) as List;

                      final current = allSets.firstWhere(
                        (s) => s["id"].toString() == _activeSetId,
                      );

                      final parentSetId = current["isDropSet"] == true
                          ? current["dropOfSetId"]
                          : _activeSetId;

                      await SessionService().addDropSet(
                        sessionId: widget.sessionId,
                        sessionExerciseId: widget.exercise["id"],
                        parentSetId: parentSetId,
                      );

                      widget.onRefresh();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const PhosphorIcon(
                            PhosphorIconsRegular.lightning,
                            size: 24,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Drop Set',
                            style: textTheme.bodyMedium!.copyWith(
                              color: AppColors.accent,
                              fontWeight: AppTypography.wMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.secondary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    onTap: () async {
                      final active = context.read<ActiveWorkoutController>();

                      if (isInSuperset) {
                        await SessionService().removeSuperset(
                          sessionId: widget.sessionId,
                          exerciseId: widget.exercise["id"].toString(),
                        );

                        if (mounted) {
                          await active.refreshFromBackend();
                        }
                      } else {
                        _openSupersetSheet(context);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhosphorIcon(
                            PhosphorIconsRegular.link,
                            size: 24,
                            color: scheme.secondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            isInSuperset ? "Unlink" : "Super Set",
                            style: textTheme.bodyMedium!.copyWith(
                              color: scheme.secondary,
                              fontWeight: AppTypography.wMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // How hard was this?
          Text(
            'How hard was this?',
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              fontWeight: AppTypography.wMedium,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Mood selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MoodButton(
                scheme: scheme,
                label: '😌',
                selected: selectedMood == 1,
                onTap: () {
                  context.read<ActiveWorkoutController>().setExerciseEffort(
                    sessionExerciseId: widget.exercise["id"],
                    howHard: selectedMood == 1 ? null : 1,
                  );
                },
                minWidth: 64,
                height: AppSpacing.xl,
                textTheme: textTheme,
                neutralBg: _neutralBg,
              ),
              _MoodButton(
                scheme: scheme,
                label: '🙂',
                selected: selectedMood == 2,
                onTap: () {
                  context.read<ActiveWorkoutController>().setExerciseEffort(
                    sessionExerciseId: widget.exercise["id"],
                    howHard: selectedMood == 2 ? null : 2,
                  );
                },
                minWidth: 56,
                height: AppSpacing.xl,
                textTheme: textTheme,
                neutralBg: _neutralBg,
              ),
              _MoodButton(
                scheme: scheme,
                label: '😅',
                selected: selectedMood == 3,
                onTap: () {
                  context.read<ActiveWorkoutController>().setExerciseEffort(
                    sessionExerciseId: widget.exercise["id"],
                    howHard: selectedMood == 3 ? null : 3,
                  );
                },
                minWidth: 56,
                height: AppSpacing.xl,
                textTheme: textTheme,
                neutralBg: _neutralBg,
              ),
              _MoodButton(
                scheme: scheme,
                label: '🤯',
                selected: selectedMood == 4,
                onTap: () {
                  context.read<ActiveWorkoutController>().setExerciseEffort(
                    sessionExerciseId: widget.exercise["id"],
                    howHard: selectedMood == 4 ? null : 4,
                  );
                },
                minWidth: 56,
                height: AppSpacing.xl,
                textTheme: textTheme,
                neutralBg: _neutralBg,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Easy and Hard labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Easy', style: textTheme.labelSmall),
              Text('Hard', style: textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double minWidth;
  final double height;
  final TextTheme textTheme;
  final Color neutralBg;

  const _MoodButton({
    required this.scheme,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.minWidth,
    required this.height,
    required this.textTheme,
    required this.neutralBg,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(minWidth: minWidth),
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withOpacity(0.15) : neutralBg,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: selected
              ? Border.all(color: scheme.primary, width: 1.2)
              : null,
        ),
        child: Text(label, style: textTheme.bodyMedium),
      ),
    );
  }
}

class _EmptyWorkoutState extends StatelessWidget {
  const _EmptyWorkoutState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.barbell,
              color: scheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "No exercises yet",
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap “Add Exercise” to start logging.",
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Widget _imageFallback(ColorScheme scheme) {
  return Container(
    color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
    alignment: Alignment.center,
    child: const PhosphorIcon(PhosphorIconsRegular.image, size: 24),
  );
}

class _SupersetChip extends StatelessWidget {
  final String group;

  const _SupersetChip({required this.group});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final color = SupersetColors.colorFor(group);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: Border.all(color: color.withOpacity(0.45), width: 1.2),
          ),
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                "Superset $group",
                style: textTheme.labelMedium!.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SupersetColors {
  static const _palette = [
    AppColors.secondary,
    AppColors.accent,
    AppColors.primary,
    AppColors.positive,
  ];

  static Color colorFor(String group) {
    final index = group.codeUnitAt(0) % _palette.length;
    return _palette[index];
  }
}

class _ReorderExercisesSheet extends StatefulWidget {
  final String sessionId;
  final List<Map<String, dynamic>> exercises;

  const _ReorderExercisesSheet({
    required this.sessionId,
    required this.exercises,
  });

  @override
  State<_ReorderExercisesSheet> createState() => _ReorderExercisesSheetState();
}

class _ReorderExercisesSheetState extends State<_ReorderExercisesSheet> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.exercises);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              /// drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const SizedBox(height: 18),

              /// Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.swap_vert_rounded, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      "Reorder Exercises",
                      style: textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Drag exercises to change workout flow",
                    style: textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// LIST
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: _items.length,

                  onReorderStart: (_) => HapticFeedback.mediumImpact(),

                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 10,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },

                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;

                      final item = _items.removeAt(oldIndex);
                      _items.insert(newIndex, item);
                    });
                  },

                  itemBuilder: (context, index) {
                    final ex = _items[index];
                    final id = ex["id"].toString();
                    final image = ex["exercise"]?["mediaUrl"]?.toString();

                    return Container(
                      key: ValueKey(id),
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outline.withOpacity(0.2),
                        ),
                        color: scheme.surface,
                      ),

                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),

                        child: Row(
                          children: [
                            /// Exercise image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: image != null
                                  ? Image.network(
                                      image,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      color: scheme.surfaceVariant,
                                      child: const Icon(
                                        Icons.fitness_center,
                                        size: 22,
                                      ),
                                    ),
                            ),

                            const SizedBox(width: 12),

                            /// Exercise name + order
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex["name"] ?? "Exercise",
                                    style: textTheme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Position ${index + 1}",
                                    style: textTheme.bodySmall!.copyWith(
                                      color: scheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// drag handle
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_indicator,
                                color: scheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// Save button
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: scheme.outline.withOpacity(0.15)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Save Order"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final ids = _items
                            .map((e) => e["id"].toString())
                            .toList();

                        await context
                            .read<ActiveWorkoutController>()
                            .reorderExercises(ids);

                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatDuration(int? seconds) {
  final sec = seconds ?? 0;

  final h = sec ~/ 3600;
  final m = (sec % 3600) ~/ 60;
  final s = sec % 60;

  if (h > 0) {
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
}


String? _getDisplayName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return null;

  final parts = fullName.trim().split(RegExp(r'\s+'));

  if (parts.length == 1) return parts[0];
  if (parts.length == 2) return parts[0];
  if (parts.length >= 3) return "${parts[0]} ${parts[1]}";

  return fullName;
}

