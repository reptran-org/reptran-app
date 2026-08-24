import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/services/workout_plan_builder_service.dart';
import 'package:reptran_app/features/workout/services/routine_service.dart';
import 'package:flutter/services.dart';

enum PlanType { rotation, weekly }

enum RotationItemType { workout, rest }

enum WorkoutPickerSource { template, userWorkout }

class WorkoutPlanBuilderPage extends StatefulWidget {
  final String? mode; // "create" | "edit"
  final String? routineId;

  const WorkoutPlanBuilderPage({super.key, this.mode, this.routineId});

  @override
  State<WorkoutPlanBuilderPage> createState() => _WorkoutPlanBuilderPageState();
}

class _WorkoutPlanBuilderPageState extends State<WorkoutPlanBuilderPage> {
  final _service = WorkoutPlanBuilderService();
  final _routineService = RoutineService();

  final ScrollController _scrollController = ScrollController();
  bool get isEditMode =>
      widget.mode == "edit" && (widget.routineId?.isNotEmpty ?? false);

  int step = 1;

  // Plan Type
  PlanType planType = PlanType.rotation;

  // Weekly plan: frequency per week
  String weeklyFrequency = "3x";

  // Rotation plan: rest days rule (0/1/2/flex)
  String rotationRestRule = "1";

  final List<String> weekDays = const [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];
  List<String> selectedDays = ["Mon", "Wed", "Fri"];

  // Weekly assignments: day -> workout OR rest
  final Map<String, _WeeklyAssignment> weeklyAssignments = {};

  final TextEditingController titleController = TextEditingController(
    text: "My Routine",
  );

  final TextEditingController descriptionController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ==========================
  // Real backend data (picker)
  // ==========================
  bool isLoadingPickerData = true;
  String? pickerError;

  bool isLoadingRoutine = false;
  String? routineLoadError;

  List<WorkoutPickerItem> templateItems = [];
  List<WorkoutPickerItem> myWorkoutItems = [];

  // Rotation items (reorderable + supports rest items)
  List<_RotationItem> rotationItems = [
    _RotationItem(label: "Day 1", type: RotationItemType.workout),
    _RotationItem(label: "Day 2", type: RotationItemType.workout),
    _RotationItem(label: "Day 3", type: RotationItemType.rest),
  ];

  // Save state
  bool isSaving = false;

  int estimateMinutesFromExerciseCount(int exerciseCount) {
    return (5 + (exerciseCount * 6)).clamp(15, 999);
  }

