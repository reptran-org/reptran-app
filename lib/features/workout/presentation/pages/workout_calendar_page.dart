// WorkoutCalendarPage.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/services/progress_service.dart';

// ============================================================
// DATA MODEL
// ============================================================

class _CalDay {
  const _CalDay({
    required this.date,
    required this.volume,
    required this.duration,
    required this.sessions,
    required this.workedOut,
    required this.intensity,
    required this.isStreakDay,
  });

  final String date;
  final double volume;
  final int duration;
  final int sessions;
  final bool workedOut;
  final int intensity; // 0–3
  final bool isStreakDay;

  DateTime get dt => DateTime.parse(date);
  int get day => dt.day;
}

// ============================================================
// PAGE
// ============================================================

class WorkoutCalendarPage extends StatefulWidget {
  const WorkoutCalendarPage({super.key});

  @override
  State<WorkoutCalendarPage> createState() => _WorkoutCalendarPageState();
}

class _WorkoutCalendarPageState extends State<WorkoutCalendarPage> {
  final _service = ProgressService();

  bool _loading = true;
  bool _error = false;

  Map<String, _CalDay> _dayMap = {};
  List<DateTime> _months = [];

  int _totalSessions = 0;
  double _totalVolume = 0;
  int _activeDays = 0;
  int _longestStreak = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final result = await _service.getCalendarData();
      _parseData(result);
    } catch (e) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _parseData(Map<String, dynamic> result) {
    // Support both {days: [...]} and direct array patterns
    List<dynamic> rawDays = [];
    if (result['days'] is List) {
      rawDays = result['days'] as List;
    } else if (result['data'] is List) {
      rawDays = result['data'] as List;
    } else {
      for (final v in result.values) {
        if (v is List) {
          rawDays = v;
          break;
        }
      }
    }

    final map = <String, _CalDay>{};
    int sessions = 0;
    double volume = 0;
    int active = 0;
    int runStreak = 0;
    int maxStreak = 0;

    for (final raw in rawDays) {
      final m = raw as Map<String, dynamic>;
      final day = _CalDay(
        date: m['date'] as String,
        volume: (m['volume'] as num? ?? 0).toDouble(),
        duration: (m['duration'] as num? ?? 0).toInt(),
        sessions: (m['sessions'] as num? ?? 0).toInt(),
        workedOut: m['workedOut'] as bool? ?? false,
        intensity: ((m['intensity'] as num? ?? 0).toInt()).clamp(0, 3),
        isStreakDay: m['isStreakDay'] as bool? ?? false,
      );
      map[day.date] = day;

      if (day.workedOut) {
        sessions += day.sessions;
        volume += day.volume;
        active++;
        runStreak++;
        if (runStreak > maxStreak) maxStreak = runStreak;
      } else {
        runStreak = 0;
      }
    }

    // Build ordered month list
    final months = <DateTime>[];
    if (map.isNotEmpty) {
      final sorted = map.keys.toList()..sort();
      final first = DateTime.parse(sorted.first);
      final last = DateTime.parse(sorted.last);
      var cur = DateTime(first.year, first.month, 1);
      final lastMonth = DateTime(last.year, last.month, 1);
      while (!cur.isAfter(lastMonth)) {
        months.add(cur);
        cur = DateTime(cur.year, cur.month + 1, 1);
      }
    }

    setState(() {
      _dayMap = map;
      _months = months;
      _totalSessions = sessions;
      _totalVolume = volume;
      _activeDays = active;
      _longestStreak = maxStreak;
      _loading = false;
    });
  }

  // ── build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Workout Calendar'),
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scheme.surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? _buildError(context)
              : _buildBody(context),
    );
  }

  Widget _buildError(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.warning,
              size: 52,
              color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Could not load calendar', style: tt.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Check your connection and try again',
              style: tt.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final volLabel = _totalVolume >= 1000
        ? '${(_totalVolume / 1000).toStringAsFixed(1)}k kg'
        : '${_totalVolume.toStringAsFixed(0)} kg';

    // Newest month first
    final reversed = _months.reversed.toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Stats + legend header
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, 0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsStrip(
                  totalSessions: _totalSessions,
                  activeDays: _activeDays,
                  volume: volLabel,
                  longestStreak: _longestStreak,
                ),
                const SizedBox(height: AppSpacing.sm),
                _IntensityLegend(),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),

        // Month cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm,
              ),
              child: _MonthCard(month: reversed[i], dayMap: _dayMap),
            ),
            childCount: reversed.length,
          ),
        ),

        const SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacing.xxl),
        ),
      ],
    );
  }
}

