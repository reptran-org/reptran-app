import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:reptran_app/features/workout/services/user_workout_service.dart';
import 'package:reptran_app/features/workout/models/editable_workout.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class UserWorkoutBuilderPage extends StatefulWidget {
  final String workoutId;
  final bool isNew;

  const UserWorkoutBuilderPage({
    super.key,
    required this.workoutId,
    required this.isNew,
  });

  @override
  State<UserWorkoutBuilderPage> createState() => _UserWorkoutBuilderPageState();
}

class _UserWorkoutBuilderPageState extends State<UserWorkoutBuilderPage> {
  EditableWorkout? _workout;

  final _uuid = const Uuid();

  final TextEditingController _titleCtrl = TextEditingController();

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
    _fetchWorkout();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();

    for (final c in _weightCtrls.values) {
      c.dispose();
    }
    for (final c in _repsCtrls.values) {
      c.dispose();
    }

    super.dispose();
  }

  Future<void> _fetchWorkout() async {
    try {
      final res = await UserWorkoutService().getWorkout(widget.workoutId);

      final workout = EditableWorkout.fromApi(res);

      if (_titleCtrl.text.isEmpty) {
        _titleCtrl.text = workout.title;
      }

      setState(() {
        _workout = workout;
      });
    } catch (e) {}
  }

  Future<void> _saveWorkout() async {
    final title = _titleCtrl.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Workout name is required")));
      return;
    }

    try {
      _workout!.title = title;

      final payload = _workout!.toPayload();

      await UserWorkoutService().saveWorkout(
        workoutId: widget.workoutId,
        payload: payload,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Workout saved")));

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save workout")));
    }
  }

  Future<void> _confirmDiscard() async {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          title: const Text("Discard changes?"),
          content: const Text("Your changes will not be saved."),
          actions: [
            /// KEEP EDITING
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Keep editing",
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(AppOpacities.secondary),
                  fontWeight: AppTypography.wMedium,
                ),
              ),
            ),

            /// DISCARD
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                "Discard",
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                  fontWeight: AppTypography.wSemibold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDiscard != true) return;

    /// delete only if this was a newly created workout
    if (widget.isNew) {
      try {
        await UserWorkoutService().deleteWorkout(workoutId: widget.workoutId);
      } catch (e) {}
    }

    if (mounted) {
      context.pop();
    }
  }

  void _openSupersetSheet(
    BuildContext context,
    EditableWorkoutExercise exercise,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return _SupersetSheet(
          currentExerciseId: exercise.id,
          currentExerciseName: exercise.name,
          currentExerciseImage: exercise.mediaUrl,
          exercises: _workout!.exercises,
          onUpdated: () {
            setState(() {});
          },
        );
      },
    );
  }

  void _openReorderSheet() async {
    final reordered = await showModalBottomSheet<List<EditableWorkoutExercise>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReorderExercisesSheet(
        sessionId: widget.workoutId,
        exercises: _workout!.exercises,
      ),
    );

    if (reordered != null) {
      setState(() {
        _workout!.exercises = reordered;
      });
    }
  }

  void _showExerciseActionsSheet({
    required String workoutId,
    required String workoutExerciseId,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final errorColor = scheme.error;

    final workout = _workout!;
    final exercise = workout.exercises.firstWhere(
      (e) => e.id == workoutExerciseId,
    );

    final isInSuperset = exercise.supersetGroup != null;

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
                      leading: PhosphorIcon(
                        PhosphorIconsRegular.arrowsVertical,
                      ),
                      title: Text("Reorder Exercises"),
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

                        final result = await context.push<Map<String, dynamic>>(
                          '/workout/exercise-search',
                          extra: {
                            "type": "workout",
                            "id": widget.workoutId,
                            "mode": "replace",
                          },
                        );

                        if (result != null) {
                          setState(() {
                            /// Replace identity
                            exercise.exerciseId = result["exerciseId"];
                            exercise.name = result["name"];
                            exercise.mediaUrl = result["mediaUrl"];
                            exercise.trackingType = result["trackingType"];

                            /// Reset notes
                            exercise.notes = null;

                            /// Reset sets
                            for (final s in exercise.sets) {
                              s.reps = null;
                              s.weightKg = null;
                              s.durationSec = null;
                              s.restSec = null;
                              s.isFailure = false;

                              /// IMPORTANT: clear controllers
                              _repsCtrls[s.id]?.clear();
                              _weightCtrls[s.id]?.clear();
                            }
                          });
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
                      onTap: () {
                        Navigator.pop(context);

                        if (isInSuperset) {
                          /// remove superset locally
                          final group = exercise.supersetGroup;

                          setState(() {
                            for (final e in _workout!.exercises) {
                              if (e.supersetGroup == group) {
                                e.supersetGroup = null;
                              }
                            }
                          });
                        } else {
                          /// open superset selector
                          _openSupersetSheet(context, exercise);
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
                      onTap: () {
                        Navigator.pop(context);

                        setState(() {
                          workout.exercises.removeWhere(
                            (e) => e.id == workoutExerciseId,
                          );
                        });
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
    required String workoutId,
    required String workoutExerciseId,
    required String setId,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();

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
                /// ADD DROP SET
                ListTile(
                  leading: const PhosphorIcon(PhosphorIconsRegular.arrowDown),
                  title: const Text("Add Drop Set"),
                  onTap: () {
                    Navigator.pop(context);

                    final sets = _workout!.exercises
                        .firstWhere((e) => e.id == workoutExerciseId)
                        .sets;

                    final exercise = _workout!.exercises.firstWhere(
                      (e) => e.id == workoutExerciseId,
                    );

                    final current = sets.firstWhere((s) => s.id == setId);

                    final parentSetId = current.isDropSet
                        ? current.dropOfSetId
                        : current.id;

                    final parentSet = sets.firstWhere(
                      (s) => s.id == parentSetId,
                    );

                    final existingDrops = sets
                        .where((s) => s.dropOfSetId == parentSetId)
                        .toList();

                    final dropCount = existingDrops.length;

                    /// weight source
                    double? weightSource = parentSet.weightKg;

                    if (weightSource == null) {
                      final prev =
                          sets
                              .where((s) => !s.isDropSet && s.weightKg != null)
                              .toList()
                            ..sort((a, b) => b.setIndex.compareTo(a.setIndex));

                      weightSource = prev.isNotEmpty
                          ? prev.first.weightKg
                          : null;
                    }

                    /// drop weight
                    double? dropWeight;

                    if (exercise.trackingType == "REPS_WEIGHT" &&
                        weightSource != null) {
                      final raw = weightSource * 0.75;
                      dropWeight = (raw / 2.5).round() * 2.5;
                    }
                    final newDrop = EditableWorkoutSet(
                      id: _uuid.v4(),
                      setIndex: parentSet.setIndex + (dropCount + 1) * 10,
                      isDropSet: true,
                      dropOfSetId: parentSetId,
                      weightKg: dropWeight,
                    );

                    setState(() {
                      sets.add(newDrop);
                    });
                  },
                ),

                const SizedBox(height: 8),

                /// DELETE SET (LOCAL)
                ListTile(
                  leading: const PhosphorIcon(PhosphorIconsRegular.trash),
                  title: const Text("Delete set"),
                  onTap: () {
                    Navigator.pop(context);

                    final sets = _workout!.exercises
                        .firstWhere((e) => e.id == workoutExerciseId)
                        .sets;

                    final target = sets.firstWhere((s) => s.id == setId);

                    setState(() {
                      sets.removeWhere((s) => s.id == setId);

                      /// if parent deleted remove its drops
                      if (!target.isDropSet) {
                        sets.removeWhere((s) => s.dropOfSetId == setId);
                      }
                    });
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_workout == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _confirmDiscard();
      },
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.sm),

                      // Cancel + Title + Save (improved)
                      Row(
                        children: [
                          // Cancel
                          InkWell(
                            borderRadius: BorderRadius.circular(AppRadii.full),
                            onTap: _confirmDiscard,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                "Cancel",
                                style: textTheme.bodyMedium!.copyWith(
                                  color: scheme.onSurface.withOpacity(
                                    AppOpacities.secondary,
                                  ),
                                  fontWeight: AppTypography.wMedium,
                                ),
                              ),
                            ),
                          ),

                          // Center title
                          Expanded(
                            child: Center(
                              child: Text(
                                "Create Workout",
                                style: textTheme.titleMedium!.copyWith(
                                  fontWeight: AppTypography.wSemibold,
                                ),
                              ),
                            ),
                          ),

                          // Save
                          InkWell(
                            borderRadius: BorderRadius.circular(AppRadii.full),
                            onTap: _saveWorkout,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.full,
                                ),
                                boxShadow: AppShadows.e1(scheme),
                              ),
                              child: Text(
                                "Save",
                                style: textTheme.bodyMedium!.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: AppTypography.wSemibold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Inline title
                      // Workout name (subtle container + radius)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: scheme.onSurface.withOpacity(0.06),
                          ),
                        ),
                        child: TextField(
                          controller: _titleCtrl,
                          style: textTheme.headlineSmall!.copyWith(
                            fontWeight: AppTypography.wBold,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Workout name",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Cards or empty
                      if (_workout!.exercises.isEmpty) ...[
                        const _EmptyWorkoutState(),
                      ] else ...[
                        ...List.generate(_workout!.exercises.length, (index) {
                          final ex = _workout!.exercises[index];
                          final workoutExerciseId = ex.id;

                          final supersetGroup = ex.supersetGroup;

                          final showSupersetChip = supersetGroup != null;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              /// SUPerset chip
                              if (showSupersetChip)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xs,
                                    left: AppSpacing.xs,
                                  ),
                                  child: _SupersetChip(group: supersetGroup!),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: _WorkoutCard(
                                  key: ValueKey(ex.exerciseId),
                                  scheme: scheme,
                                  textTheme: textTheme,
                                  exercise: ex,
                                  workoutId: widget.workoutId,
                                  workoutExerciseId: workoutExerciseId,
                                  exercises: _workout!.exercises,
                                  onOpenSupersetSheet: () {
                                    final group = ex.supersetGroup;

                                    if (group != null) {
                                      /// REMOVE SUPERSET
                                      setState(() {
                                        for (final e in _workout!.exercises) {
                                          if (e.supersetGroup == group) {
                                            e.supersetGroup = null;
                                          }
                                        }
                                      });
                                    } else {
                                      /// CREATE SUPERSET
                                      _openSupersetSheet(context, ex);
                                    }
                                  },

                                  getWeightCtrl: _getWeightCtrl,
                                  getRepsCtrl: _getRepsCtrl,
                                  onRefresh: _fetchWorkout,
                                  onLongPressSet: (setId) {
                                    _showSetActionsSheet(
                                      context,
                                      workoutId: widget.workoutId,
                                      workoutExerciseId: workoutExerciseId,
                                      setId: setId,
                                    );
                                  },

                                  onOpenExerciseMenu: () {
                                    _showExerciseActionsSheet(
                                      workoutId: widget.workoutId,
                                      workoutExerciseId: workoutExerciseId,
                                    );
                                  },
                                  onAddSet: () async {
                                    await UserWorkoutService().addSet(
                                      workoutId: widget.workoutId,
                                      workoutExerciseId: workoutExerciseId,
                                    );
                                    await _fetchWorkout();
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                      ],

                      const SizedBox(height: AppSpacing.md),

                      // Add Exercise button
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        onTap: () async {
                          final addedExercises = await context
                              .push<List<Map<String, dynamic>>>(
                                '/workout/exercise-search',
                                extra: {
                                  "type": "workout",
                                  "id": widget.workoutId,
                                },
                              );

                          if (addedExercises != null &&
                              addedExercises.isNotEmpty) {
                            setState(() {
                              for (final ex in addedExercises) {
                                _workout!.exercises.add(
                                  EditableWorkoutExercise(
                                    id: _uuid.v4(),
                                    orderIndex: _workout!.exercises.length,
                                    exerciseId: ex["exerciseId"],
                                    name: ex["name"],
                                    mediaUrl: ex["mediaUrl"],
                                    trackingType:
                                        ex["trackingType"] ?? "REPS_WEIGHT",
                                    restSeconds: null,
                                    supersetGroup: null,
                                    notes: null,
                                    sets: [
                                      EditableWorkoutSet(
                                        id: _uuid.v4(),
                                        setIndex: 0,
                                        reps: null,
                                        weightKg: null,
                                        tempo: null,
                                        isWarmup: false,
                                        isDropSet: false,
                                        dropOfSetId: null,
                                        restSec: null,
                                        isFailure: false,
                                      ),
                                    ],
                                  ),
                                );
                              }
                            });
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [scheme.primary, scheme.secondary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.lg),
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

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// Workout Card (UI unchanged, only logic wiring fixed)
/// ===============================================================
class _WorkoutCard extends StatefulWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  final EditableWorkoutExercise exercise;

  final String workoutId;
  final String workoutExerciseId;
  final VoidCallback onOpenSupersetSheet;

  final List<EditableWorkoutExercise> exercises;

  final VoidCallback onRefresh;
  final VoidCallback onAddSet;
  final void Function(String setId) onLongPressSet;
  final VoidCallback onOpenExerciseMenu;

  final TextEditingController Function(String setId, double? initial)
  getWeightCtrl;
  final TextEditingController Function(String setId, int? initial) getRepsCtrl;

  const _WorkoutCard({
    super.key,
    required this.scheme,
    required this.textTheme,
    required this.exercise,
    required this.workoutId,
    required this.onOpenSupersetSheet,
    required this.workoutExerciseId,
    required this.exercises,
    required this.onAddSet,
    required this.onRefresh,
    required this.onLongPressSet,
    required this.onOpenExerciseMenu,
    required this.getWeightCtrl,
    required this.getRepsCtrl,
  });

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard> {
  late final TextEditingController _notesController;

  final _uuid = const Uuid();
  String? _activeSetId;

  Color get _neutralBg => widget.scheme.brightness == Brightness.light
      ? AppColors.neutralLight
      : AppColors.neutralDark;

  @override
  void initState() {
    super.initState();

    _notesController = TextEditingController(text: widget.exercise.notes ?? "");
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _WorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.exercise.exerciseId != widget.exercise.exerciseId) {
      _notesController.text = "";
      _activeSetId = null;

      for (final s in widget.exercise.sets) {
        widget.getWeightCtrl(s.id, null).clear();
        widget.getRepsCtrl(s.id, null).clear();
      }
    }
  }

  void _openRestTimerSheet(BuildContext context, String title) {
    FocusManager.instance.primaryFocus?.unfocus();
    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    final isLight = scheme.brightness == Brightness.light;
    final highlightColor = isLight ? AppColors.primary : AppColors.secondary;

    int? initialSeconds =
        (widget.exercise.restSeconds != null &&
            widget.exercise.restSeconds! >= 5)
        ? widget.exercise.restSeconds!.clamp(5, 300)
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
    ).then((_) {
      FocusManager.instance.primaryFocus?.unfocus();

      int? finalSeconds = selectedIndex == 0 ? null : selectedIndex * 5;

      if (finalSeconds != initialSeconds) {
        setState(() {
          widget.exercise.restSeconds = finalSeconds;
        });
      }
    });
  }

  void _openDurationPicker(BuildContext context, EditableWorkoutSet set) {
    FocusManager.instance.primaryFocus?.unfocus();

    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    final isLight = scheme.brightness == Brightness.light;
    final highlightColor = isLight ? AppColors.primary : AppColors.secondary;

    int initial = set.durationSec ?? 0;

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

                    /// Center highlight
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

                  /// Drag handle
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// Title
                  Text(
                    "Set Duration",
                    style: textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// Exercise name
                  Text(
                    widget.exercise.name,
                    style: textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Wheels
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

                  /// Done button (optional close)
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
    ).then((_) {
      /// Commit duration when modal closes
      final total = hours * 3600 + minutes * 60 + seconds;

      if (set.durationSec != total) {
        setState(() {
          set.durationSec = total;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.exercise.name;
    final sets = widget.exercise.sets;
    final hasSets = sets.isNotEmpty;
    final imageUrl = widget.exercise.mediaUrl;
    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    final allSets = widget.exercise.sets;
    final trackingType = widget.exercise.trackingType;

    final isTimeExercise = trackingType == "TIME";
    final isRepsOnly = trackingType == "REPS";
    final isRepsWeight = trackingType == "REPS_WEIGHT";

    final isInSuperset = widget.exercise.supersetGroup != null;

    final normalSets = <EditableWorkoutSet>[];
    final Map<String, List<EditableWorkoutSet>> dropSets = {};

    for (final s in allSets) {
      if (s.isDropSet && s.dropOfSetId != null) {
        dropSets.putIfAbsent(s.dropOfSetId!, () => []);
        dropSets[s.dropOfSetId!]!.add(s);
      } else {
        normalSets.add(s);
      }
    }

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
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
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
                        errorBuilder: (context, error, stackTrace) =>
                            _imageFallback(scheme),
                      )
                    : _imageFallback(scheme),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadii.full),
                onTap: widget.onOpenExerciseMenu,
                child: const PhosphorIcon(
                  PhosphorIconsRegular.dotsThreeVertical,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          TextField(
            controller: _notesController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            cursorColor: scheme.primary,
            style: textTheme.bodySmall,
            onChanged: (value) {
              widget.exercise.notes = value;
            },
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
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () {
              FocusScope.of(context).unfocus(); // 👈 important
              _openRestTimerSheet(context, title);
            },
            child: Row(
              children: [
                const PhosphorIcon(PhosphorIconsRegular.clock, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  "Rest Timer : ${_formatRest(widget.exercise.restSeconds)}",
                  style: textTheme.bodyMedium!.copyWith(
                    color: widget.exercise.restSeconds == null
                        ? scheme.onSurface.withOpacity(0.5)
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          if (hasSets) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  /// SET
                  Expanded(
                    flex: 2,
                    child: Text(
                      'SET',
                      style: textTheme.bodySmall!.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  /// TIME MODE
                  if (isTimeExercise)
                    Flexible(
                      flex: 4,
                      child: Center(
                        child: Text(
                          'TIME',
                          style: textTheme.bodySmall!.copyWith(
                            fontWeight: AppTypography.wMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (isRepsOnly)
                    Flexible(
                      flex: 4,
                      child: Center(
                        child: Text(
                          'REPS',
                          style: textTheme.bodySmall!.copyWith(
                            fontWeight: AppTypography.wMedium,
                          ),
                        ),
                      ),
                    )
                  /// NORMAL MODE
                  else ...[
                    Flexible(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'KG',
                          style: textTheme.bodySmall!.copyWith(
                            fontWeight: AppTypography.wMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'REPS',
                          style: textTheme.bodySmall!.copyWith(
                            fontWeight: AppTypography.wMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),
          ],
          if (hasSets) ...[
            const SizedBox(height: AppSpacing.xs),

            Column(
              children: List.generate(normalSets.length, (index) {
                final set = normalSets[index];
                final setId = set.id;

                final weightKg = set.weightKg;
                final reps = set.reps;

                final weightController = widget.getWeightCtrl(setId, weightKg);
                final repsController = widget.getRepsCtrl(setId, reps);

                final drops = dropSets[setId] ?? [];

                return Column(
                  key: ValueKey(set.id),
                  children: [
                    /// NORMAL SET ROW
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _activeSetId = setId;
                          });
                        },
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        onLongPress: () => widget.onLongPressSet(setId),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _neutralBg,
                            borderRadius: BorderRadius.circular(AppRadii.md),
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
                                flex: 2,
                                child: Text(
                                  '${index + 1}',
                                  style: textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: AppSpacing.xs),

                              /// KG
                              if (isTimeExercise)
                                /// if (isTimeExercise)
                                Expanded(
                                  flex: 4,
                                  child: InkWell(
                                    onTap: () =>
                                        _openDurationPicker(context, set),
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: scheme.surface,
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.xs,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _formatDuration(set.durationSec),
                                          style: textTheme.bodyMedium!.copyWith(
                                            fontWeight: AppTypography.wSemibold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else if (isRepsOnly)
                                Expanded(
                                  flex: 4,
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
                                          onChanged: (value) {
                                            set.reps = int.tryParse(value);
                                          },
                                          expands: true,
                                          maxLines: null,
                                          minLines: null,
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
                                  flex: 2,
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
                                          onChanged: (value) {
                                            set.weightKg = double.tryParse(
                                              value,
                                            );
                                          },
                                          expands: true,
                                          maxLines: null,
                                          minLines: null,
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

                                /// REPS
                                Expanded(
                                  flex: 2,
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
                                          onChanged: (value) {
                                            set.reps = int.tryParse(value);
                                          },
                                          expands: true,
                                          maxLines: null,
                                          minLines: null,
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
                            ],
                          ),
                        ),
                      ),
                    ),

                    /// DROP SETS
                    ...drops.asMap().entries.map((entry) {
                      final dropIndex = entry.key;
                      final dropSet = entry.value;

                      final dropId = dropSet.id;

                      final weightController = widget.getWeightCtrl(
                        dropId,
                        dropSet.weightKg,
                      );

                      final repsController = widget.getRepsCtrl(
                        dropId,
                        dropSet.reps,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: [
                            /// indentation
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

                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _activeSetId = dropId;
                                  });
                                },
                                onLongPress: () =>
                                    widget.onLongPressSet(dropId),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _neutralBg.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.md,
                                    ),
                                    border: _activeSetId == dropId
                                        ? Border.all(
                                            color: widget.scheme.onSurface
                                                .withOpacity(0.20),
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
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "D${dropIndex + 1}",
                                          style: textTheme.bodyMedium!.copyWith(
                                            color: AppColors.accent,
                                            fontWeight: AppTypography.wSemibold,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: AppSpacing.xs),

                                      if (isTimeExercise)
                                        /// if (isTimeExercise)
                                        Expanded(
                                          flex: 4,
                                          child: InkWell(
                                            onTap: () => _openDurationPicker(
                                              context,
                                              dropSet,
                                            ),
                                            child: Container(
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: scheme.surface,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadii.xs,
                                                    ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _formatDuration(
                                                    dropSet.durationSec,
                                                  ),
                                                  style: textTheme.bodyMedium!
                                                      .copyWith(
                                                        fontWeight:
                                                            AppTypography
                                                                .wSemibold,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (isRepsOnly)
                                        Expanded(
                                          flex: 4,
                                          child: Container(
                                            height: 40,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(
                                              color: scheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadii.xs,
                                                  ),
                                            ),
                                            child: Center(
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: double.infinity,
                                                child: TextField(
                                                  controller: repsController,
                                                  onChanged: (value) {
                                                    dropSet.reps = int.tryParse(
                                                      value,
                                                    );
                                                  },
                                                  expands: true,
                                                  maxLines: null,
                                                  minLines: null,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: false,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                  textAlignVertical:
                                                      TextAlignVertical.center,
                                                  style: textTheme.bodyMedium!
                                                      .copyWith(
                                                        color: scheme.onSurface,
                                                        fontWeight:
                                                            AppTypography
                                                                .wSemibold,
                                                      ),
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText: "--",
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        border:
                                                            InputBorder.none,
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                        disabledBorder:
                                                            InputBorder.none,
                                                        errorBorder:
                                                            InputBorder.none,
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
                                          flex: 2,
                                          child: Container(
                                            height: 40,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(
                                              color: scheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadii.xs,
                                                  ),
                                            ),
                                            child: Center(
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: double.infinity,
                                                child: TextField(
                                                  controller: weightController,
                                                  onChanged: (value) {
                                                    dropSet.weightKg =
                                                        double.tryParse(value);
                                                  },
                                                  expands: true,
                                                  maxLines: null,
                                                  minLines: null,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                  textAlignVertical:
                                                      TextAlignVertical.center,
                                                  style: textTheme.bodyMedium!
                                                      .copyWith(
                                                        color: scheme.onSurface,
                                                        fontWeight:
                                                            AppTypography
                                                                .wSemibold,
                                                      ),
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText: "--",
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        border:
                                                            InputBorder.none,
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                        disabledBorder:
                                                            InputBorder.none,
                                                        errorBorder:
                                                            InputBorder.none,
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
                                          flex: 2,
                                          child: Container(
                                            height: 40,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(
                                              color: scheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadii.xs,
                                                  ),
                                            ),
                                            child: Center(
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: double.infinity,
                                                child: TextField(
                                                  controller: repsController,
                                                  onChanged: (value) {
                                                    dropSet.reps = int.tryParse(
                                                      value,
                                                    );
                                                  },
                                                  expands: true,
                                                  maxLines: null,
                                                  minLines: null,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: false,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                  textAlignVertical:
                                                      TextAlignVertical.center,
                                                  style: textTheme.bodyMedium!
                                                      .copyWith(
                                                        color: scheme.onSurface,
                                                        fontWeight:
                                                            AppTypography
                                                                .wSemibold,
                                                      ),
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText: "--",
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        border:
                                                            InputBorder.none,
                                                        enabledBorder:
                                                            InputBorder.none,
                                                        focusedBorder:
                                                            InputBorder.none,
                                                        disabledBorder:
                                                            InputBorder.none,
                                                        errorBorder:
                                                            InputBorder.none,
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
              onTap: () {
                final sets = widget.exercise.sets;

                int nextIndex = 1;

                if (sets.isNotEmpty) {
                  final highest = sets
                      .map((s) => s.setIndex)
                      .reduce((a, b) => a > b ? a : b);

                  nextIndex = highest + 1;
                }

                final newSet = EditableWorkoutSet(
                  id: _uuid.v4(),
                  setIndex: nextIndex,
                );

                setState(() {
                  sets.add(newSet);
                });
              },
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
                    onTap: () {
                      if (_activeSetId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Select a set first")),
                        );
                        return;
                      }

                      final sets = widget.exercise.sets;

                      /// currently selected set
                      final current = sets.firstWhere(
                        (s) => s.id == _activeSetId,
                      );

                      /// determine parent
                      final parentSetId = current.isDropSet
                          ? current.dropOfSetId
                          : current.id;

                      final parentSet = sets.firstWhere(
                        (s) => s.id == parentSetId,
                      );

                      /// existing drops under this parent
                      final existingDrops = sets
                          .where((s) => s.dropOfSetId == parentSetId)
                          .toList();

                      final dropCount = existingDrops.length;

                      /// weight source
                      double? weightSource = parentSet.weightKg;

                      if (weightSource == null) {
                        final previousSet =
                            sets
                                .where(
                                  (s) => !s.isDropSet && s.weightKg != null,
                                )
                                .toList()
                              ..sort(
                                (a, b) => b.setIndex.compareTo(a.setIndex),
                              );

                        if (previousSet.isNotEmpty) {
                          weightSource = previousSet.first.weightKg;
                        }
                      }

                      /// calculate drop weight (75% rounded to 2.5kg)
                      double? dropWeight;

                      if (weightSource != null) {
                        final raw = weightSource * 0.75;
                        dropWeight = (raw / 2.5).round() * 2.5;
                      }

                      final newDrop = EditableWorkoutSet(
                        id: _uuid.v4(),
                        setIndex: parentSet.setIndex + (dropCount + 1) * 10,
                        isDropSet: true,
                        dropOfSetId: parentSetId,
                        weightKg: dropWeight,
                      );

                      setState(() {
                        sets.add(newDrop);
                      });
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
                    onTap: widget.onOpenSupersetSheet,
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
                            isInSuperset ? 'Unlink' : 'Super Set',
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
        ],
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

class _SupersetSheet extends StatefulWidget {
  final String currentExerciseId;
  final String currentExerciseName;
  final String? currentExerciseImage;
  final List<EditableWorkoutExercise> exercises;
  final VoidCallback onUpdated;

  const _SupersetSheet({
    required this.currentExerciseId,
    required this.currentExerciseName,
    required this.currentExerciseImage,
    required this.exercises,
    required this.onUpdated,
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
        .where((e) => e.id != widget.currentExerciseId)
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
                          final exId = ex.id;

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _ExerciseOptionCard(
                              exercise: {
                                "name": ex.name,
                                "exercise": {"mediaUrl": ex.mediaUrl},
                              },
                              loading: _loadingExerciseId == exId,
                              onTap: () {
                                final exercises = widget.exercises;

                                final current = exercises.firstWhere(
                                  (e) => e.id == widget.currentExerciseId,
                                );

                                final target = exercises.firstWhere(
                                  (e) => e.id == exId,
                                );

                                String? group;

                                /// CASE 1: both already in supersets but different → merge
                                if (current.supersetGroup != null &&
                                    target.supersetGroup != null &&
                                    current.supersetGroup !=
                                        target.supersetGroup) {
                                  group = current.supersetGroup;

                                  final oldGroup = target.supersetGroup;

                                  for (final e in exercises) {
                                    if (e.supersetGroup == oldGroup) {
                                      e.supersetGroup = group;
                                    }
                                  }
                                }

                                /// CASE 2: one already in superset
                                group ??=
                                    current.supersetGroup ??
                                    target.supersetGroup;

                                /// CASE 3: create new superset
                                if (group == null) {
                                  final usedGroups = exercises
                                      .map((e) => e.supersetGroup)
                                      .where((g) => g != null)
                                      .toSet();

                                  String nextGroup = "A";

                                  while (usedGroups.contains(nextGroup)) {
                                    nextGroup = String.fromCharCode(
                                      nextGroup.codeUnitAt(0) + 1,
                                    );
                                  }

                                  group = nextGroup;
                                }

                                setState(() {
                                  current.supersetGroup = group;
                                  target.supersetGroup = group;
                                });

                                widget.onUpdated();

                                HapticFeedback.mediumImpact();
                                Navigator.pop(context);
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
  final List<EditableWorkoutExercise> exercises;

  const _ReorderExercisesSheet({
    required this.sessionId,
    required this.exercises,
  });

  @override
  State<_ReorderExercisesSheet> createState() => _ReorderExercisesSheetState();
}

class _ReorderExercisesSheetState extends State<_ReorderExercisesSheet> {
  late List<EditableWorkoutExercise> _items;

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

              /// Drag handle
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
                    final id = ex.id;
                    final image = ex.mediaUrl;

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
                                    ex.name,
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

                            /// Drag handle
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

                      onPressed: () {
                        for (int i = 0; i < _items.length; i++) {
                          _items[i].orderIndex = i;
                        }

                        Navigator.pop(context, _items);
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
