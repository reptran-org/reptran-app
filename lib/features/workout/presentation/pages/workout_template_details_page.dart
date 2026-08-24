import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/models/workout_template.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';

class WorkoutTemplateDetailsPage extends StatefulWidget {
  final String templateId;

  const WorkoutTemplateDetailsPage({
    super.key,
    required this.templateId,
  });

  @override
  State<WorkoutTemplateDetailsPage> createState() =>
      _WorkoutTemplateDetailsPageState();
}

class _WorkoutTemplateDetailsPageState extends State<WorkoutTemplateDetailsPage> {
  final _service = SessionService();

  bool _loading = true;
  String? _error;
  WorkoutTemplateDetailsModel? _template;

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final t = await _service.getTemplateDetails(widget.templateId);

      setState(() {
        _template = t;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Couldn't load this template.";
        _loading = false;
      });
    }
  }

  void _onStartWorkout() {
    if (_template == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Start workout: ${_template!.title}")),
    );
  }

  void _onSaveAsWorkout() {
    if (_template == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved as workout: ${_template!.title}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final t = _template;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: scheme.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          t?.title ?? "Template",
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: scheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     onPressed: () => setState(() => _saved = !_saved),
        //     icon: Icon(
        //       _saved ? Icons.bookmark : Icons.bookmark_border,
        //       color: _saved
        //           ? scheme.primary
        //           : scheme.onSurface.withValues(alpha: AppOpacities.secondary),
        //     ),
        //   ),
        // ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: scheme.primary))
          : _error != null
              ? _DetailsError(message: _error!, onRetry: _fetch)
              : t == null
                  ? _DetailsError(message: "Template not found.", onRetry: _fetch)
                  : Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.sm,
                            right: AppSpacing.sm,
                            bottom: 120,
                          ),
                          children: [
                            const SizedBox(height: AppSpacing.sm),

                            // Hero Card
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(AppRadii.lg),
                                border: Border.all(
                                  color: scheme.outline.withValues(alpha: 0.35),
                                ),
                                boxShadow: AppShadows.e2(scheme),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _TemplateCover(
                                        coverUrl: t.coverImageUrl,
                                        category: t.category,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _CategoryPill(category: t.category),
                                            const SizedBox(height: AppSpacing.xs),

                                            Wrap(
                                              spacing: AppSpacing.xs,
                                              runSpacing: AppSpacing.xxs,
                                              children: t.tags.map((tag) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: scheme.surfaceVariant,
                                                    borderRadius: BorderRadius.circular(
                                                      AppRadii.full,
                                                    ),
                                                    border: Border.all(
                                                      color: scheme.outline.withValues(
                                                        alpha: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    tag,
                                                    style: tt.labelSmall?.copyWith(
                                                      color: scheme.primary,
                                                      fontWeight: AppTypography.wMedium,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),

                                            const SizedBox(height: AppSpacing.xs),

                                            Text(
                                              "${t.exerciseCount} exercises • ~${t.estimatedMinutes ?? 35} min",
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

                                  const SizedBox(height: AppSpacing.sm),

                                  Text(
                                    t.description ?? "",
                                    style: tt.bodySmall?.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.75),
                                      height: AppTypography.lhLoose,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),

                            Text(
                              "Exercises",
                              style: tt.titleMedium?.copyWith(
                                fontWeight: AppTypography.wBold,
                                color: scheme.onSurface,
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            for (int i = 0; i < t.exercises.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                child: _ExerciseCard(
                                  index: i + 1,
                                  ex: t.exercises[i],
                                ),
                              ),

                            const SizedBox(height: AppSpacing.md),

                            // Supportive card
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: scheme.secondary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                border: Border.all(
                                  color: scheme.secondary.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "Short on time? Start anyway — you can do fewer sets and still count it.",
                                textAlign: TextAlign.center,
                                style: tt.bodySmall?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.75),
                                  height: AppTypography.lhLoose,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Sticky bottom actions
                        // Positioned(
                        //   left: AppSpacing.sm,
                        //   right: AppSpacing.sm,
                        //   bottom: AppSpacing.sm,
                        //   child: Container(
                        //     padding: const EdgeInsets.all(AppSpacing.sm),
                        //     decoration: BoxDecoration(
                        //       color: scheme.surface,
                        //       borderRadius: BorderRadius.circular(AppRadii.lg),
                        //       border: Border.all(
                        //         color: scheme.outline.withValues(alpha: 0.35),
                        //       ),
                        //       boxShadow: AppShadows.e3(scheme),
                        //     ),
                        //     // child: Row(
                        //     //   children: [
                        //     //     Expanded(
                        //     //       child: SizedBox(
                        //     //         height: 48,
                        //     //         child: ElevatedButton(
                        //     //           onPressed: _onStartWorkout,
                        //     //           child: const Text("Start Workout"),
                        //     //         ),
                        //     //       ),
                        //     //     ),
                        //     //     const SizedBox(width: AppSpacing.sm),
                        //     //     Expanded(
                        //     //       child: SizedBox(
                        //     //         height: 48,
                        //     //         child: OutlinedButton(
                        //     //           onPressed: _onSaveAsWorkout,
                        //     //           child: const Text("Save as Workout"),
                        //     //         ),
                        //     //       ),
                        //     //     ),
                        //     //   ],
                        //     // ),
                          
                          
                        //   ),
                        // ),
                    
                    
                      ],
                    ),
    );
  }
}

class _TemplateCover extends StatelessWidget {
  final String? coverUrl;
  final String category;

  const _TemplateCover({
    required this.coverUrl,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.45),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: coverUrl != null && coverUrl!.isNotEmpty
            ? Image.network(
                coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    _emojiForCategory(category),
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              )
            : Center(
                child: Text(
                  _emojiForCategory(category),
                  style: const TextStyle(fontSize: 34),
                ),
              ),
      ),
    );
  }

  String _emojiForCategory(String category) {
    switch (category) {
      case "STARTER":
        return "🏋️";
      case "QUICK":
        return "⚡";
      default:
        return "🦾";
    }
  }
}

class _CategoryPill extends StatelessWidget {
  final String category;

  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    Color bg;
    switch (category) {
      case "STARTER":
        bg = AppColors.secondary;
        break;
      case "QUICK":
        bg = AppColors.accent;
        break;
      default:
        bg = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        category,
        style: tt.labelSmall?.copyWith(
          color: AppColors.whiteUtility,
          fontWeight: AppTypography.wBold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final int index;
  final WorkoutTemplateExerciseModel ex;

  const _ExerciseCard({
    required this.index,
    required this.ex,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasSeconds = ex.seconds > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.35),
        ),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // index block
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Center(
                  child: Text(
                    "$index",
                    style: tt.labelMedium?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text("🏋️", style: TextStyle(fontSize: 22)),
            ],
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.name,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wSemibold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                Row(
                  children: [
                    Text(
                      hasSeconds
                          ? "${ex.sets} × ${ex.seconds}s"
                          : "${ex.sets} × ${ex.reps}",
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      "•",
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.tertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      "Rest ${ex.restSeconds ?? 60}s",
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (ex.notes != null && ex.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    ex.notes!,
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.tertiary,
                      ),
                      fontStyle: FontStyle.italic,
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

class _DetailsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailsError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wMedium,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onRetry,
                  child: const Text("Retry"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