// ============================================================
// STATS STRIP
// ============================================================

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.totalSessions,
    required this.activeDays,
    required this.volume,
    required this.longestStreak,
  });

  final int totalSessions;
  final int activeDays;
  final String volume;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          icon: PhosphorIconsRegular.barbell,
          value: '$totalSessions',
          label: 'Sessions',
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatTile(
          icon: PhosphorIconsRegular.calendarCheck,
          value: '$activeDays',
          label: 'Active days',
          color: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatTile(
          icon: PhosphorIconsRegular.trendUp,
          value: volume,
          label: 'Total vol.',
          color: AppColors.positive,
        ),
        const SizedBox(width: AppSpacing.xs),
        _StatTile(
          icon: PhosphorIconsRegular.fire,
          value: '$longestStreak d',
          label: 'Best streak',
          color: AppColors.accent,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: AppBorders.boxCard(scheme),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value,
              style: tt.labelMedium?.copyWith(fontWeight: AppTypography.wBold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// INTENSITY LEGEND
// ============================================================

class _IntensityLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final items = [
      (
        scheme.onSurface.withValues(alpha: 0.10),
        'Rest',
      ),
      (AppColors.secondary.withValues(alpha: 0.30), 'Low'),
      (AppColors.secondary.withValues(alpha: 0.65), 'Medium'),
      (AppColors.secondary, 'High'),
    ];

    return Row(
      children: [
        Text(
          'Intensity',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        ...items.expand((item) => [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.$1,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                item.$2,
                style: tt.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ]),
      ],
    );
  }
}

// ============================================================
// MONTH CARD
// ============================================================

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.month, required this.dayMap});

  final DateTime month;
  final Map<String, _CalDay> dayMap;

  static const _dowLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static const _monthNames = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];

  String _key(int y, int m, int d) =>
      '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // weekday: 1=Mon..7=Sun → column index = weekday - 1
    final startOffset =
        DateTime(month.year, month.month, 1).weekday - 1;

    // Month-level stats
    int monthWorkouts = 0;
    int monthVolume = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final day = dayMap[_key(month.year, month.month, d)];
      if (day?.workedOut == true) {
        monthWorkouts++;
        monthVolume += day!.volume.toInt();
      }
    }
    final volLabel = monthVolume >= 1000
        ? '${(monthVolume / 1000).toStringAsFixed(1)}k kg'
        : '$monthVolume kg';

    // Build flat list: empty offsets + day cells
    final items = <_CellData>[];
    for (int i = 0; i < startOffset; i++) {
      items.add(const _CellData(dayNum: 0, day: null));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      items.add(_CellData(
        dayNum: d,
        day: dayMap[_key(month.year, month.month, d)],
      ));
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Month header ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_monthNames[month.month - 1]} ${month.year}',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ),
              if (monthWorkouts > 0) ...[
                _MonthChip(
                  icon: PhosphorIconsRegular.barbell,
                  label: '$monthWorkouts sessions',
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                _MonthChip(
                  icon: PhosphorIconsRegular.trendUp,
                  label: volLabel,
                  color: AppColors.primary,
                ),
              ] else
                _MonthChip(
                  icon: PhosphorIconsRegular.moon,
                  label: 'No workouts',
                  color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Day of week labels ────────────────────────────
          Row(
            children: _dowLabels
                .map(
                  (l) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        l,
                        textAlign: TextAlign.center,
                        style: tt.labelSmall?.copyWith(
                          color: scheme.onSurface
                              .withValues(alpha: AppOpacities.tertiary),
                          fontWeight: AppTypography.wMedium,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          // ── Day grid ──────────────────────────────────────
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            childAspectRatio: 1.0,
            children: items
                .map((cell) => _DayCell(cell: cell))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wSemibold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DAY CELL
// ============================================================

class _CellData {
  const _CellData({required this.dayNum, required this.day});
  final int dayNum; // 0 = empty
  final _CalDay? day;
  bool get isEmpty => dayNum == 0;
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.cell});

  final _CellData cell;

  Color _bg(BuildContext ctx) {
    if (cell.isEmpty) return Colors.transparent;
    final scheme = Theme.of(ctx).colorScheme;
    final d = cell.day;
    if (d == null || !d.workedOut) {
      return scheme.onSurface.withValues(alpha: 0.07);
    }
    return switch (d.intensity) {
      1 => AppColors.secondary.withValues(alpha: 0.28),
      2 => AppColors.secondary.withValues(alpha: 0.62),
      3 => AppColors.secondary,
      _ => scheme.onSurface.withValues(alpha: 0.07),
    };
  }

  Color _fg(BuildContext ctx) {
    final scheme = Theme.of(ctx).colorScheme;
    if (cell.isEmpty) return Colors.transparent;
    final d = cell.day;
    if (d == null || !d.workedOut || d.intensity < 2) {
      return scheme.onSurface.withValues(alpha: AppOpacities.secondary);
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    if (cell.isEmpty) return const SizedBox.shrink();

    final tt = Theme.of(context).textTheme;
    final hasData = cell.day != null;

    return GestureDetector(
      onTap: hasData ? () => _showSheet(context, cell.day!) : null,
      child: Container(
        decoration: BoxDecoration(
          color: _bg(context),
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        child: Stack(
          children: [
            // Day number
            Center(
              child: Text(
                '${cell.dayNum}',
                style: tt.labelSmall?.copyWith(
                  fontSize: 11,
                  color: _fg(context),
                  fontWeight: cell.day?.workedOut == true
                      ? AppTypography.wSemibold
                      : AppTypography.wRegular,
                ),
              ),
            ),

            // Streak indicator dot (bottom-right)
            if (cell.day?.isStreakDay == true)
              Positioned(
                bottom: 2,
                right: 3,
                child: Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (cell.day!.intensity >= 2)
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, _CalDay day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DayDetailSheet(day: day),
    );
  }
}

// ============================================================
// DAY DETAIL BOTTOM SHEET
// ============================================================

class _DayDetailSheet extends StatelessWidget {
  const _DayDetailSheet({required this.day});

  final _CalDay day;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _dayNames = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _intensityLabels = [
    'Rest day',
    'Light session',
    'Moderate session',
    'High intensity',
  ];

  Color _intensityColor(BuildContext ctx, int i) {
    return switch (i) {
      1 => AppColors.secondary.withValues(alpha: 0.6),
      2 => AppColors.secondary,
      3 => AppColors.primary,
      _ => Theme.of(ctx).colorScheme.onSurface.withValues(alpha: AppOpacities.tertiary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final dt = day.dt;
    final dateLabel =
        '${_dayNames[dt.weekday - 1]}, ${_monthNames[dt.month - 1]} ${dt.day}, ${dt.year}';
    final iColor = _intensityColor(context, day.intensity);

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
        AppSpacing.md + bottomPad,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Date row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: iColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          _intensityLabels[day.intensity.clamp(0, 3)],
                          style: tt.bodySmall?.copyWith(color: iColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (day.isStreakDay)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.fire,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        'Streak',
                        style: tt.labelSmall
                            ?.copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          Divider(
            height: 1,
            color: scheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Stats or rest
          if (!day.workedOut)
            _RestDayRow()
          else
            Row(
              children: [
                Expanded(
                  child: _SheetStat(
                    icon: PhosphorIconsRegular.barbell,
                    value: day.volume >= 1000
                        ? '${(day.volume / 1000).toStringAsFixed(1)}k kg'
                        : '${day.volume.toStringAsFixed(0)} kg',
                    label: 'Volume lifted',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _SheetStat(
                    icon: PhosphorIconsRegular.clock,
                    value: '${day.duration} min',
                    label: 'Duration',
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _SheetStat(
                    icon: PhosphorIconsRegular.arrowsClockwise,
                    value: '${day.sessions}',
                    label: 'Session${day.sessions == 1 ? '' : 's'}',
                    color: AppColors.positive,
                  ),
                ),
              ],
            ),

          // Intensity bar (only for workout days)
          if (day.workedOut) ...[
            const SizedBox(height: AppSpacing.sm),
            _IntensityBar(intensity: day.intensity),
          ],
        ],
      ),
    );
  }
}

class _RestDayRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.moon,
            size: 20,
            color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Rest & recovery day',
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetStat extends StatelessWidget {
  const _SheetStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wBold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _IntensityBar extends StatelessWidget {
  const _IntensityBar({required this.intensity});

  final int intensity; // 1–3

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final labels = ['', 'Low', 'Medium', 'High'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intensity · ${labels[intensity.clamp(1, 3)]}',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          children: List.generate(3, (i) {
            final filled = (i + 1) <= intensity;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                height: 6,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.secondary
                      : scheme.onSurface.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}