// ExerciseSearchScreen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/services/exercise_service.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:reptran_app/features/workout/presentation/state/active_workout_controller.dart';
import 'dart:async';

enum ExerciseAttachTargetType { session, workout }

class ExerciseAttachTarget {
  final ExerciseAttachTargetType type;
  final String id;

  const ExerciseAttachTarget({required this.type, required this.id});
}

const Map<String, List<String>> categoryMuscleMap = {
  "Push": ["chest", "shoulders", "triceps"],
  "Pull": ["lats", "upper back", "traps", "biceps"],
  "Legs": ["quadriceps", "hamstrings", "glutes", "calves"],
  "Core": ["abdominals", "lower back"],
};

const List<String> equipmentOptions = [
  "All Equipment",
  "none",
  "barbell",
  "dumbbell",
  "kettlebell",
  "machine",
  "plate",
  "resistance band",
  "suspension band",
];

const List<String> muscleOptions = [
  "All Muscles",
  "abdominals",
  "abductors",
  "adductors",
  "biceps",
  "calves",
  "cardio",
  "chest",
  "forearms",
  "full body",
  "glutes",
  "hamstrings",
  "lats",
  "lower back",
  "neck",
  "quadriceps",
  "shoulders",
  "traps",
  "triceps",
  "upper back",
  "other",
];

class ExerciseSearchPage extends StatefulWidget {
  final String targetType;
  final String targetId;
  final String? mode;
  final String? replaceExerciseId;

  const ExerciseSearchPage({
    super.key,
    required this.targetType,
    required this.targetId,
    this.mode,
    this.replaceExerciseId,
  });

  @override
  State<ExerciseSearchPage> createState() => _ExerciseSearchPageState();
}

class _ExerciseSearchPageState extends State<ExerciseSearchPage> {
  final _service = ExerciseService(); // or ExerciseService
  bool _loading = true;
  List<dynamic> _exercises = [];
  final Set<String> _selectedExerciseIds = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String? _searchQuery;
  bool _isSearchFocused = false;
  String? _category;
  String? _equipment;
  List<String>? _muscles;
  String _selectedCategory = "All";
  Timer? _debounce;
  String _selectedEquipment = "All Equipment";
  String _selectedMuscle = "All Muscles";
  final Map<String, Map<String, dynamic>> _selectedExercises = {};

  void _toggleSelect(String id) {
  if (widget.targetId.isEmpty) return;

  final exercise = _exercises.firstWhere((e) => e["id"] == id);

  setState(() {
    if (widget.mode == "replace") {
      _selectedExerciseIds.clear();
      _selectedExercises.clear();

      _selectedExerciseIds.add(id);
      _selectedExercises[id] = exercise;
    } else {
      if (_selectedExerciseIds.contains(id)) {
        _selectedExerciseIds.remove(id);
        _selectedExercises.remove(id);
      } else {
        _selectedExerciseIds.add(id);
        _selectedExercises[id] = exercise;
      }
    }
  });
}

void _clearSelection() {
  setState(() {
    _selectedExerciseIds.clear();
    _selectedExercises.clear();
  });
}

