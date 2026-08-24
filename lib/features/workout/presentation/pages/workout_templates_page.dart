import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/models/workout_template.dart';
import 'package:reptran_app/features/workout/services/session_service.dart';
import 'package:go_router/go_router.dart';

class WorkoutTemplatesPage extends StatefulWidget {
  const WorkoutTemplatesPage({super.key});

  @override
  State<WorkoutTemplatesPage> createState() => _WorkoutTemplatesPageState();
}

class _WorkoutTemplatesPageState extends State<WorkoutTemplatesPage> {
  final _service = SessionService();

  String _activeTab = "STARTER";
  final List<String> _activeFilters = ["beginner"]; // tags
  final Set<String> _savedTemplateIds = {};

  bool _loading = true;
  String? _error;
  List<WorkoutTemplateModel> _templates = [];

  static const _tabs = [
    ("Starter", "STARTER"),
    ("Standard", "STANDARD"),
    ("Quick", "QUICK"),
  ];

  static const _filters = [
    ("Gym", "gym"),
    ("Beginner", "beginner"),
    ("Full body", "full_body"),
    ("Push", "push"),
    ("Pull", "pull"),
    ("Legs", "legs"),
  ];

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
      final res = await _service.getTemplates(
        category: _activeTab,
        tags: _activeFilters,
      );

      setState(() {
        _templates = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Couldn't load templates right now.";
        _loading = false;
      });
    }
  }

  void _setTab(String tabKey) {
    if (_activeTab == tabKey) return;
    setState(() => _activeTab = tabKey);
    _fetch();
  }