  void _prefillFromRoutine(Map<String, dynamic> routine) {
    final title = routine["title"]?.toString() ?? "My Routine";
    final desc = routine["description"]?.toString();

    titleController.text = title;
    descriptionController.text = desc ?? "";

    final schedule = Map<String, dynamic>.from(
      (routine["schedule"] as Map?) ?? {},
    );

    final planTypeRaw = schedule["type"]?.toString();

    // Backend: "WEEKLY" or "CYCLE"
    final loadedPlanType = (planTypeRaw == "WEEKLY")
        ? PlanType.weekly
        : PlanType.rotation;

    final days = (routine["days"] as List?) ?? [];

    setState(() {
      planType = loadedPlanType;

      // Reset assignments to avoid mixing old state
      weeklyAssignments.clear();
      rotationItems = [];
    });

    if (loadedPlanType == PlanType.weekly) {
      // schedule.daysOfWeek expected ["Mon","Wed","Fri"]
      final schedule = Map<String, dynamic>.from(
        (routine["schedule"] as Map?) ?? {},
      );
      final daysOfWeek =
          (schedule["daysOfWeek"] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      setState(() {
        selectedDays = daysOfWeek.isEmpty ? ["Mon", "Wed", "Fri"] : daysOfWeek;

        // optional
        weeklyFrequency =
            schedule["weeklyFrequency"]?.toString() ?? weeklyFrequency;
      });

      // Fill assignments from routine.days
      for (final d in days) {
        final m = Map<String, dynamic>.from(d as Map);

        final title = m["title"]?.toString(); // "Mon"
        if (title == null || title.isEmpty) continue;

        final note = m["note"]?.toString();
        final templateId = m["templateId"]?.toString();
        final userWorkoutId = m["userWorkoutId"]?.toString();

        if (note == "REST") {
          weeklyAssignments[title] = const _WeeklyAssignment.rest();
          continue;
        }

        // For edit, we may not know exact title/exerciseCount unless backend returns it.
        // So we keep safe placeholders and still save correctly.
        WorkoutPickerItem? item;

        if (templateId != null) {
          try {
            item = templateItems.firstWhere((t) => t.id == templateId);
          } catch (_) {}
        }

        if (userWorkoutId != null) {
          try {
            item = myWorkoutItems.firstWhere((w) => w.id == userWorkoutId);
          } catch (_) {}
        }

        if (item != null) {
          weeklyAssignments[title] = _WeeklyAssignment.workout(
            source: item.source,
            id: item.id,
            title: item.title,
            exerciseCount: item.exerciseCount,
            estimatedMinutes:
                item.estimatedMinutes ??
                estimateMinutesFromExerciseCount(item.exerciseCount),
          );
        }
      }

      // keep Mon->Sun ordering
      selectedDays.sort(
        (a, b) => weekDays.indexOf(a).compareTo(weekDays.indexOf(b)),
      );
      return;
    }

    // Rotation / Cycle
    // final schedule = Map<String, dynamic>.from(
    //   (routine["schedule"] as Map?) ?? {},
    // );
    final restRule = schedule["restRule"]?.toString();

    setState(() {
      rotationRestRule = restRule ?? rotationRestRule;
    });

    final mappedRotation = <_RotationItem>[];

    for (final d in days) {
      final m = Map<String, dynamic>.from(d as Map);

      final dayIndex = (m["dayIndex"] as num?)?.toInt();
      final label =
          m["title"]?.toString() ??
          (dayIndex != null ? "Day ${dayIndex + 1}" : "Day");

      final note = m["note"]?.toString();
      final templateId = m["templateId"]?.toString();
      final userWorkoutId = m["userWorkoutId"]?.toString();

      if (note == "REST") {
        mappedRotation.add(
          _RotationItem(label: label, type: RotationItemType.rest),
        );
        continue;
      }

      WorkoutPickerItem? item;

      if (templateId != null) {
        try {
          item = templateItems.firstWhere((t) => t.id == templateId);
        } catch (_) {}
      }

      if (userWorkoutId != null) {
        try {
          item = myWorkoutItems.firstWhere((w) => w.id == userWorkoutId);
        } catch (_) {}
      }

      mappedRotation.add(
        _RotationItem(
          label: label,
          type: RotationItemType.workout,
          workout: item?.title ?? "Workout",
          exercises: item?.exerciseCount,
          estimatedMinutes: item?.estimatedMinutes,
          source: item?.source,
          templateId: templateId,
          userWorkoutId: userWorkoutId,
        ),
      );
    }

    setState(() {
      rotationItems = mappedRotation.isEmpty
          ? [_RotationItem(label: "Day 1", type: RotationItemType.workout)]
          : mappedRotation;

      _relabelRotationItems();
    });
  }

  Future<void> _maybeLoadRoutineForEdit() async {
    final isEdit =
        widget.mode == "edit" && (widget.routineId?.isNotEmpty ?? false);
    if (!isEdit) return;

    setState(() {
      isLoadingRoutine = true;
      routineLoadError = null;
    });
    try {
      final routine = await _routineService.getRoutineById(
        routineId: widget.routineId!,
      );


      final days = routine["days"] as List?;
      if (days != null) {
        for (final d in days) {
        }
      }

      _prefillFromRoutine(routine);

      setState(() => isLoadingRoutine = false);
    } catch (e) {
      setState(() {
        routineLoadError = e.toString();
        isLoadingRoutine = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchPickerData(); // load workouts first
    await _maybeLoadRoutineForEdit(); // then prefill
  }

  Future<void> _fetchPickerData() async {
    setState(() {
      isLoadingPickerData = true;
      pickerError = null;
    });

    try {
      final templatesRes = await _service.getTemplatesRaw(take: 50, skip: 0);
      final workoutsRes = await _service.getMyWorkoutsRaw();

      final templatesResult = (templatesRes["result"] as Map?) ?? {};
      final templatesList = (templatesResult["templates"] as List?) ?? [];

      final workoutsList = (workoutsRes["result"] as List?) ?? [];

      final mappedTemplates = templatesList.map((t) {
        final m = Map<String, dynamic>.from(t as Map);

        final exerciseCount = (m["exerciseCount"] as num?)?.toInt() ?? 0;
        final estimatedMinutes = (m["estimatedMinutes"] as num?)?.toInt();

        return WorkoutPickerItem(
          source: WorkoutPickerSource.template,
          id: (m["id"] ?? "").toString(),
          title: (m["title"] ?? "Template").toString(),
          description: m["description"]?.toString(),
          tags: (m["tags"] as List?)?.map((e) => e.toString()).toList() ?? [],
          exerciseCount: exerciseCount,
          estimatedMinutes:
              estimatedMinutes ??
              estimateMinutesFromExerciseCount(exerciseCount),
          previewExercises:
              const [], // templates list doesn't include exercises
        );
      }).toList();

      final mappedWorkouts = workoutsList.map((w) {
        final m = Map<String, dynamic>.from(w as Map);

        final exercises = (m["exercises"] as List?) ?? [];
        final preview = exercises.take(3).map((ex) {
          final exMap = Map<String, dynamic>.from(ex as Map);
          final customName = exMap["customName"]?.toString();
          final exerciseObj = exMap["exercise"];
          final nameFromExercise = (exerciseObj is Map)
              ? (exerciseObj["name"]?.toString())
              : null;

          return (customName?.trim().isNotEmpty ?? false)
              ? customName!.trim()
              : (nameFromExercise?.trim().isNotEmpty ?? false)
              ? nameFromExercise!.trim()
              : "Exercise";
        }).toList();

        final exerciseCount = exercises.length;
        final estimatedMinutes = estimateMinutesFromExerciseCount(
          exerciseCount,
        );

        return WorkoutPickerItem(
          source: WorkoutPickerSource.userWorkout,
          id: (m["id"] ?? "").toString(),
          title: (m["title"] ?? "Workout").toString(),
          description: m["description"]?.toString(),
          tags: const [],
          exerciseCount: exerciseCount,
          estimatedMinutes: estimatedMinutes,
          previewExercises: preview,
        );
      }).toList();

      setState(() {
        templateItems = mappedTemplates;
        myWorkoutItems = mappedWorkouts;
        isLoadingPickerData = false;
      });

     
    } catch (e) {
      setState(() {
        pickerError = e.toString();
        isLoadingPickerData = false;
      });
    }
  }

  void nextStep() {
    setState(() {
      step = (step + 1).clamp(1, 3);
    });

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void prevStep() {
    setState(() {
      step = (step - 1).clamp(1, 3);
    });

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  String getRotationGoalLabel() {
    switch (rotationRestRule) {
      case "0":
        return "Train daily";
      case "1":
        return "Rest every other day";
      case "2":
        return "2 rest days between sessions";
      case "flex":
        return "Flexible rhythm";
      default:
        return "Rest every other day";
    }
  }

  Future<void> openWorkoutPicker({
    int? rotationIndex,
    String? weeklyDay,
  }) async {
    final selected = await showModalBottomSheet<WorkoutPickerItem?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkoutPickerSheet(
        templates: templateItems,
        myWorkouts: myWorkoutItems,
        isLoading: isLoadingPickerData,
        error: pickerError,
        onRetry: _fetchPickerData,
      ),
    );

    if (selected == null) return;

    final minutes =
        selected.estimatedMinutes ??
        estimateMinutesFromExerciseCount(selected.exerciseCount);

    // Rotation
    if (planType == PlanType.rotation && rotationIndex != null) {
      setState(() {
        rotationItems[rotationIndex] = rotationItems[rotationIndex].copyWith(
          type: RotationItemType.workout,
          workout: selected.title,
          exercises: selected.exerciseCount,
          estimatedMinutes: minutes,
          source: selected.source,
          templateId: selected.source == WorkoutPickerSource.template
              ? selected.id
              : null,
          userWorkoutId: selected.source == WorkoutPickerSource.userWorkout
              ? selected.id
              : null,
        );
      });
      return;
    }

    // Weekly
    if (planType == PlanType.weekly && weeklyDay != null) {
      setState(() {
        weeklyAssignments[weeklyDay] = _WeeklyAssignment.workout(
          source: selected.source,
          id: selected.id,
          title: selected.title,
          exerciseCount: selected.exerciseCount,
          estimatedMinutes: minutes,
        );
      });
    }
  }

  void setWeeklyRestDay(String day) {
    setState(() {
      weeklyAssignments[day] = const _WeeklyAssignment.rest();
    });
  }

  void addRotationWorkoutDay() {
    if (rotationItems.length >= 8) return;
    setState(() {
      rotationItems.add(
        _RotationItem(
          label: "Day ${rotationItems.length + 1}",
          type: RotationItemType.workout,
        ),
      );
      _relabelRotationItems();
    });
  }

  void addRotationRestDay() {
    if (rotationItems.length >= 8) return;
    setState(() {
      rotationItems.add(
        _RotationItem(
          label: "Day ${rotationItems.length + 1}",
          type: RotationItemType.rest,
        ),
      );
      _relabelRotationItems();
    });
  }

  void removeRotationItem(int index) {
    if (rotationItems.length <= 1) return;
    setState(() {
      rotationItems.removeAt(index);
      _relabelRotationItems();
    });
  }

  void _relabelRotationItems() {
    rotationItems = rotationItems
        .asMap()
        .entries
        .map((e) => e.value.copyWith(label: "Day ${e.key + 1}"))
        .toList();
  }

  void reorderRotationItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = rotationItems.removeAt(oldIndex);
      rotationItems.insert(newIndex, item);
      _relabelRotationItems();
    });
  }

  bool _isWeeklyReady() {
    if (selectedDays.isEmpty) return false;

    // must have assignment for each selected day
    for (final d in selectedDays) {
      if (!weeklyAssignments.containsKey(d)) return false;
    }
    return true;
  }

  bool _isRotationReady() {
    // at least 1 workout day chosen
    for (final r in rotationItems) {
      if (r.type == RotationItemType.workout &&
          (r.workout?.trim().isNotEmpty ?? false)) {
        return true;
      }
    }
    return false;
  }

  Future<void> savePlan() async {
    if (isSaving) return;

    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a plan title.")),
      );
      return;
    }

    final isWeekly = planType == PlanType.weekly;

    if (isWeekly && !_isWeeklyReady()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please assign workouts/rest days for all selected days.",
          ),
        ),
      );
      return;
    }

    if (!isWeekly && !_isRotationReady()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please choose at least 1 workout in your rotation."),
        ),
      );
      return;
    }

    final isEditMode =
        widget.mode == "edit" && (widget.routineId?.trim().isNotEmpty ?? false);

    setState(() => isSaving = true);

    try {
      final payload = _buildSavePayload(
        title: title,
        description: description.isEmpty ? null : description,
      );


      Map<String, dynamic> routine;

      if (isEditMode) {
        routine = await _service.updateRoutineRaw(
          routineId: widget.routineId!,
          payload: payload,
        );
      } else {
        routine = await _service.createRoutineRaw(payload: payload);
      }

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? "Plan updated successfully ✅"
                : "Plan saved successfully ✅",
          ),
        ),
      );

      // Optional: go back after save
      // Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode ? "Failed to update plan" : "Failed to save plan",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Map<String, dynamic> _buildSavePayload({
    required String title,
    required String? description,
  }) {
    if (planType == PlanType.weekly) {
      // Keep in correct order Mon -> Sun but only selected
      final orderedDays = weekDays
          .where((d) => selectedDays.contains(d))
          .toList();

      final routineDays = <Map<String, dynamic>>[];

      for (int i = 0; i < orderedDays.length; i++) {
        final day = orderedDays[i];
        final a = weeklyAssignments[day]!;

        if (a.isRest) {
          routineDays.add({"dayIndex": i, "title": day, "note": "REST"});
          continue;
        }

        routineDays.add({
          "dayIndex": i,
          "title": day,
          "templateId": a.source == WorkoutPickerSource.template ? a.id : null,
          "userWorkoutId": a.source == WorkoutPickerSource.userWorkout
              ? a.id
              : null,
        });
      }

      return {
        "title": title,
        "description": description,
        "planType": "WEEKLY",

        "schedule": {
          "type": "WEEKLY",
          "daysOfWeek": orderedDays, // ["Mon","Wed","Fri"]
          "weeklyFrequency": weeklyFrequency, // optional, your choice
        },
        "days": routineDays,
      };
    }

    // ROTATION / CYCLE
    final routineDays = <Map<String, dynamic>>[];

    for (int i = 0; i < rotationItems.length; i++) {
      final r = rotationItems[i];

      if (r.type == RotationItemType.rest) {
        routineDays.add({"dayIndex": i, "title": r.label, "note": "REST"});
        continue;
      }

      routineDays.add({
        "dayIndex": i,
        "title": r.label,
        "templateId": r.templateId,
        "userWorkoutId": r.userWorkoutId,
      });
    }

    return {
      "title": title,
      "description": description,
      "planType": "CYCLE",
      "schedule": {
        "type": "CYCLE",
        "restRule": rotationRestRule, // "0" | "1" | "2" | "flex"
      },
      "days": routineDays,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return PopScope(
      canPop: step == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (step > 1) {
          setState(() {
            step -= 1;
          });
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                color: scheme.surface,
                child: Column(
                  children: [
                    // ===== Progress Header =====
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        border: AppBorders.boxCard(scheme),
                        boxShadow: AppShadows.e0,
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Row(
                        children: List.generate(3, (i) {
                          final index = i + 1;
                          final isActive = step >= index;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 450),
                              height: 6,
                              margin: EdgeInsets.only(
                                right: i == 2 ? 0 : AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? scheme.primary
                                    : scheme.outlineVariant.withValues(
                                        alpha: 0.6,
                                      ),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.full,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // ===== Body =====
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.xxl,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: step == 1
                              ? _ScreenOne(
                                  key: const ValueKey("s1"),
                                  scheme: scheme,
                                  tt: tt,
                                  planType: planType,
                                  isEditMode: isEditMode,
                                  weeklyFrequency: weeklyFrequency,
                                  rotationRestRule: rotationRestRule,
                                  onPlanTypeChange: (t) =>
                                      setState(() => planType = t),
                                  onWeeklyFrequencyChange: (f) =>
                                      setState(() => weeklyFrequency = f),
                                  onRotationRestRuleChange: (v) =>
                                      setState(() => rotationRestRule = v),
                                  onContinue: nextStep,
                                )
                              : step == 2
                              ? _ScreenTwo(
                                  key: const ValueKey("s2"),
                                  scheme: scheme,
                                  tt: tt,
                                  planType: planType,
                                  weekDays: weekDays,
                                  selectedDays: selectedDays,
                                  isEditMode: isEditMode,
                                  weeklyAssignments: weeklyAssignments,
                                  rotationItems: rotationItems,
                                  onBack: prevStep,
                                  onContinue: nextStep,
                                  onSetRotationRest: (idx) {
                                    setState(() {
                                      rotationItems[idx] = rotationItems[idx]
                                          .copyWith(
                                            type: RotationItemType.rest,
                                            workout: null,
                                            exercises: null,
                                            estimatedMinutes: null,
                                            templateId: null,
                                            userWorkoutId: null,
                                          );
                                    });
                                  },
                                  onToggleDay: (day) {
                                    setState(() {
                                      if (selectedDays.contains(day)) {
                                        selectedDays.remove(day);
                                      } else {
                                        selectedDays.add(day);
                                      }

                                      // ✅ keep in Mon→Sun order always
                                      selectedDays.sort(
                                        (a, b) => weekDays
                                            .indexOf(a)
                                            .compareTo(weekDays.indexOf(b)),
                                      );
                                    });
                                  },

                                  onChooseRotationWorkout: (idx) =>
                                      openWorkoutPicker(rotationIndex: idx),
                                  onChooseWeeklyWorkout: (day) =>
                                      openWorkoutPicker(weeklyDay: day),
                                  onWeeklyRest: setWeeklyRestDay,
                                  onAddRotationWorkoutDay:
                                      addRotationWorkoutDay,
                                  onAddRotationRestDay: addRotationRestDay,
                                  onRemoveRotationItem: removeRotationItem,
                                  onReorderRotationItems: reorderRotationItems,
                                )
                              : _ScreenThree(
                                  key: const ValueKey("s3"),
                                  scheme: scheme,
                                  tt: tt,
                                  planType: planType,
                                  isEditMode: isEditMode,
                                  titleController: titleController,
                                  descriptionController: descriptionController,
                                  weeklyFrequency: weeklyFrequency,
                                  rotationGoalLabel: getRotationGoalLabel(),
                                  selectedDays: selectedDays,
                                  weeklyAssignments: weeklyAssignments,
                                  rotationItems: rotationItems,
                                  onBack: prevStep,
                                  isSaving: isSaving,
                                  onSave: savePlan,
                                  onStart: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Starting first workout (mock).",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================
// SCREEN 1
// =======================================================

class _ScreenOne extends StatelessWidget {
  const _ScreenOne({
    super.key,
    required this.scheme,
    required this.tt,
    required this.planType,
    required this.isEditMode,
    required this.weeklyFrequency,
    required this.rotationRestRule,
    required this.onPlanTypeChange,
    required this.onWeeklyFrequencyChange,
    required this.onRotationRestRuleChange,
    required this.onContinue,
  });

  final ColorScheme scheme;
  final TextTheme tt;

  final PlanType planType;
  final String weeklyFrequency;
  final String rotationRestRule;
  final bool isEditMode;

  final ValueChanged<PlanType> onPlanTypeChange;
  final ValueChanged<String> onWeeklyFrequencyChange;
  final ValueChanged<String> onRotationRestRuleChange;
  final VoidCallback onContinue;

  String _rotationRestRuleLabel(String v) {
    switch (v) {
      case "0":
        return "Train daily (nudge after ~24h).";
      case "1":
        return "Rest every other day (nudge after ~48h).";
      case "2":
        return "More recovery (nudge after ~72h).";
      case "flex":
        return "Flexible rhythm (gentle nudge ~48h, stronger ~96h).";
      default:
        return "Rest every other day.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeekly = planType == PlanType.weekly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditMode)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  "EDITING",
                  style: tt.labelSmall?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

        Text(
          isEditMode ? "Review your plan structure" : "Build your plan",
          style: tt.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isEditMode
              ? "Your structure is already set. You can update workouts later."
              : "Pick a structure that fits your life right now.",
          style: tt.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: scheme.tertiary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: scheme.tertiary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.info, size: 18, color: scheme.tertiary),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  "Plans aren’t promises — they’re support.",
                  style: tt.bodySmall?.copyWith(
                    color: scheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        _PlanTypeCard(
          scheme: scheme,
          tt: tt,
          isSelected: planType == PlanType.rotation,
          isRecommended: true,
          icon: PhosphorIconsRegular.arrowsClockwise,
          title: "Rotation split",
          subtitle: "Best if you train in order, any day.",
          hint: "Rotation means you always do the next workout in order.",
          footer: "PUSH  →  PULL  →  LEGS  →  REPEAT",
          onTap: isEditMode ? null : () => onPlanTypeChange(PlanType.rotation),
        ),
        const SizedBox(height: AppSpacing.md),
        _PlanTypeCard(
          scheme: scheme,
          tt: tt,
          isSelected: planType == PlanType.weekly,
          isRecommended: false,
          icon: PhosphorIconsRegular.calendarBlank,
          title: "Weekly schedule",
          subtitle: "Best if you train on specific days.",
          hint: null,
          footer: "MON • WED • FRI",
          onTap: isEditMode ? null : () => onPlanTypeChange(PlanType.weekly),
        ),

        if (isEditMode) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.lock,
                size: 16,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  "Structure locked for this plan. You can still change workouts.",
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        if (isWeekly) ...[
          Text(
            isEditMode
                ? "Training frequency"
                : "How often do you want to show up?",
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: AppBorders.boxCard(scheme),
              boxShadow: AppShadows.e0,
            ),
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: Row(
              children: ["2x", "3x", "4x", "5x", "6x"].map((f) {
                final isActive = weeklyFrequency == f;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onWeeklyFrequencyChange(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? scheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Center(
                        child: Text(
                          f,
                          style: tt.titleSmall?.copyWith(
                            color: isActive
                                ? scheme.onPrimary
                                : scheme.onSurface.withValues(
                                    alpha: AppOpacities.secondary,
                                  ),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        if (!isWeekly) ...[
          Text("Rest between sessions", style: tt.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: AppBorders.boxCard(scheme),
              boxShadow: AppShadows.e0,
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _MiniChoicePill(
                  scheme: scheme,
                  tt: tt,
                  label: "0",
                  isActive: rotationRestRule == "0",
                  onTap: () => onRotationRestRuleChange("0"),
                ),
                _MiniChoicePill(
                  scheme: scheme,
                  tt: tt,
                  label: "1",
                  isActive: rotationRestRule == "1",
                  onTap: () => onRotationRestRuleChange("1"),
                ),
                _MiniChoicePill(
                  scheme: scheme,
                  tt: tt,
                  label: "2",
                  isActive: rotationRestRule == "2",
                  onTap: () => onRotationRestRuleChange("2"),
                ),
                _MiniChoicePill(
                  scheme: scheme,
                  tt: tt,
                  label: "Flex",
                  isActive: rotationRestRule == "flex",
                  onTap: () => onRotationRestRuleChange("flex"),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _rotationRestRuleLabel(rotationRestRule),
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),

        _PrimaryButton(
          scheme: scheme,
          label: isEditMode ? "Edit workouts" : "Continue",
          trailingIcon: PhosphorIconsRegular.caretRight,
          onTap: onContinue,
        ),
      ],
    );
  }
}

// =======================================================
// SCREEN 2
// =======================================================

class _ScreenTwo extends StatelessWidget {
  const _ScreenTwo({
    super.key,
    required this.scheme,
    required this.tt,
    required this.planType,
    required this.weekDays,
    required this.selectedDays,
    required this.weeklyAssignments,
    required this.rotationItems,
    required this.onBack,
    required this.onContinue,
    required this.onToggleDay,
    required this.onChooseRotationWorkout,
    required this.onChooseWeeklyWorkout,
    required this.onWeeklyRest,
    required this.onAddRotationWorkoutDay,
    required this.onAddRotationRestDay,
    required this.onRemoveRotationItem,
    required this.onReorderRotationItems,
    required this.onSetRotationRest,
    required this.isEditMode,
  });

  final ColorScheme scheme;
  final TextTheme tt;

  final PlanType planType;

  final List<String> weekDays;
  final List<String> selectedDays;
  final Map<String, _WeeklyAssignment> weeklyAssignments;

  final List<_RotationItem> rotationItems;

  final VoidCallback onBack;
  final VoidCallback onContinue;
  final void Function(int index) onSetRotationRest;

  final ValueChanged<String> onToggleDay;

  final ValueChanged<int> onChooseRotationWorkout;
  final ValueChanged<String> onChooseWeeklyWorkout;
  final ValueChanged<String> onWeeklyRest;
  final bool isEditMode;

  final VoidCallback onAddRotationWorkoutDay;
  final VoidCallback onAddRotationRestDay;

  final ValueChanged<int> onRemoveRotationItem;
  final void Function(int oldIndex, int newIndex) onReorderRotationItems;

  @override
  Widget build(BuildContext context) {
    final isWeekly = planType == PlanType.weekly;

    void _openRotationDayOptions(
      BuildContext context,
      int idx,
      _RotationItem item,
    ) {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) {
          return _RotationDayOptionsSheet(
            item: item,
            onChooseWorkout: () {
              Navigator.pop(sheetContext);
              onChooseRotationWorkout(idx);
            },
            onSetRest: () {
              Navigator.pop(sheetContext);
              onSetRotationRest(idx);
            },
            onRemoveDay: () {
              Navigator.pop(sheetContext);
              onRemoveRotationItem(idx);
            },
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(
                PhosphorIconsRegular.arrowLeft,
                color: scheme.onSurface.withValues(
                  alpha: AppOpacities.secondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditMode ? "Edit your workouts" : "Choose your workouts",
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isWeekly
                        ? (isEditMode
                              ? "Update workouts or adjust rest days."
                              : "Pick your days, then assign workouts (or rest).")
                        : (isEditMode
                              ? "Reorder sessions or change workouts."
                              : "Set your training order (and rest days)."),
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (isWeekly) ...[
          Text(
            "CHOOSE DAYS",
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: weekDays.map((d) {
              final isActive = selectedDays.contains(d);
              return GestureDetector(
                onTap: () => onToggleDay(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? scheme.primary : scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      width: 2,
                      color: isActive
                          ? scheme.primary
                          : scheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Text(
                    d,
                    style: tt.labelLarge?.copyWith(
                      color: isActive
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            "ASSIGNED DAYS",
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (selectedDays.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: AppBorders.boxCard(scheme),
              ),
              child: Text(
                "Pick at least 1 day to build your weekly plan.",
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: selectedDays.map((day) {
                final assigned = weeklyAssignments[day];

                final isRest = assigned?.isRest ?? false;
                final title = assigned == null
                    ? "Choose Workout"
                    : isRest
                    ? "Rest Day"
                    : assigned.title;

                final meta = assigned == null
                    ? null
                    : isRest
                    ? "Recovery counts as progress."
                    : "${assigned.estimatedMinutes} min • ${assigned.exerciseCount} exercises";

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PlanRowCard(
                    scheme: scheme,
                    tt: tt,
                    label: day.toUpperCase(),
                    title: title ?? "Choose Workout",

                    meta: meta,
                    showDragHandle: false,
                    actionLabel: assigned == null ? "Choose" : "Change",
                    onActionTap: () => onChooseWeeklyWorkout(day),
                    leadingIcon: Icon(
                      isRest
                          ? PhosphorIconsRegular.moonStars
                          : PhosphorIconsRegular.calendarBlank,
                      size: 20,
                      color: isRest ? scheme.tertiary : scheme.secondary,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: AppSpacing.xs),

          if (selectedDays.isNotEmpty)
            _OutlineButton(
              scheme: scheme,
              label: "Set selected day as Rest",
              leadingIcon: PhosphorIconsRegular.moonStars,
              onTap: () async {
                // quick rest picker
                final day = await showModalBottomSheet<String?>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => _WeeklyRestPicker(days: selectedDays),
                );

                if (day == null) return;
                onWeeklyRest(day);
              },
            ),
        ],

        if (!isWeekly) ...[
          Text(
            "YOUR ROTATION",
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
            ),
          ),

         

          const SizedBox(height: AppSpacing.sm),

          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rotationItems.length,
            onReorder: onReorderRotationItems,
            buildDefaultDragHandles: false,
            itemBuilder: (context, idx) {
              final item = rotationItems[idx];
              final isRest = item.type == RotationItemType.rest;

              final title = isRest
                  ? "Rest Day"
                  : (item.workout ?? "Choose Workout");
              final meta = isRest
                  ? "Recovery counts as progress."
                  : (item.workout != null
                        ? "${item.estimatedMinutes ?? 0} min • ${item.exercises ?? 0} exercises"
                        : null);

              final actionLabel = isRest
                  ? "Remove"
                  : (item.workout != null ? "Change" : "Choose");

              return Padding(
                key: ValueKey("rotation_$idx"),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _openRotationDayOptions(context, idx, item);
                  },
                  child: _PlanRowCard(
                    scheme: scheme,
                    tt: tt,
                    label: item.label.toUpperCase(),
                    title: title,
                    meta: meta,
                    showDragHandle: true,
                    actionLabel: actionLabel,
                    onActionTap: () {
                      if (isRest) {
                        onRemoveRotationItem(idx);
                        return;
                      }
                      onChooseRotationWorkout(idx);
                    },
                    dragHandle: ReorderableDragStartListener(
                      index: idx,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Icon(
                          PhosphorIconsRegular.dotsSixVertical,
                          size: 22,
                          color: scheme.onSurface.withValues(alpha: 0.30),
                        ),
                      ),
                    ),
                    leadingIcon: isRest
                        ? Icon(
                            PhosphorIconsRegular.moonStars,
                            size: 20,
                            color: scheme.tertiary,
                          )
                        : Icon(
                            PhosphorIconsRegular.barbell,
                            size: 20,
                            color: scheme.secondary,
                          ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.xs),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onAddRotationWorkoutDay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      border: Border.all(
                        width: 2,
                        color: scheme.outlineVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "+ Add workout day",
                        style: tt.labelLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: onAddRotationRestDay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      border: Border.all(
                        width: 2,
                        color: scheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "+ Add rest day",
                        style: tt.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        _PrimaryButton(
          scheme: scheme,
          label: isEditMode ? "Review changes" : "Review plan",

          trailingIcon: PhosphorIconsRegular.caretRight,
          onTap: onContinue,
        ),
      ],
    );
  }
}

// =======================================================
// SCREEN 3
// =======================================================

class _ScreenThree extends StatelessWidget {
  const _ScreenThree({
    super.key,
    required this.scheme,
    required this.tt,
    required this.planType,
    required this.titleController,
    required this.descriptionController,

    required this.weeklyFrequency,
    required this.rotationGoalLabel,
    required this.selectedDays,
    required this.weeklyAssignments,
    required this.rotationItems,
    required this.onBack,
    required this.onSave,
    required this.onStart,
    required this.isSaving,
    required this.isEditMode,
  });

  final ColorScheme scheme;
  final TextTheme tt;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  final PlanType planType;
  final String weeklyFrequency;
  final String rotationGoalLabel;

  final List<String> selectedDays;
  final Map<String, _WeeklyAssignment> weeklyAssignments;
  final List<_RotationItem> rotationItems;
  final bool isEditMode;

  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onStart;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final isWeekly = planType == PlanType.weekly;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // black card in light mode, theme surface in dark mode (clean)
    final cardBg = isDark
        ? scheme.surfaceContainerHighest
        : const Color(0xFF1E1E1E);
    final titleColor = isDark ? scheme.onSurface : Colors.white;
    final mutedColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.45);

    final dividerColor = isDark
        ? scheme.outlineVariant.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.08);

    final goalText = isWeekly ? "$weeklyFrequency / week" : rotationGoalLabel;

    final itemsCount = isWeekly ? selectedDays.length : rotationItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditMode)
  Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: scheme.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Text(
          "EDITING",
          style: tt.labelSmall?.copyWith(
            color: scheme.secondary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    ],
  ),

        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(
                PhosphorIconsRegular.arrowLeft,
                color: scheme.onSurface.withValues(
                  alpha: AppOpacities.secondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                isEditMode ? "Review your changes" : "Review your plan",
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          "Name your plan",
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Keep it short. You can change it later.",
          style: tt.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.65),
              width: 1.5,
            ),
            boxShadow: AppShadows.e0,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Title =====
              Text(
                "TITLE",
                style: tt.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    hintText: "e.g. PPL Rotation",
                    hintStyle: tt.titleMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w800,
                    ),

                    // ✅ kill inner borders completely
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,

                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ===== Description =====
              Text(
                "DESCRIPTION (OPTIONAL)",
                style: tt.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  minLines: 1,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Why this plan works for you",
                    hintStyle: tt.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.35),
                    ),

                    // ✅ kill inner borders completely
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,

                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? scheme.outlineVariant.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: AppShadows.e2(scheme),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "STRUCTURE",
                          style: tt.labelSmall?.copyWith(
                            color: mutedColor,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isWeekly ? "Weekly Split" : "Rotation Split",
                          style: tt.titleMedium?.copyWith(
                            color: scheme.secondary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "GOAL",
                          style: tt.labelSmall?.copyWith(
                            color: mutedColor,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          goalText,
                          style: tt.titleMedium?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(color: dividerColor),
              const SizedBox(height: AppSpacing.md),

              ...List.generate(itemsCount, (i) {
                if (isWeekly) {
                  final day = selectedDays[i];
                  final a = weeklyAssignments[day];

                  final isRest = a?.isRest ?? false;

                  final sessionTitle = a == null
                      ? "Not assigned"
                      : isRest
                      ? "Rest Day"
                      : a.title;

                  final meta = (a == null || isRest)
                      ? (isRest ? "Recovery counts as progress." : null)
                      : "${a.estimatedMinutes} min • ${a.exerciseCount} exercises";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        _IndexBubble(
                          scheme: scheme,
                          tt: tt,
                          isDark: isDark,
                          index: i + 1,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day.toUpperCase(),
                                style: tt.labelSmall?.copyWith(
                                  color: mutedColor,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sessionTitle ?? "Training Session",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodyMedium?.copyWith(
                                  color: titleColor.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (meta != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  meta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodySmall?.copyWith(
                                    color: mutedColor,
                                    fontWeight: FontWeight.w600,
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

                final r = rotationItems[i];
                final isRest = r.type == RotationItemType.rest;

                final sessionTitle = isRest
                    ? "Rest Day"
                    : (r.workout ?? "Choose Workout");
                final meta = (!isRest && r.workout != null)
                    ? "${r.estimatedMinutes ?? 0} min • ${r.exercises ?? 0} exercises"
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      _IndexBubble(
                        scheme: scheme,
                        tt: tt,
                        isDark: isDark,
                        index: i + 1,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SESSION ${i + 1}",
                              style: tt.labelSmall?.copyWith(
                                color: mutedColor,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sessionTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyMedium?.copyWith(
                                color: titleColor.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (meta != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        _PrimaryButton(
          scheme: scheme,
          label: isSaving
    ? "Saving..."
    : isEditMode
        ? "Update plan"
        : "Save plan",

          trailingIcon: PhosphorIconsRegular.floppyDisk,
          onTap: isSaving ? () {} : onSave,
        ),
        const SizedBox(height: AppSpacing.sm),
       if (!isEditMode)
  _OutlineButton(
    scheme: scheme,
    label: "Start first workout",
    leadingIcon: PhosphorIconsFill.play,
    onTap: onStart,
  ),

      ],
    );
  }
}

class _IndexBubble extends StatelessWidget {
  const _IndexBubble({
    required this.scheme,
    required this.tt,
    required this.isDark,
    required this.index,
  });

  final ColorScheme scheme;
  final TextTheme tt;
  final bool isDark;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surface.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Center(
        child: Text(
          "$index",
          style: tt.labelMedium?.copyWith(
            color: scheme.secondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// =======================================================
// PICKER SHEET
// =======================================================

class _WorkoutPickerSheet extends StatefulWidget {
  const _WorkoutPickerSheet({
    required this.templates,
    required this.myWorkouts,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final List<WorkoutPickerItem> templates;
  final List<WorkoutPickerItem> myWorkouts;

  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  State<_WorkoutPickerSheet> createState() => _WorkoutPickerSheetState();
}

class _WorkoutPickerSheetState extends State<_WorkoutPickerSheet> {
  int tabIndex = 0; // 0 = templates, 1 = my workouts

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final items = tabIndex == 0 ? widget.templates : widget.myWorkouts;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: AppShadows.e2(scheme),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: Text(
                    "Select Workout",
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _TabPill(
                      scheme: scheme,
                      tt: tt,
                      isActive: tabIndex == 0,
                      label: "Templates",
                      onTap: () => setState(() => tabIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _TabPill(
                      scheme: scheme,
                      tt: tt,
                      isActive: tabIndex == 1,
                      label: "My Workouts",
                      onTap: () => setState(() => tabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            if (widget.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      "Loading workouts...",
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (widget.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(
                    color: scheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Failed to load workouts",
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.error!,
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onErrorContainer.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _SecondaryButton(
                      scheme: scheme,
                      label: "Retry",
                      onTap: widget.onRetry,
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 440),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final w = items[i];

                    final meta =
                        "${w.estimatedMinutes ?? "—"} min • ${w.exerciseCount} exercises";

                    final previewText = w.previewExercises.isEmpty
                        ? null
                        : "${w.previewExercises.join(", ")}${w.exerciseCount > 3 ? " (+more)" : ""}";

                    return GestureDetector(
                      onTap: () => Navigator.pop(context, w),
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            width: 2,
                            color: scheme.outlineVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.title,
                                        style: tt.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        meta,
                                        style: tt.bodySmall?.copyWith(
                                          color: scheme.onSurface.withValues(
                                            alpha: AppOpacities.secondary,
                                          ),
                                        ),
                                      ),
                                      if (previewText != null) ...[
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(
                                          previewText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: tt.bodySmall?.copyWith(
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.55,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.lg,
                                    ),
                                  ),
                                  child: Icon(
                                    PhosphorIconsRegular.caretRight,
                                    size: 18,
                                    color: scheme.onSurface.withValues(
                                      alpha: AppOpacities.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (w.tags.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xxs,
                                children: w.tags
                                    .take(6)
                                    .map(
                                      (t) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xs,
                                          vertical: AppSpacing.xxs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.md,
                                          ),
                                          border: Border.all(
                                            color: scheme.outlineVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        child: Text(
                                          t.toUpperCase(),
                                          style: tt.labelSmall?.copyWith(
                                            color: scheme.onSurface.withValues(
                                              alpha: AppOpacities.secondary,
                                            ),
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyRestPicker extends StatelessWidget {
  const _WeeklyRestPicker({required this.days});

  final List<String> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              "Pick a day to set Rest",
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: AppSpacing.md),

            ...days.map((d) {
              return ListTile(
                title: Text(
                  d,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                trailing: Icon(
                  PhosphorIconsRegular.moonStars,
                  color: scheme.tertiary,
                ),
                onTap: () => Navigator.pop(context, d),
              );
            }),
          ],
        ),
      ),
    );
  }
}
// =======================================================
// Shared UI widgets
// =======================================================

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.scheme,
    required this.tt,
    required this.isActive,
    required this.label,
    required this.onTap,
  });

  final ColorScheme scheme;
  final TextTheme tt;
  final bool isActive;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: isActive ? AppShadows.e0 : null,
        ),
        child: Center(
          child: Text(
            label,
            style: tt.labelLarge?.copyWith(
              color: isActive
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.scheme,
    required this.label,
    required this.onTap,
    this.trailingIcon,
  });

  final ColorScheme scheme;
  final String label;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: AppShadows.e2(scheme),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: tt.titleMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(trailingIcon, size: 18, color: scheme.onPrimary),
            ],
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.scheme,
    required this.label,
    required this.onTap,
  });

  final ColorScheme scheme;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Text(
          label,
          style: tt.labelLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.scheme,
    required this.label,
    required this.onTap,
    this.leadingIcon,
  });

  final ColorScheme scheme;
  final String label;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: AppBorders.boxCard(scheme),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: tt.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRowCard extends StatelessWidget {
  const _PlanRowCard({
    required this.scheme,
    required this.tt,
    required this.label,
    required this.title,
    required this.meta,
    required this.showDragHandle,
    required this.actionLabel,
    required this.onActionTap,
    this.dragHandle,
    this.leadingIcon,
  });

  final ColorScheme scheme;
  final TextTheme tt;

  final String label;
  final String title;
  final String? meta;

  final bool showDragHandle;
  final String actionLabel;
  final VoidCallback onActionTap;

  final Widget? dragHandle;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e0,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          if (showDragHandle) dragHandle ?? const SizedBox.shrink(),
          if (leadingIcon != null) ...[
            leadingIcon!,
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.labelSmall?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (meta != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    meta!,
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _SecondaryButton(
            scheme: scheme,
            label: actionLabel,
            onTap: onActionTap,
          ),
        ],
      ),
    );
  }
}

// =======================================================
// PlanType Cards / Pills
// =======================================================

class _MiniChoicePill extends StatelessWidget {
  const _MiniChoicePill({
    required this.scheme,
    required this.tt,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final ColorScheme scheme;
  final TextTheme tt;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isActive ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Center(
            child: Text(
              label,
              style: tt.labelLarge?.copyWith(
                color: isActive
                    ? scheme.onPrimary
                    : scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanTypeCard extends StatelessWidget {
  const _PlanTypeCard({
    required this.scheme,
    required this.tt,
    required this.isSelected,
    required this.isRecommended,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.onTap,
    required this.hint,
  });

  final ColorScheme scheme;
  final TextTheme tt;

  final bool isSelected;
  final bool isRecommended;
  final IconData icon;
  final String title;
  final String subtitle;
  final String footer;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null && !isSelected ? 0.6 : 1,

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: scheme.surface,

            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              width: 2,
              color: isSelected
                  ? scheme.primary
                  : (onTap == null
                        ? scheme.outlineVariant.withValues(alpha: 0.4)
                        : scheme.outlineVariant.withValues(alpha: 0.7)),
            ),
            boxShadow: isSelected ? AppShadows.e1(scheme) : AppShadows.e0,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.primary
                          : scheme.secondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isSelected ? scheme.onPrimary : scheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (isRecommended && isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,

                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(
                        "RECOMMENDED",
                        style: tt.labelSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hint!,
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                footer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.labelSmall?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================
// MODELS
// =======================================================

class WorkoutPickerItem {
  final WorkoutPickerSource source;
  final String id;
  final String title;

  final String? description;
  final List<String> tags;

  final int exerciseCount;
  final int? estimatedMinutes;

  final List<String> previewExercises;

  const WorkoutPickerItem({
    required this.source,
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.exerciseCount,
    required this.estimatedMinutes,
    required this.previewExercises,
  });
}

class _RotationItem {
  final String label;
  final RotationItemType type;

  final String? workout;
  final int? estimatedMinutes;
  final int? exercises;

  final WorkoutPickerSource? source;
  final String? templateId;
  final String? userWorkoutId;

  const _RotationItem({
    required this.label,
    required this.type,
    this.workout,
    this.estimatedMinutes,
    this.exercises,
    this.source,
    this.templateId,
    this.userWorkoutId,
  });

  _RotationItem copyWith({
    String? label,
    RotationItemType? type,
    String? workout,
    int? estimatedMinutes,
    int? exercises,
    WorkoutPickerSource? source,
    String? templateId,
    String? userWorkoutId,
  }) {
    return _RotationItem(
      label: label ?? this.label,
      type: type ?? this.type,
      workout: workout ?? this.workout,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      exercises: exercises ?? this.exercises,
      source: source ?? this.source,
      templateId: templateId ?? this.templateId,
      userWorkoutId: userWorkoutId ?? this.userWorkoutId,
    );
  }
}

class _WeeklyAssignment {
  final bool isRest;

  final WorkoutPickerSource? source;
  final String? id;
  final String? title;
  final int? exerciseCount;
  final int? estimatedMinutes;

  const _WeeklyAssignment.rest()
    : isRest = true,
      source = null,
      id = null,
      title = null,
      exerciseCount = null,
      estimatedMinutes = null;

  const _WeeklyAssignment.workout({
    required WorkoutPickerSource source,
    required String id,
    required String title,
    required int exerciseCount,
    required int estimatedMinutes,
  }) : isRest = false,
       source = source,
       id = id,
       title = title,
       exerciseCount = exerciseCount,
       estimatedMinutes = estimatedMinutes;
}

class _RotationDayOptionsSheet extends StatelessWidget {
  final _RotationItem item;
  final VoidCallback onChooseWorkout;
  final VoidCallback onSetRest;
  final VoidCallback onRemoveDay;

  const _RotationDayOptionsSheet({
    required this.item,
    required this.onChooseWorkout,
    required this.onSetRest,
    required this.onRemoveDay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final errorColor = scheme.error;

    final isRest = item.type == RotationItemType.rest;
    final hasWorkout = item.workout != null && item.workout!.trim().isNotEmpty;

    final List<Widget> actions = [];

    if (isRest) {
      actions.add(
        ListTile(
          leading: const PhosphorIcon(PhosphorIconsRegular.plusCircle),
          title: const Text("Choose Workout"),
          onTap: onChooseWorkout,
        ),
      );
    } else {
      actions.add(
        ListTile(
          leading: const PhosphorIcon(PhosphorIconsRegular.swap),
          title: Text(hasWorkout ? "Change Workout" : "Choose Workout"),
          onTap: onChooseWorkout,
        ),
      );

      actions.add(
        ListTile(
          leading: const PhosphorIcon(PhosphorIconsRegular.moonStars),
          title: const Text("Set as Rest Day"),
          onTap: onSetRest,
        ),
      );
    }

    actions.add(
      ListTile(
        leading: const PhosphorIcon(PhosphorIconsRegular.trash),
        title: Text("Remove Day", style: TextStyle(color: errorColor)),
        onTap: onRemoveDay,
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// HEADER
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (hasWorkout) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.workout!,
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: .6),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            /// ACTIONS
            Column(
              children: List.generate(actions.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i == actions.length - 1 ? 0 : AppSpacing.sm,
                  ),
                  child: actions[i],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
