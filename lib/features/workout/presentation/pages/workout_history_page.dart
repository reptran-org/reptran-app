// workout_history_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/presentation/pages/workout_history_details_page.dart';
import 'package:reptran_app/features/workout/services/user_workout_service.dart';
import 'package:go_router/go_router.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ExercisePreview {
  final String id;
  final String name;
  final String? mediaUrl;

  ExercisePreview({required this.id, required this.name, this.mediaUrl});

  factory ExercisePreview.fromJson(Map<String, dynamic> json) =>
      ExercisePreview(
        id: json['id'],
        name: json['name'],
        mediaUrl: json['mediaUrl'],
      );
}

class WorkoutHistoryItem {
  final String id;
  final String title;
  final DateTime completedAt;
  final int durationMin;
  final int totalSets;
  final int totalReps;
  final List<ExercisePreview> exercises;

  WorkoutHistoryItem({
    required this.id,
    required this.title,
    required this.completedAt,
    required this.durationMin,
    required this.totalSets,
    required this.totalReps,
    required this.exercises,
  });

  factory WorkoutHistoryItem.fromJson(Map<String, dynamic> json) =>
      WorkoutHistoryItem(
        id: json['id'],
        title: json['title'],
        completedAt: DateTime.parse(json['completedAt']),
        durationMin: json['durationMin'] ?? 0,
        totalSets: json['totalSets'] ?? 0,
        totalReps: json['totalReps'] ?? 0,
        exercises: (json['exercises'] as List)
            .map((e) => ExercisePreview.fromJson(e))
            .toList(),
      );
}

class _Section {
  final String label;
  final List<WorkoutHistoryItem> items;
  _Section({required this.label, required this.items});
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  final _service = UserWorkoutService();

  List<WorkoutHistoryItem> _history = [];
  bool _loading = false;
  bool _hasMore = true;
  Map<String, dynamic>? _cursor;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && _hasMore) _fetchHistory();
    }
  }

  Future<void> _fetchHistory() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res = await _service.getWorkoutHistory(cursor: _cursor);
      final items = (res['items'] as List)
          .map((e) => WorkoutHistoryItem.fromJson(e))
          .toList();
      setState(() {
        _history.addAll(items);
        _cursor = res['nextCursor'];
        _hasMore = res['nextCursor'] != null;
      });
    } catch (e) {
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Grouping ────────────────────────────────────────────────────────────────

  List<_Section> get _sections {
    if (_history.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    final Map<String, List<WorkoutHistoryItem>> groups = {};

    for (final item in _history) {
      final d = DateTime(
        item.completedAt.year,
        item.completedAt.month,
        item.completedAt.day,
      );

      String key;
      if (d == today) {
        key = 'Today';
      } else if (d == yesterday) {
        key = 'Yesterday';
      } else if (!d.isBefore(startOfWeek)) {
        key = _weekdayName(d.weekday);
      } else {
        key = '${_monthName(d.month)} ${d.year}';
      }

      groups.putIfAbsent(key, () => []).add(item);
    }

    return groups.entries
        .map((e) => _Section(label: e.key, items: e.value))
        .toList();
  }

  String _weekdayName(int wd) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[wd - 1];
  }

  String _monthName(int m) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[m - 1];
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${days[local.weekday - 1]}, ${local.day} ${months[local.month - 1]} · $h:$m $period';
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sections = _sections;

    final List<Widget> listItems = [];

    for (final section in sections) {
      listItems.add(_SectionHeader(label: section.label));
      for (final item in section.items) {
        listItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _HistoryCard(
              item: item,
              formattedDate: _formatDate(item.completedAt),
            ),
          ),
        );
      }
    }

    if (!_loading && _history.isEmpty) {
      listItems.add(const _EmptyState());
    }

    if (_loading || _hasMore) {
      listItems.add(const _LoaderFooter());
    } else if (_history.isNotEmpty) {
      listItems.add(const _EndOfList());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyHeaderDelegate(
                    child: _PageHeader(totalCount: _history.length),
                    extent: 82,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => listItems[i],
                      childCount: listItems.length,
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

// ─── Sticky Header Delegate ───────────────────────────────────────────────────

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;

  _StickyHeaderDelegate({required this.child, required this.extent});

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(_StickyHeaderDelegate old) =>
      old.child != child || old.extent != extent;
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final int totalCount;
  const _PageHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline, width: 1)),
      ),
      child: SizedBox(
        height: 82, // ✅ MUST match Sliver extent
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // ✅ key fix
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout History',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: AppTypography.wSemibold,
                      ),
                    ),
                    const SizedBox(height: 2), // ✅ reduced spacing
                    Text(
                      'Your complete training journal',
                      style: tt.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (totalCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    '$totalCount sessions',
                    style: tt.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: AppTypography.wSemibold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],

              _HeaderIconButton(
                icon: PhosphorIconsRegular.funnel,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: AppBorders.boxCard(scheme),
        ),
        child: Icon(
          icon,
          size: 18,
          color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              letterSpacing: 1.0,
              fontWeight: AppTypography.wSemibold,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.outline, scheme.outline.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatefulWidget {
  final WorkoutHistoryItem item;
  final String formattedDate;

  const _HistoryCard({required this.item, required this.formattedDate});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/workout/workout-history/${item.id}');
      },
      child: AnimatedScale(
        scale: _pressed ? AppAnimation.pressScale : 1.0,
        duration: AppAnimation.microInteraction,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: AppBorders.boxCard(scheme),
            boxShadow: AppShadows.e2(scheme),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left gradient accent bar ──
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [scheme.primary, AppColors.secondary],
                    ),
                  ),
                ),

                // ── Card Body ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title + caret ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: AppTypography.wSemibold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              PhosphorIconsRegular.caretRight,
                              size: 16,
                              color: scheme.onSurface.withValues(
                                alpha: AppOpacities.tertiary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xxs),

                        // ── Date ──
                        Text(
                          widget.formattedDate,
                          style: tt.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(
                              alpha: AppOpacities.secondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // ── Stat chips ──
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xxs,
                          children: [
                            _StatChip(
                              icon: PhosphorIconsRegular.timer,
                              label: '${item.durationMin} min',
                            ),
                            _StatChip(
                              icon: PhosphorIconsRegular.barbell,
                              label: '${item.totalSets} sets',
                            ),
                            _StatChip(
                              icon: PhosphorIconsRegular.arrowsClockwise,
                              label: '${item.totalReps} reps',
                            ),
                          ],
                        ),

                        // ── Exercise Avatar Row ──
                        if (item.exercises.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _ExerciseAvatarRow(exercises: item.exercises),
                        ],
                      ],
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

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              fontWeight: AppTypography.wMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Exercise Avatar Row ──────────────────────────────────────────────────────