void _toggleFilter(String tagKey) {
  setState(() {
    if (_activeFilters.contains(tagKey)) {
      // If tapping the already-selected filter → deselect it
      _activeFilters.clear();
    } else {
      // Single-select: clear previous and add new
      _activeFilters
        ..clear()
        ..add(tagKey);
    }
  });

  _fetch();
}


  void _toggleSave(String templateId) {
    setState(() {
      if (_savedTemplateIds.contains(templateId)) {
        _savedTemplateIds.remove(templateId);
      } else {
        _savedTemplateIds.add(templateId);
      }
    });
  }

  void _onStartTemplate(WorkoutTemplateModel t) async {
    try {
      final session = await SessionService().startSession(templateId: t.id);

      final sessionId = session["id"]?.toString();
      if (sessionId == null) return;

      if (context.mounted) {
        context.push('/workout/logger', extra: sessionId);
      }
    } catch (e) {
    }
  }

  void _onViewTemplate(WorkoutTemplateModel t) {
    context.push('/workout/templates/${t.id}');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
          "Templates",
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.search),
        //     color: scheme.onSurface,
        //     onPressed: () {
        //       // V1: later add search modal/field
        //     },
        //   ),
        // ],
      ),
      body: RefreshIndicator(
        color: scheme.primary,
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: AppSpacing.lg,
          ),
          children: [
            const SizedBox(height: AppSpacing.sm),

            // Subtitle
            Text(
              "Pick one and start. You can customize anytime.",
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.70),
                height: AppTypography.lhNormal,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Tabs
            _CategoryTabs(activeKey: _activeTab, onChanged: _setTab),

            const SizedBox(height: AppSpacing.sm),

            // Filters
            _FilterChipsRow(
              activeFilters: _activeFilters,
              onToggle: _toggleFilter,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Featured Card (static V1)
            _FeaturedTemplateCard(
              onStart: () {
                // If you want: pick the first QUICK template
                final quick = _templates.isNotEmpty ? _templates.first : null;
                if (quick != null) _onStartTemplate(quick);
              },
            ),

            const SizedBox(height: AppSpacing.sm),

            // Content
            if (_loading) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(color: scheme.primary),
                ),
              ),
            ] else if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              _ErrorState(message: _error!, onRetry: _fetch),
            ] else if (_templates.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _EmptyState(
                title: "No templates found",
                subtitle: "Try switching categories or removing filters.",
                onClearFilters: () {
                  setState(() => _activeFilters.clear());
                  _fetch();
                },
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.xs),
              for (final t in _templates)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TemplateCard(
                    template: t,
                    isSaved: _savedTemplateIds.contains(t.id),
                    onStart: () => _onStartTemplate(t),
                    onView: () => _onViewTemplate(t),
                    onToggleSave: () => _toggleSave(t.id),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final String activeKey;
  final void Function(String tabKey) onChanged;

  const _CategoryTabs({required this.activeKey, required this.onChanged});

  static const _tabs = [
    ("Starter", "STARTER"),
    ("Standard", "STANDARD"),
    ("Quick", "QUICK"),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: _tabs.map((t) {
        final label = t.$1;
        final key = t.$2;
        final isActive = activeKey == key;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: AnimatedContainer(
              duration: AppDurations.short,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? scheme.primary : scheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: isActive
                    ? null
                    : Border.all(color: scheme.outline.withValues(alpha: 0.7)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () => onChanged(key),
                child: Center(
                  child: Text(
                    label,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: isActive
                          ? AppTypography.wSemibold
                          : AppTypography.wMedium,
                      color: isActive ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  final List<String> activeFilters;
  final void Function(String tagKey) onToggle;

  const _FilterChipsRow({required this.activeFilters, required this.onToggle});

  static const _filters = [
    ("Gym", "gym"),
    ("Beginner", "beginner"),
    ("Full body", "full_body"),
    ("Push", "push"),
    ("Pull", "pull"),
    ("Legs", "legs"),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final label = _filters[index].$1;
          final key = _filters[index].$2;

          final isActive = activeFilters.contains(key);

          return InkWell(
            borderRadius: BorderRadius.circular(AppRadii.full),
            onTap: () => onToggle(key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(
                  color: isActive ? scheme.primary : scheme.outline,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: tt.bodySmall?.copyWith(
                    fontWeight: AppTypography.wMedium,
                    color: isActive ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedTemplateCard extends StatelessWidget {
  final VoidCallback onStart;

  const _FeaturedTemplateCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.secondary.withValues(alpha: 0.12),
            scheme.secondary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: AppShadows.e2(scheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "⭐ Recommended for today",
            style: tt.labelMedium?.copyWith(
              fontWeight: AppTypography.wSemibold,
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Center(
                  child: Text("⚡", style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quick Full Body",
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      "Perfect for busy days",
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.70),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      "4 exercises • 15 min",
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onStart,
              child: const Text("Start"),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final WorkoutTemplateModel template;
  final bool isSaved;
  final VoidCallback onStart;
  final VoidCallback onView;
  final VoidCallback onToggleSave;

  const _TemplateCard({
    required this.template,
    required this.isSaved,
    required this.onStart,
    required this.onView,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail (emoji placeholder)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadii.lg - 2),
            ),
            child: Center(
              child: Text(
                _emojiForCategory(template.category),
                style: const TextStyle(fontSize: 34),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  template.description ?? "",
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.70),
                    height: AppTypography.lhNormal,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  "${template.exerciseCount} exercises • ~${template.estimatedMinutes ?? 35} min",
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: template.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.5),
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

                const SizedBox(height: AppSpacing.sm),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onStart,
                          child: const Text("Start"),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    TextButton(onPressed: onView, child: const Text("View")),
                    // IconButton(
                    //   onPressed: onToggleSave,
                    //   icon: Icon(
                    //     isSaved ? Icons.bookmark : Icons.bookmark_border,
                    //     color: isSaved
                    //         ? scheme.primary
                    //         : scheme.onSurface.withValues(alpha: 0.55),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        return "💪";
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wBold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.70),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: onClearFilters,
              child: const Text("Clear filters"),
            ),
          ),
        ],
      ),
    );
  }
}