  @override
  void initState() {
    super.initState();

    _searchFocus.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocus.hasFocus;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.targetId.isNotEmpty) {
        _searchFocus.requestFocus();
      }
    });
    _fetchExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchExercises() async {
    try {
      setState(() {
        _loading = true;
      });

      final data = await _service.getExercises(
        search: _searchQuery,
        category: _category,
        equipment: _equipment,
        muscles: _muscles,
      );

      setState(() {
        _exercises = data;
      });
    } catch (e) {
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _addSelectedExercises() async {
    if (_selectedExerciseIds.isEmpty) return;

   final selectedExercises = _selectedExercises.values
    .map(
      (e) => {
        "exerciseId": e["id"],
        "name": e["name"],
        "mediaUrl": e["mediaUrl"],
        "trackingType": e["trackingType"],
      },
    )
    .toList();

    try {
      final exercise = selectedExercises.first;

      /// ---------- REPLACE MODE ----------
      if (widget.mode == "replace") {
        if (widget.targetType == "session") {
          /// LOGGER → show loader
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          await SessionService().replaceExercise(
            sessionId: widget.targetId,
            sessionExerciseId: widget.replaceExerciseId!,
            exerciseId: exercise["exerciseId"] as String,
          );

          if (mounted) {
            await context.read<ActiveWorkoutController>().refreshFromBackend();
          }

          if (context.mounted) Navigator.pop(context); // close loader
          if (context.mounted) context.pop(true);
        } else {
          /// BUILDER → instant replace (no loader)
          if (context.mounted) context.pop(exercise);
        }

        return;
      }

      /// ---------- ADD MODE ----------

      if (widget.targetType == "session") {
        /// LOGGER → show loader
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        final ids = selectedExercises
            .map<String>((e) => e["exerciseId"] as String)
            .toList();

        await SessionService().addExercisesToSession(
          sessionId: widget.targetId,
          exerciseIds: ids,
        );

        if (mounted) {
          await context.read<ActiveWorkoutController>().refreshFromBackend();
        }

        if (context.mounted) Navigator.pop(context);
        if (context.mounted) context.pop(true);
      } else {
        /// BUILDER → local state
        if (context.mounted) context.pop(selectedExercises);
      }
    } catch (e) {

      if (context.mounted) Navigator.pop(context);
    }
  }

  void _openFilterSheet({
    required String title,
    required List<String> options,
    required String selected,
    required Function(String) onSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: 420, // fixed height prevents layout overflow
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),

                  /// title
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(title, style: textTheme.titleLarge),
                  ),

                  /// scrollable list
                  Expanded(
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option == selected;

                        return _FilterListItem(
                          label: option,
                          selected: isSelected,
                          onTap: () {
                            Navigator.pop(context);
                            onSelected(option);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openEquipmentSheet() {
    _openFilterSheet(
      title: "Equipment",
      options: equipmentOptions,
      selected: _selectedEquipment,
      onSelected: (equipment) {
        setState(() {
          _selectedEquipment = equipment;
          _equipment = equipment == "All Equipment" ? null : equipment;
        });

        _fetchExercises();
      },
    );
  }

  void _openMuscleSheet() {
    _openFilterSheet(
      title: "Muscles",
      options: muscleOptions,
      selected: _selectedMuscle,
      onSelected: (muscle) {
        setState(() {
          _selectedMuscle = muscle;
          _muscles = muscle == "All Muscles" ? null : [muscle];
        });

        _fetchExercises();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // ---------- Top tools (search + recents + filters) are in a surface container ----------
    final topTools = Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      // in topTools
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxl,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text('Exercises.', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),

          // Search field (static)
          _SearchField(
            controller: _searchController,
            focusNode: _searchFocus,
            focused: _isSearchFocused,
            onChanged: (value) {
              _searchQuery = value;

              _debounce?.cancel();

              _debounce = Timer(const Duration(milliseconds: 350), () {
                _fetchExercises();
              });
            },
          ),

          // const SizedBox(height: AppSpacing.md),

          // Recent & Favorites title
          // Row(
          //   children: [
          //     Icon(
          //       PhosphorIconsRegular.heart,
          //       size: 24,
          //       color: scheme.onSurface.withValues(
          //         alpha: AppOpacities.secondary,
          //       ),
          //     ),
          //     const SizedBox(width: AppSpacing.xs),
          //     Text('RECENT & FAVORITES', style: textTheme.bodySmall),
          //   ],
          // ),
          // const SizedBox(height: AppSpacing.sm),

          // Recent shortcuts
          // Row(
          //   children: const [
          //     _CircleShortcut(emoji: '💪', label: 'Bench'),
          //     SizedBox(width: AppSpacing.sm),
          //     _CircleShortcut(emoji: '🏋️‍♂️', label: 'Squat'),
          //     SizedBox(width: AppSpacing.sm),
          //     _CircleShortcut(emoji: '⬆️', label: 'Pull-up'),
          //     SizedBox(width: AppSpacing.sm),
          //     _CircleShortcut(emoji: '🏋️', label: 'Deadlift'),
          //   ],
          // ),

          // const SizedBox(height: AppSpacing.md),
          // Divider(color: scheme.outline),
          const SizedBox(height: AppSpacing.md),

          // Filter chips row (temporarily hidden)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _FilterChipToken(
                label: 'All',
                selected: _selectedCategory == "All",
                onTap: () {
                  setState(() {
                    _selectedCategory = "All";
                    _category = null;
                    _muscles = null;
                  });
                  _fetchExercises();
                },
              ),

              _FilterChipToken(
                label: 'Push',
                selected: _selectedCategory == "Push",
                onTap: () {
                  setState(() {
                    _selectedCategory = "Push";
                    _category = null;
                    _muscles = categoryMuscleMap["Push"];

                    _searchController.clear();
                    _searchQuery = null;
                  });
                  _fetchExercises();
                },
              ),

              _FilterChipToken(
                label: 'Pull',
                selected: _selectedCategory == "Pull",
                onTap: () {
                  setState(() {
                    _selectedCategory = "Pull";
                    _category = null;
                    _muscles = categoryMuscleMap["Pull"];

                    _searchController.clear();
                    _searchQuery = null;
                  });
                  _fetchExercises();
                },
              ),

              _FilterChipToken(
                label: 'Legs',
                selected: _selectedCategory == "Legs",
                onTap: () {
                  setState(() {
                    _selectedCategory = "Legs";
                    _category = null;
                    _muscles = categoryMuscleMap["Legs"];

                    _searchController.clear();
                    _searchQuery = null;
                  });
                  _fetchExercises();
                },
              ),

              _FilterChipToken(
                label: 'Core',
                selected: _selectedCategory == "Core",
                onTap: () {
                  setState(() {
                    _selectedCategory = "Core";
                    _category = null;
                    _muscles = categoryMuscleMap["Core"];

                    _searchController.clear();
                    _searchQuery = null;
                  });
                  _fetchExercises();
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _FilterActionButton(
                  label: _selectedEquipment,
                  onTap: _openEquipmentSheet,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: _FilterActionButton(
                  label: _selectedMuscle,
                  onTap: _openMuscleSheet,
                ),
              ),
            ],
          ),
          // ✅ Spacer to preserve section height
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );

    Widget exerciseList;

    if (_loading) {
      exerciseList = const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_exercises.isEmpty) {
      exerciseList = Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsRegular.magnifyingGlass,
                size: 44,
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: AppOpacities.secondary,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                "No exercises found",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 4),

              Text(
                "Try adjusting your search",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
  exerciseList = ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: _exercises.length,
  itemBuilder: (context, index) {
    final ex = _exercises[index];

    final id = ex["id"]?.toString() ?? "";
    final name = ex["name"]?.toString() ?? "Unknown";
    final imageUrl = ex["mediaUrl"]?.toString();

    final equipment = (ex["equipment"] ?? []) as List;
    final muscles = (ex["muscles"] ?? []) as List;

    final isSelected = _selectedExerciseIds.contains(id);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _ExerciseCard(
        title: name,
        imageUrl: imageUrl,
        tagsLeft: equipment.take(2).map((e) => e.toString()).toList(),
        tagsRight: [
          if (ex["category"] != null) ex["category"].toString(),
          if (muscles.isNotEmpty) muscles.first.toString(),
        ],
        isSelected: isSelected,
        isSelectable: widget.targetId.isNotEmpty,
        onTap: () => _toggleSelect(id),
      ),
    );
  },
);
   
    }
    final selectedCount = _selectedExerciseIds.length;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(
                bottom: 140,
              ), // space for bottom bar
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top tools section with its own inner padding already
                      topTools,

                      const SizedBox(height: AppSpacing.md),

                      // The rest of the page uses standard horizontal padding
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Column(children: [exerciseList]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ✅ Bottom sticky bar
            if (widget.targetId.isNotEmpty && selectedCount > 0)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _SelectionBar(
                  count: selectedCount,
                  onCancel: _clearSelection,
                  onAdd: _addSelectedExercises,
                  mode: widget.mode,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ===================================================================
/// Widgets
/// ===================================================================

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final bool focused;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.focused,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color bg = isLight ? AppColors.neutralLight : AppColors.neutralDark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.full),

        /// 🔹 focus border now here
        border: Border.all(
          color: focused ? scheme.primary : scheme.outline,
          width: focused ? 1.6 : 1,
        ),

        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 22,
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),

          const SizedBox(width: AppSpacing.xs),

          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,

              /// 🔹 removes material background
              style: textTheme.bodySmall,
              cursorColor: scheme.primary,

              decoration: const InputDecoration(
                hintText: "Search Exercises",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          Icon(
            PhosphorIconsRegular.funnel,
            size: 20,
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
        ],
      ),
    );
  }
}

class _CircleShortcut extends StatelessWidget {
  final String emoji;
  final String label;
  const _CircleShortcut({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: AppOpacities.secondary),
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: AppBorders.boxOnePx(scheme),
          ),
          alignment: Alignment.center,
          child: Text(
            emoji,
            style: textTheme.titleMedium!.copyWith(color: scheme.onSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

class _FilterChipToken extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterChipToken({
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;

    final bg = selected
        ? scheme.primary
        : isLight
        ? AppColors.neutralLight
        : AppColors.neutralDark;

    final fg = selected
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: AppOpacities.secondary);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.full),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Text(label, style: textTheme.bodySmall!.copyWith(color: fg)),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final List<String> tagsLeft;
  final List<String> tagsRight;

  final bool isSelected;
  final VoidCallback? onTap;
  final bool isSelectable;

  const _ExerciseCard({
    required this.title,
    required this.tagsLeft,
    required this.tagsRight,
    this.imageUrl,
    this.isSelected = false,
    this.isSelectable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final leftPillBg = isLight ? AppColors.neutralLight : AppColors.neutralDark;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.85)
                : scheme.outlineVariant.withValues(alpha: 0.45),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: AppShadows.e1(scheme),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Container(
                    width: 52,
                    height: 52,
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    child: (imageUrl != null && imageUrl!.isNotEmpty)
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              PhosphorIconsRegular.barbell,
                              size: 24,
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          )
                        : Icon(
                            PhosphorIconsRegular.barbell,
                            size: 24,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                          ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        PhosphorIconsRegular.heart,
                        size: 18,
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Selection button
                if (isSelectable)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    height: 38,
                    width: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? scheme.secondary : scheme.primary,
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      boxShadow: AppShadows.e1(scheme),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isSelected
                          ? PhosphorIconsRegular.check
                          : PhosphorIconsRegular.plus,
                      size: 20,
                      color: scheme.onPrimary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Row 2: pills
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...tagsLeft.map(
                  (t) => _MiniPillTag(
                    label: t,
                    bg: leftPillBg,
                    fg: scheme.onSurface,
                  ),
                ),
                ...tagsRight.map(
                  (t) => _MiniPillTag(
                    label: t,
                    bg: scheme.secondary.withValues(alpha: 0.10),
                    fg: scheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPillTag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _MiniPillTag({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // ✅ smaller
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11, // ✅ smaller
          fontWeight: FontWeight.w600,
          color: fg.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onAdd;
  final String? mode;

  const _SelectionBar({
    required this.count,
    required this.onCancel,
    required this.onAdd,
    this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final label = mode == "replace"
        ? "Replace Exercise"
        : (count == 1 ? "Add 1 exercise" : "Add $count exercises");

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e2(scheme),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Cancel"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterListItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterListItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  String capitalizeWords(String text) {
    return text
        .split(' ')
        .map(
          (w) => w.isEmpty
              ? w
              : "${w[0].toUpperCase()}${w.substring(1).toLowerCase()}",
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bg = selected
        ? scheme.primary.withValues(alpha: 0.10)
        : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(capitalizeWords(label), style: textTheme.bodyMedium),
            ),
            if (selected)
              Icon(PhosphorIconsRegular.check, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _FilterActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool isLight = Theme.of(context).brightness == Brightness.light;

    final textColor = isLight ? scheme.primary : scheme.secondary;

    final bg = isLight ? AppColors.neutralLight : AppColors.neutralDark;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.full),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: AppBorders.boxOnePx(scheme),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 4),

            Icon(
              PhosphorIconsRegular.caretDown,
              size: 16,
              color: textColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