class _ExerciseAvatarRow extends StatelessWidget {
  final List<ExercisePreview> exercises;

  const _ExerciseAvatarRow({required this.exercises});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    const double avatarSize = 30.0;
    const double overlap = 10.0;
    const int maxShown = 4;

    final shown = exercises.take(maxShown).toList();
    final remaining = exercises.length - maxShown;

    final int bubbleCount = shown.length + (remaining > 0 ? 1 : 0);
    final double stackWidth = bubbleCount * (avatarSize - overlap) + overlap;

    return Row(
      children: [
        SizedBox(
          height: avatarSize,
          width: stackWidth,
          child: Stack(
            children: [
              for (int i = 0; i < shown.length; i++)
                Positioned(
                  left: i * (avatarSize - overlap),
                  child: _ExerciseAvatar(exercise: shown[i], size: avatarSize),
                ),
              if (remaining > 0)
                Positioned(
                  left: shown.length * (avatarSize - overlap),
                  child: _MoreBubble(count: remaining, size: avatarSize),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            exercises.length == 1
                ? exercises[0].name
                : '${exercises[0].name} & ${exercises.length - 1} more',
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ExerciseAvatar extends StatelessWidget {
  final ExercisePreview exercise;
  final double size;

  const _ExerciseAvatar({required this.exercise, required this.size});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary.withValues(alpha: 0.10),
        border: Border.all(color: scheme.surface, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: exercise.mediaUrl != null
          ? Image.network(
              exercise.mediaUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarPlaceholder(size: size),
            )
          : _AvatarPlaceholder(size: size),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final double size;
  const _AvatarPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Icon(
        PhosphorIconsRegular.barbell,
        size: size * 0.42,
        color: scheme.primary.withValues(alpha: 0.6),
      ),
    );
  }
}

class _MoreBubble extends StatelessWidget {
  final int count;
  final double size;

  const _MoreBubble({required this.count, required this.size});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.surface, width: 2),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            fontSize: 9,
            fontWeight: AppTypography.wSemibold,
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Icon(
              PhosphorIconsRegular.barbell,
              size: 34,
              color: scheme.primary.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No workouts yet',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemibold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Complete your first session and it\nwill appear here',
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Loader Footer ────────────────────────────────────────────────────────────

class _LoaderFooter extends StatelessWidget {
  const _LoaderFooter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}

// ─── End of List ──────────────────────────────────────────────────────────────

class _EndOfList extends StatelessWidget {
  const _EndOfList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 1,
            width: 40,
            color: scheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'All caught up',
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            height: 1,
            width: 40,
            color: scheme.outline.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

// class _InsightsCard extends StatelessWidget {
//   const _InsightsCard();

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;

//     return Container(
//       decoration: BoxDecoration(
//         color: scheme.secondary.withValues(alpha: 0.10),
//         borderRadius: BorderRadius.circular(AppRadii.lg),
//         border: Border.all(color: scheme.secondary.withValues(alpha: 0.15)),
//         boxShadow: AppShadows.e1(scheme),
//       ),
//       padding: const EdgeInsets.all(AppSpacing.sm),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 PhosphorIconsRegular.lightbulb,
//                 size: 24,
//                 color: scheme.primary,
//               ),
//               const SizedBox(width: AppSpacing.sm),
//               Expanded(child: Text('Training Insights', style: tt.titleMedium)),
//             ],
//           ),

//           // ✅ The alignment fix:
//           Padding(
//             padding: const EdgeInsets.only(left: 32), // 24 icon + 8 spacing
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: AppSpacing.sm),
//                 RichText(
//                   text: TextSpan(
//                     style: tt.bodySmall,
//                     children: [
//                       const TextSpan(text: 'You train most consistently on '),
//                       TextSpan(
//                         text: 'Tuesdays ',
//                         style: tt.bodySmall?.copyWith(color: scheme.primary),
//                       ),
//                       const TextSpan(text: 'and '),
//                       TextSpan(
//                         text: 'Fridays',
//                         style: tt.bodySmall?.copyWith(color: scheme.primary),
//                       ),
//                       const TextSpan(text: '.'),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: AppSpacing.xs),
//                 RichText(
//                   text: TextSpan(
//                     style: tt.bodySmall,
//                     children: [
//                       const TextSpan(text: 'Average duration: '),
//                       TextSpan(
//                         text: '38 minutes',
//                         style: tt.bodySmall?.copyWith(color: scheme.primary),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
