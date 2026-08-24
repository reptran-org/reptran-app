// ProgressTrackerPage.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/workout/presentation/pages/workout_calendar_page.dart';
import 'package:reptran_app/features/workout/services/progress_service.dart';

class ProgressTrackerPage extends StatefulWidget {
  const ProgressTrackerPage({super.key});

  @override
  State<ProgressTrackerPage> createState() => _ProgressTrackerPageState();
}

class _ProgressTrackerPageState extends State<ProgressTrackerPage> {
  final _service = ProgressService();

  bool _loading = true;
  Map<String, dynamic>? _data;
  int _selectedTab = 0;

  static const _tabLabels = ['Volume', 'Duration', 'Intensity', 'Frequency'];
  static const _tabKeys = [
    'volumeTrend',
    'durationTrend',
    'intensityTrend',
    'frequencyTrend',
  ];
  static const _tabUnits = ['kg', 'min', 'kg / rep', 'sessions'];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      final result = await _service.getAnalytics(range: '7d');
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<_ChartPoint> _getChartPoints() {
    if (_data == null) return [];
    final charts = _data!['charts'] as Map<String, dynamic>? ?? {};
    final raw = charts[_tabKeys[_selectedTab]] as List<dynamic>? ?? [];
    return raw.map((e) {
      final m = e as Map<String, dynamic>;
      return _ChartPoint(
        date: m['date'] as String,
        value: (m['value'] as num).toDouble(),
      );
    }).toList();
  }

  Map<String, dynamic> get _summary =>
      (_data!['summary'] as Map<String, dynamic>? ?? {});
  Map<String, dynamic> get _weekly =>
      (_summary['weekly'] as Map<String, dynamic>? ?? {});
  Map<String, dynamic> get _consistency =>
      (_data!['consistency'] as Map<String, dynamic>? ?? {});
  Map<String, dynamic> get _recovery =>
      (_data!['recovery'] as Map<String, dynamic>? ?? {});
  Map<String, dynamic> get _trends =>
      (_data!['trends'] as Map<String, dynamic>? ?? {});
  Map<String, dynamic> get _density =>
      (_data!['density'] as Map<String, dynamic>? ?? {});
  List<String> get _insights =>
      ((_data!['insights'] as List<dynamic>?) ?? []).cast<String>();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? _EmptyState()
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final weekDone = _weekly['done'] as int? ?? 0;
    final weekTarget = _weekly['target'] as int? ?? 0;
    final weekPercent =
        ((_weekly['percent'] as num? ?? 0) / 100).clamp(0.0, 1.0).toDouble();
    final streak = _summary['streak'] as int? ?? 0;
    final totalSessions = _summary['totalSessions'] as int? ?? 0;
    final activeDays = _consistency['activeDays'] as int? ?? 0;
    final adherenceRate =
        (_consistency['adherenceRate'] as num? ?? 0).toDouble();
    final longestGap = _recovery['longestGap'] as int? ?? 0;
    final avgGap = (_recovery['avgGap'] as num? ?? 0).toDouble();
    final volumePerDay = (_density['volumePerDay'] as num? ?? 0).toDouble();
    final chartPoints = _getChartPoints();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroHeader(
                  weekDone: weekDone,
                  weekTarget: weekTarget,
                  weekPercent: weekPercent,
                  streak: streak,
                  totalSessions: totalSessions,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _QuickStatsRow(
                        activeDays: activeDays,
                        adherenceRate: adherenceRate,
                        volumePerDay: volumePerDay,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ChartCard(
                        tabs: _tabLabels,
                        selectedTab: _selectedTab,
                        unit: _tabUnits[_selectedTab],
                        points: chartPoints,
                        lineColor: AppColors.secondary,
                        onTabChanged: (i) =>
                            setState(() => _selectedTab = i),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionLabel(label: 'Trends'),
                      const SizedBox(height: AppSpacing.xs),
                      _TrendsRow(trends: _trends),
                      const SizedBox(height: AppSpacing.md),
                      _SectionLabel(label: 'Recovery'),
                      const SizedBox(height: AppSpacing.xs),
                      _RecoveryCard(longestGap: longestGap, avgGap: avgGap),
                      const SizedBox(height: AppSpacing.md),
                      if (_insights.isNotEmpty) ...[
                        _SectionLabel(label: 'Insights 💡'),
                        const SizedBox(height: AppSpacing.xs),
                        ..._insights.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: _InsightCard(text: s),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      // ── View Calendar CTA ──────────────────────────
                      _CalendarButton(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HERO HEADER
// ============================================================

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.weekDone,
    required this.weekTarget,
    required this.weekPercent,
    required this.streak,
    required this.totalSessions,
  });

  final int weekDone;
  final int weekTarget;
  final double weekPercent;
  final int streak;
  final int totalSessions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: AppShadows.e2(scheme),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm, AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress 📈',
            style: tt.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.wBold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Your last 7 days at a glance',
            style: tt.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _WeeklyRing(
                done: weekDone,
                target: weekTarget,
                percent: weekPercent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$weekDone / $weekTarget',
                      style: tt.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                    Text(
                      'sessions this week',
                      style: tt.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        _HeroBadge(
                          icon: PhosphorIconsRegular.fire,
                          label: '$streak day streak',
                          borderColor: AppColors.accent,
                          iconColor: AppColors.accent,
                        ),
                        _HeroBadge(
                          icon: PhosphorIconsRegular.barbell,
                          label: '$totalSessions total sessions',
                          borderColor: AppColors.secondary,
                          iconColor: AppColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyRing extends StatelessWidget {
  const _WeeklyRing({
    required this.done,
    required this.target,
    required this.percent,
  });
  final int done;
  final int target;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      width: 88,
      height: 88,
      child: CustomPaint(
        painter: _RingPainter(
          percent: percent,
          baseColor: Colors.white.withValues(alpha: 0.18),
          progressColor: AppColors.secondary,
          strokeWidth: 7,
        ),
        child: Center(
          child: Text(
            '${(percent * 100).toInt()}%',
            style: tt.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.wBold,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.percent,
    required this.baseColor,
    required this.progressColor,
    required this.strokeWidth,
  });
  final double percent;
  final Color baseColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - strokeWidth / 2;
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = baseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent || old.progressColor != progressColor;
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.borderColor,
    required this.iconColor,
  });
  final IconData icon;
  final String label;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs, vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: borderColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: AppSpacing.xxs),
          Text(label,
              style: tt.labelSmall?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK STATS ROW
// ============================================================

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.activeDays,
    required this.adherenceRate,
    required this.volumePerDay,
  });
  final int activeDays;
  final double adherenceRate;
  final double volumePerDay;

  @override
  Widget build(BuildContext context) {
    final vLabel = volumePerDay >= 1000
        ? '${(volumePerDay / 1000).toStringAsFixed(1)}k kg'
        : '${volumePerDay.toStringAsFixed(0)} kg';
    return Row(
      children: [
        _QuickStatTile(
          icon: PhosphorIconsRegular.calendarCheck,
          value: '$activeDays',
          label: 'Active days',
          color: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        _QuickStatTile(
          icon: PhosphorIconsRegular.percent,
          value: '${(adherenceRate * 100).toInt()}%',
          label: 'Adherence',
          color: AppColors.positive,
        ),
        const SizedBox(width: AppSpacing.xs),
        _QuickStatTile(
          icon: PhosphorIconsRegular.barbell,
          value: vLabel,
          label: 'Daily avg vol.',
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _QuickStatTile extends StatelessWidget {
  const _QuickStatTile({
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
          borderRadius: BorderRadius.circular(AppRadii.lg),
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
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: tt.titleSmall?.copyWith(fontWeight: AppTypography.wBold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
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
// CHART CARD
// ============================================================

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.tabs,
    required this.selectedTab,
    required this.unit,
    required this.points,
    required this.lineColor,
    required this.onTabChanged,
  });
  final List<String> tabs;
  final int selectedTab;
  final String unit;
  final List<_ChartPoint> points;
  final Color lineColor;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs, AppSpacing.xs, AppSpacing.xs, 0),
            child: _SegmentedControl(
              tabs: tabs,
              selected: selectedTab,
              onTap: onTabChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit,
                  style: tt.labelSmall?.copyWith(
                    color: scheme.onSurface
                        .withValues(alpha: AppOpacities.secondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 180,
                  child: points.isEmpty
                      ? Center(
                          child: Text(
                            'No data for this range',
                            style: tt.bodySmall?.copyWith(
                              color: scheme.onSurface
                                  .withValues(alpha: AppOpacities.tertiary),
                            ),
                          ),
                        )
                      : _AreaChart(points: points, lineColor: lineColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.tabs,
    required this.selected,
    required this.onTap,
  });
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: AppDurations.short,
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: active ? scheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  boxShadow: active ? AppShadows.e1(scheme) : null,
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(
                    color: active
                        ? AppColors.primary
                        : scheme.onSurface
                            .withValues(alpha: AppOpacities.secondary),
                    fontWeight: active
                        ? AppTypography.wSemibold
                        : AppTypography.wRegular,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================
// AREA CHART
// ============================================================

class _ChartPoint {
  const _ChartPoint({required this.date, required this.value});
  final String date;
  final double value;

  String get dayLabel {
    try {
      final p = date.split('-');
      final dt =
          DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      return days[dt.weekday - 1];
    } catch (_) {
      return '';
    }
  }
}

class _AreaChart extends StatelessWidget {
  const _AreaChart({required this.points, required this.lineColor});
  final List<_ChartPoint> points;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _AreaChartPainter(
        values: points.map((p) => p.value).toList(),
        labels: points.map((p) => p.dayLabel).toList(),
        lineColor: lineColor,
        gridColor: scheme.onSurface.withValues(alpha: 0.07),
        labelColor:
            scheme.onSurface.withValues(alpha: AppOpacities.secondary),
        dotFill: scheme.surface,
      ),
      size: Size.infinite,
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  _AreaChartPainter({
    required this.values,
    required this.labels,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
    required this.dotFill,
  });
  final List<double> values;
  final List<String> labels;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final Color dotFill;

  static const _xLabelH = 22.0;
  static const _yLabelW = 44.0;
  static const _topPad = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final chartRect = Rect.fromLTWH(
      _yLabelW, _topPad,
      size.width - _yLabelW,
      size.height - _xLabelH - _topPad,
    );
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final range = (maxV == minV) ? (maxV == 0 ? 1.0 : maxV) : maxV - minV;
    final effMin = minV == maxV ? 0.0 : minV;

    double toY(double v) =>
        chartRect.bottom - ((v - effMin) / range) * chartRect.height;
    double toX(int i) => values.length <= 1
        ? chartRect.center.dx
        : chartRect.left + i * (chartRect.width / (values.length - 1));

    // Grid + Y labels
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;
    for (int g = 0; g <= 4; g++) {
      final v = effMin + g * (range / 4);
      final y = toY(v);
      _dashLine(canvas, Offset(chartRect.left, y),
          Offset(chartRect.right, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: _fmt(v),
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: _yLabelW - 4);
      tp.paint(canvas,
          Offset(_yLabelW - tp.width - 4, y - tp.height / 2));
    }

    // Area + line
    final areaPath = Path();
    final linePath = Path();
    for (int i = 0; i < values.length; i++) {
      final x = toX(i);
      final y = toY(values[i]);
      if (i == 0) {
        areaPath.moveTo(x, chartRect.bottom);
        areaPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        final px = toX(i - 1);
        final py = toY(values[i - 1]);
        final cpx = (px + x) / 2;
        areaPath.cubicTo(cpx, py, cpx, y, x, y);
        linePath.cubicTo(cpx, py, cpx, y, x, y);
      }
      if (i == values.length - 1) {
        areaPath.lineTo(x, chartRect.bottom);
        areaPath.close();
      }
    }
    final shaderRect =
        Rect.fromLTWH(0, chartRect.top, size.width, chartRect.height);
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.22),
            lineColor.withValues(alpha: 0.02),
          ],
        ).createShader(shaderRect),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (int i = 0; i < values.length; i++) {
      final x = toX(i);
      final y = toY(values[i]);
      canvas.drawCircle(
          Offset(x, y), 5, Paint()..color = dotFill);
      canvas.drawCircle(
          Offset(x, y), 3.5, Paint()..color = lineColor);
    }
    for (int i = 0; i < labels.length; i++) {
      final x = toX(i);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: 10, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 40);
      tp.paint(canvas,
          Offset(x - tp.width / 2, chartRect.bottom + 6));
    }
  }

  static String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  static void _dashLine(Canvas c, Offset p1, Offset p2, Paint paint) {
    const dash = 4.0, gap = 4.0;
    final dir = p2 - p1;
    final len = dir.distance;
    if (len == 0) return;
    final unit = dir / len;
    double d = 0;
    while (d < len) {
      c.drawLine(
          p1 + unit * d, p1 + unit * math.min(d + dash, len), paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_AreaChartPainter old) =>
      old.values != values || old.lineColor != lineColor;
}

// ============================================================
// TRENDS ROW
// ============================================================

class _TrendsRow extends StatelessWidget {
  const _TrendsRow({required this.trends});
  final Map<String, dynamic> trends;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Volume', trends['volume'] as String? ?? '-'),
      ('Intensity', trends['intensity'] as String? ?? '-'),
      ('Consistency', trends['consistency'] as String? ?? '-'),
    ];
    return Row(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _TrendTile(
                label: entries[i].$1, value: entries[i].$2),
          ),
        ],
      ],
    );
  }
}

class _TrendTile extends StatelessWidget {
  const _TrendTile({required this.label, required this.value});
  final String label;
  final String value;

  Color _color(BuildContext ctx) {
    if (value == 'up' || value == 'good') return AppColors.positive;
    if (value == 'down') return AppColors.accent;
    return Theme.of(ctx)
        .colorScheme
        .onSurface
        .withValues(alpha: AppOpacities.tertiary);
  }

  IconData get _icon {
    if (value == 'up') return PhosphorIconsRegular.trendUp;
    if (value == 'down') return PhosphorIconsRegular.trendDown;
    return PhosphorIconsRegular.checkCircle;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.xxs),
          Text(label,
              style: tt.labelSmall?.copyWith(
                color: scheme.onSurface
                    .withValues(alpha: AppOpacities.secondary),
              )),
          Text(value,
              style: tt.bodySmall?.copyWith(
                color: color,
                fontWeight: AppTypography.wSemibold,
              ),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ============================================================
// RECOVERY CARD
// ============================================================

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.longestGap, required this.avgGap});
  final int longestGap;
  final double avgGap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recoveryColor =
        longestGap <= 1 ? AppColors.positive : AppColors.accent;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _RecoveryMetric(
                value: '${longestGap}d', label: 'Longest gap'),
            VerticalDivider(
              width: AppSpacing.lg,
              thickness: 1,
              color: scheme.outline.withValues(alpha: 0.5),
            ),
            _RecoveryMetric(
                value: '${avgGap.toStringAsFixed(1)}d', label: 'Avg rest'),
            VerticalDivider(
              width: AppSpacing.lg,
              thickness: 1,
              color: scheme.outline.withValues(alpha: 0.5),
            ),
            _RecoveryMetric(
              value: longestGap <= 1 ? 'Good' : 'Fair',
              label: 'Recovery',
              valueColor: recoveryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryMetric extends StatelessWidget {
  const _RecoveryMetric({
    required this.value,
    required this.label,
    this.valueColor,
  });
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: tt.titleLarge?.copyWith(
                color: valueColor ?? scheme.onSurface,
                fontWeight: AppTypography.wBold,
              )),
          const SizedBox(height: AppSpacing.xxs),
          Text(label,
              style: tt.labelSmall?.copyWith(
                color: scheme.onSurface
                    .withValues(alpha: AppOpacities.secondary),
              )),
        ],
      ),
    );
  }
}

// ============================================================
// INSIGHT CARD
// ============================================================

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(PhosphorIconsRegular.lightbulb,
                size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: tt.bodySmall, softWrap: true)),
        ],
      ),
    );
  }
}

// ============================================================
// VIEW CALENDAR BUTTON
// ============================================================

class _CalendarButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WorkoutCalendarPage()),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.e2(scheme),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                PhosphorIconsRegular.calendarBlank,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Calendar',
                    style: tt.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: AppTypography.wSemibold,
                    ),
                  ),
                  Text(
                    'See your last 6 months of workouts',
                    style: tt.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsRegular.arrowRight,
              size: 18,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SHARED HELPERS
// ============================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: Theme.of(context).textTheme.titleMedium);
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.chartBar,
              size: 52,
              color:
                  scheme.onSurface.withValues(alpha: AppOpacities.tertiary)),
          const SizedBox(height: AppSpacing.sm),
          Text('No analytics data yet', style: tt.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Complete a few workouts to see your progress',
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurface
                  .withValues(alpha: AppOpacities.tertiary),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}









// // ProgressTrackerPage.dart

// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:reptran_app/core/constants/tokens.dart';
// import 'package:reptran_app/features/workout/services/progress_service.dart';

// // ============================================================
// // PAGE
// // ============================================================

// class ProgressTrackerPage extends StatefulWidget {
//   const ProgressTrackerPage({super.key});

//   @override
//   State<ProgressTrackerPage> createState() => _ProgressTrackerPageState();
// }

// class _ProgressTrackerPageState extends State<ProgressTrackerPage> {
//   final _service = ProgressService();

//   bool _loading = true;
//   Map<String, dynamic>? _data;
//   int _selectedTab = 0;

//   static const _tabLabels = ['Volume', 'Duration', 'Intensity', 'Frequency'];
//   static const _tabKeys = [
//     'volumeTrend',
//     'durationTrend',
//     'intensityTrend',
//     'frequencyTrend',
//   ];
//   static const _tabUnits = ['kg', 'min', 'kg / rep', 'sessions'];

//   @override
//   void initState() {
//     super.initState();
//     _fetchAnalytics();
//   }

//   Future<void> _fetchAnalytics() async {
//     try {
//       final result = await _service.getAnalytics(range: '7d');
//       _service.getCalendarData();
//       setState(() {
//         _data = result;
//         _loading = false;
//       });
//     } catch (e) {
//       debugPrint('❌ Failed to fetch analytics: $e');
//       setState(() => _loading = false);
//     }
//   }

//   List<_ChartPoint> _getChartPoints() {
//     if (_data == null) return [];
//     final charts = _data!['charts'] as Map<String, dynamic>? ?? {};
//     final raw = charts[_tabKeys[_selectedTab]] as List<dynamic>? ?? [];
//     return raw.map((e) {
//       final m = e as Map<String, dynamic>;
//       return _ChartPoint(
//         date: m['date'] as String,
//         value: (m['value'] as num).toDouble(),
//       );
//     }).toList();
//   }

//   // ── helpers ──────────────────────────────────────────────

//   Map<String, dynamic> get _summary =>
//       (_data!['summary'] as Map<String, dynamic>? ?? {});
//   Map<String, dynamic> get _weekly =>
//       (_summary['weekly'] as Map<String, dynamic>? ?? {});
//   Map<String, dynamic> get _consistency =>
//       (_data!['consistency'] as Map<String, dynamic>? ?? {});
//   Map<String, dynamic> get _recovery =>
//       (_data!['recovery'] as Map<String, dynamic>? ?? {});
//   Map<String, dynamic> get _trends =>
//       (_data!['trends'] as Map<String, dynamic>? ?? {});
//   Map<String, dynamic> get _density =>
//       (_data!['density'] as Map<String, dynamic>? ?? {});
//   List<String> get _insights =>
//       ((_data!['insights'] as List<dynamic>?) ?? []).cast<String>();

//   // ── build ─────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     return Scaffold(
//       backgroundColor: scheme.surface,
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _data == null
//           ? _EmptyState()
//           : _buildBody(context),
//     );
//   }

//   Widget _buildBody(BuildContext context) {
//     final weekDone = _weekly['done'] as int? ?? 0;
//     final weekTarget = _weekly['target'] as int? ?? 0;
//     final weekPercent = ((_weekly['percent'] as num? ?? 0) / 100)
//         .clamp(0.0, 1.0)
//         .toDouble();
//     final streak = _summary['streak'] as int? ?? 0;
//     final totalSessions = _summary['totalSessions'] as int? ?? 0;
//     final activeDays = _consistency['activeDays'] as int? ?? 0;
//     final adherenceRate = (_consistency['adherenceRate'] as num? ?? 0)
//         .toDouble();
//     final longestGap = _recovery['longestGap'] as int? ?? 0;
//     final avgGap = (_recovery['avgGap'] as num? ?? 0).toDouble();
//     final volumePerDay = (_density['volumePerDay'] as num? ?? 0).toDouble();
//     final chartPoints = _getChartPoints();

//     return SafeArea(
//       child: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: Center(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 640),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // ── Hero ────────────────────────────────────────────────
//                 _HeroHeader(
//                   weekDone: weekDone,
//                   weekTarget: weekTarget,
//                   weekPercent: weekPercent,
//                   streak: streak,
//                   totalSessions: totalSessions,
//                 ),

//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: AppSpacing.sm,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: AppSpacing.sm),

//                       // ── Quick stats row ──────────────────────────────
//                       _QuickStatsRow(
//                         activeDays: activeDays,
//                         adherenceRate: adherenceRate,
//                         volumePerDay: volumePerDay,
//                       ),

//                       const SizedBox(height: AppSpacing.md),

//                       // ── Chart ────────────────────────────────────────
//                       _ChartCard(
//                         tabs: _tabLabels,
//                         selectedTab: _selectedTab,
//                         unit: _tabUnits[_selectedTab],
//                         points: chartPoints,
//                         lineColor: AppColors.secondary,
//                         onTabChanged: (i) => setState(() => _selectedTab = i),
//                       ),

//                       const SizedBox(height: AppSpacing.md),

//                       // ── Trends ───────────────────────────────────────
//                       _SectionLabel(label: 'Trends'),
//                       const SizedBox(height: AppSpacing.xs),
//                       _TrendsRow(trends: _trends),

//                       const SizedBox(height: AppSpacing.md),

//                       // ── Recovery ─────────────────────────────────────
//                       _SectionLabel(label: 'Recovery'),
//                       const SizedBox(height: AppSpacing.xs),
//                       _RecoveryCard(longestGap: longestGap, avgGap: avgGap),

//                       const SizedBox(height: AppSpacing.md),

//                       // ── Insights ─────────────────────────────────────
//                       if (_insights.isNotEmpty) ...[
//                         _SectionLabel(label: 'Insights 💡'),
//                         const SizedBox(height: AppSpacing.xs),
//                         ..._insights.map(
//                           (s) => Padding(
//                             padding: const EdgeInsets.only(
//                               bottom: AppSpacing.xs,
//                             ),
//                             child: _InsightCard(text: s),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: AppSpacing.xxl),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ============================================================
// // HERO HEADER
// // ============================================================

// class _HeroHeader extends StatelessWidget {
//   const _HeroHeader({
//     required this.weekDone,
//     required this.weekTarget,
//     required this.weekPercent,
//     required this.streak,
//     required this.totalSessions,
//   });

//   final int weekDone;
//   final int weekTarget;
//   final double weekPercent;
//   final int streak;
//   final int totalSessions;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;

//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: AppColors.primary,
//         boxShadow: AppShadows.e2(scheme),
//       ),
//       padding: const EdgeInsets.fromLTRB(
//         AppSpacing.sm,
//         AppSpacing.lg,
//         AppSpacing.sm,
//         AppSpacing.lg,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Progress 📈',
//             style: tt.headlineSmall?.copyWith(
//               color: Colors.white,
//               fontWeight: AppTypography.wBold,
//             ),
//           ),
//           const SizedBox(height: AppSpacing.xxs),
//           Text(
//             'Your last 7 days at a glance',
//             style: tt.bodySmall?.copyWith(
//               color: Colors.white.withValues(alpha: 0.65),
//             ),
//           ),
//           const SizedBox(height: AppSpacing.md),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               _WeeklyRing(
//                 done: weekDone,
//                 target: weekTarget,
//                 percent: weekPercent,
//               ),
//               const SizedBox(width: AppSpacing.sm),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '$weekDone / $weekTarget',
//                       style: tt.displaySmall?.copyWith(
//                         color: Colors.white,
//                         fontWeight: AppTypography.wBold,
//                       ),
//                     ),
//                     Text(
//                       'sessions this week',
//                       style: tt.bodySmall?.copyWith(
//                         color: Colors.white.withValues(alpha: 0.65),
//                       ),
//                     ),
//                     const SizedBox(height: AppSpacing.xs),
//                     Wrap(
//                       spacing: AppSpacing.xs,
//                       runSpacing: AppSpacing.xxs,
//                       children: [
//                         _HeroBadge(
//                           icon: PhosphorIconsRegular.fire,
//                           label: '$streak day streak',
//                           borderColor: AppColors.accent,
//                           iconColor: AppColors.accent,
//                         ),
//                         _HeroBadge(
//                           icon: PhosphorIconsRegular.barbell,
//                           label: '$totalSessions total sessions',
//                           borderColor: AppColors.secondary,
//                           iconColor: AppColors.secondary,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Ring ───────────────────────────────────────────────────────────────────

// class _WeeklyRing extends StatelessWidget {
//   const _WeeklyRing({
//     required this.done,
//     required this.target,
//     required this.percent,
//   });
//   final int done;
//   final int target;
//   final double percent;

//   @override
//   Widget build(BuildContext context) {
//     final tt = Theme.of(context).textTheme;
//     return SizedBox(
//       width: 88,
//       height: 88,
//       child: CustomPaint(
//         painter: _RingPainter(
//           percent: percent,
//           baseColor: Colors.white.withValues(alpha: 0.18),
//           progressColor: AppColors.secondary,
//           strokeWidth: 7,
//         ),
//         child: Center(
//           child: Text(
//             '${(percent * 100).toInt()}%',
//             style: tt.titleMedium?.copyWith(
//               color: Colors.white,
//               fontWeight: AppTypography.wBold,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _RingPainter extends CustomPainter {
//   const _RingPainter({
//     required this.percent,
//     required this.baseColor,
//     required this.progressColor,
//     required this.strokeWidth,
//   });
//   final double percent;
//   final Color baseColor;
//   final Color progressColor;
//   final double strokeWidth;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = (size.shortestSide / 2) - strokeWidth / 2;

//     canvas.drawCircle(
//       center,
//       radius,
//       Paint()
//         ..color = baseColor
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = strokeWidth,
//     );

//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       -math.pi / 2,
//       2 * math.pi * percent,
//       false,
//       Paint()
//         ..color = progressColor
//         ..style = PaintingStyle.stroke
//         ..strokeCap = StrokeCap.round
//         ..strokeWidth = strokeWidth,
//     );
//   }

//   @override
//   bool shouldRepaint(_RingPainter old) =>
//       old.percent != percent || old.progressColor != progressColor;
// }

// // ── Hero badge ─────────────────────────────────────────────────────────────

// class _HeroBadge extends StatelessWidget {
//   const _HeroBadge({
//     required this.icon,
//     required this.label,
//     required this.borderColor,
//     required this.iconColor,
//   });
//   final IconData icon;
//   final String label;
//   final Color borderColor;
//   final Color iconColor;

//   @override
//   Widget build(BuildContext context) {
//     final tt = Theme.of(context).textTheme;
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.xs,
//         vertical: AppSpacing.xxs,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.10),
//         borderRadius: BorderRadius.circular(AppRadii.full),
//         border: Border.all(
//           color: borderColor.withValues(alpha: 0.45),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: iconColor),
//           const SizedBox(width: AppSpacing.xxs),
//           Text(label, style: tt.labelSmall?.copyWith(color: Colors.white)),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================
// // QUICK STATS ROW
// // ============================================================

// class _QuickStatsRow extends StatelessWidget {
//   const _QuickStatsRow({
//     required this.activeDays,
//     required this.adherenceRate,
//     required this.volumePerDay,
//   });
//   final int activeDays;
//   final double adherenceRate;
//   final double volumePerDay;

//   @override
//   Widget build(BuildContext context) {
//     final vLabel = volumePerDay >= 1000
//         ? '${(volumePerDay / 1000).toStringAsFixed(1)}k kg'
//         : '${volumePerDay.toStringAsFixed(0)} kg';

//     return Row(
//       children: [
//         _QuickStatTile(
//           icon: PhosphorIconsRegular.calendarCheck,
//           value: '$activeDays',
//           label: 'Active days',
//           color: AppColors.secondary,
//         ),
//         const SizedBox(width: AppSpacing.xs),
//         _QuickStatTile(
//           icon: PhosphorIconsRegular.percent,
//           value: '${(adherenceRate * 100).toInt()}%',
//           label: 'Adherence',
//           color: AppColors.positive,
//         ),
//         const SizedBox(width: AppSpacing.xs),
//         _QuickStatTile(
//           icon: PhosphorIconsRegular.barbell,
//           value: vLabel,
//           label: 'Daily avg vol.',
//           color: AppColors.primary,
//         ),
//       ],
//     );
//   }
// }

// class _QuickStatTile extends StatelessWidget {
//   const _QuickStatTile({
//     required this.icon,
//     required this.value,
//     required this.label,
//     required this.color,
//   });
//   final IconData icon;
//   final String value;
//   final String label;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;

//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(AppSpacing.xs),
//         decoration: BoxDecoration(
//           color: scheme.surface,
//           borderRadius: BorderRadius.circular(AppRadii.lg),
//           border: AppBorders.boxCard(scheme),
//           boxShadow: AppShadows.e1(scheme),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(AppSpacing.xxs),
//               decoration: BoxDecoration(
//                 color: color.withValues(alpha: 0.12),
//                 borderRadius: BorderRadius.circular(AppRadii.sm),
//               ),
//               child: Icon(icon, size: 16, color: color),
//             ),
//             const SizedBox(height: AppSpacing.xs),
//             Text(
//               value,
//               style: tt.titleSmall?.copyWith(fontWeight: AppTypography.wBold),
//               overflow: TextOverflow.ellipsis,
//             ),
//             Text(
//               label,
//               style: tt.labelSmall?.copyWith(
//                 color: scheme.onSurface.withValues(
//                   alpha: AppOpacities.secondary,
//                 ),
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ============================================================
// // CHART CARD
// // ============================================================

// class _ChartCard extends StatelessWidget {
//   const _ChartCard({
//     required this.tabs,
//     required this.selectedTab,
//     required this.unit,
//     required this.points,
//     required this.lineColor,
//     required this.onTabChanged,
//   });
//   final List<String> tabs;
//   final int selectedTab;
//   final String unit;
//   final List<_ChartPoint> points;
//   final Color lineColor;
//   final ValueChanged<int> onTabChanged;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;

//     return Container(
//       decoration: BoxDecoration(
//         color: scheme.surface,
//         borderRadius: BorderRadius.circular(AppRadii.lg),
//         border: AppBorders.boxCard(scheme),
//         boxShadow: AppShadows.e1(scheme),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Tabs
//           Padding(
//             padding: const EdgeInsets.fromLTRB(
//               AppSpacing.xs,
//               AppSpacing.xs,
//               AppSpacing.xs,
//               0,
//             ),
//             child: _SegmentedControl(
//               tabs: tabs,
//               selected: selectedTab,
//               onTap: onTabChanged,
//             ),
//           ),
//           // Chart area
//           Padding(
//             padding: const EdgeInsets.fromLTRB(
//               AppSpacing.sm,
//               AppSpacing.sm,
//               AppSpacing.sm,
//               AppSpacing.sm,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   unit,
//                   style: tt.labelSmall?.copyWith(
//                     color: scheme.onSurface.withValues(
//                       alpha: AppOpacities.secondary,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: AppSpacing.xs),
//                 SizedBox(
//                   height: 180,
//                   child: points.isEmpty
//                       ? Center(
//                           child: Text(
//                             'No data for this range',
//                             style: tt.bodySmall?.copyWith(
//                               color: scheme.onSurface.withValues(
//                                 alpha: AppOpacities.tertiary,
//                               ),
//                             ),
//                           ),
//                         )
//                       : _AreaChart(points: points, lineColor: lineColor),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Segmented control ─────────────────────────────────────────────────────

// class _SegmentedControl extends StatelessWidget {
//   const _SegmentedControl({
//     required this.tabs,
//     required this.selected,
//     required this.onTap,
//   });
//   final List<String> tabs;
//   final int selected;
//   final ValueChanged<int> onTap;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;

//     return Container(
//       decoration: BoxDecoration(
//         color: scheme.onSurface.withValues(alpha: 0.06),
//         borderRadius: BorderRadius.circular(AppRadii.sm),
//       ),
//       padding: const EdgeInsets.all(3),
//       child: Row(
//         children: List.generate(tabs.length, (i) {
//           final active = i == selected;
//           return Expanded(
//             child: GestureDetector(
//               onTap: () => onTap(i),
//               child: AnimatedContainer(
//                 duration: AppDurations.short,
//                 curve: Curves.easeInOut,
//                 padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
//                 decoration: BoxDecoration(
//                   color: active ? scheme.surface : Colors.transparent,
//                   borderRadius: BorderRadius.circular(AppRadii.xs),
//                   boxShadow: active ? AppShadows.e1(scheme) : null,
//                 ),
//                 child: Text(
//                   tabs[i],
//                   textAlign: TextAlign.center,
//                   overflow: TextOverflow.ellipsis,
//                   style: tt.labelSmall?.copyWith(
//                     color: active
//                         ? AppColors.primary
//                         : scheme.onSurface.withValues(
//                             alpha: AppOpacities.secondary,
//                           ),
//                     fontWeight: active
//                         ? AppTypography.wSemibold
//                         : AppTypography.wRegular,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }

// // ============================================================
// // AREA CHART
// // ============================================================

// class _ChartPoint {
//   const _ChartPoint({required this.date, required this.value});
//   final String date;
//   final double value;

//   String get dayLabel {
//     try {
//       final p = date.split('-');
//       final dt = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
//       const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
//       return days[dt.weekday - 1];
//     } catch (_) {
//       return '';
//     }
//   }
// }

// class _AreaChart extends StatelessWidget {
//   const _AreaChart({required this.points, required this.lineColor});
//   final List<_ChartPoint> points;
//   final Color lineColor;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     return CustomPaint(
//       painter: _AreaChartPainter(
//         values: points.map((p) => p.value).toList(),
//         labels: points.map((p) => p.dayLabel).toList(),
//         lineColor: lineColor,
//         gridColor: scheme.onSurface.withValues(alpha: 0.07),
//         labelColor: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
//         dotFill: scheme.surface,
//       ),
//       size: Size.infinite,
//     );
//   }
// }

// class _AreaChartPainter extends CustomPainter {
//   _AreaChartPainter({
//     required this.values,
//     required this.labels,
//     required this.lineColor,
//     required this.gridColor,
//     required this.labelColor,
//     required this.dotFill,
//   });
//   final List<double> values;
//   final List<String> labels;
//   final Color lineColor;
//   final Color gridColor;
//   final Color labelColor;
//   final Color dotFill;

//   static const _xLabelH = 22.0;
//   static const _yLabelW = 44.0;
//   static const _topPad = 8.0;

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (values.isEmpty) return;

//     final chartRect = Rect.fromLTWH(
//       _yLabelW,
//       _topPad,
//       size.width - _yLabelW,
//       size.height - _xLabelH - _topPad,
//     );

//     final maxV = values.reduce(math.max);
//     final minV = values.reduce(math.min);
//     // Give zero-only series a sensible range
//     final range = (maxV == minV) ? (maxV == 0 ? 1.0 : maxV) : maxV - minV;
//     final effectiveMin = minV == maxV ? 0.0 : minV;

//     double toY(double v) =>
//         chartRect.bottom - ((v - effectiveMin) / range) * chartRect.height;

//     double toX(int i) => values.length <= 1
//         ? chartRect.center.dx
//         : chartRect.left + i * (chartRect.width / (values.length - 1));

//     // ── Grid + Y labels ────────────────────────────────────
//     final gridPaint = Paint()
//       ..color = gridColor
//       ..strokeWidth = 1;

//     const gridCount = 4;
//     for (int g = 0; g <= gridCount; g++) {
//       final v = effectiveMin + g * (range / gridCount);
//       final y = toY(v);
//       _dashLine(
//         canvas,
//         Offset(chartRect.left, y),
//         Offset(chartRect.right, y),
//         gridPaint,
//       );

//       final tp = TextPainter(
//         text: TextSpan(
//           text: _fmt(v),
//           style: TextStyle(fontSize: 10, color: labelColor),
//         ),
//         textDirection: TextDirection.ltr,
//         textAlign: TextAlign.right,
//       )..layout(maxWidth: _yLabelW - 4);
//       tp.paint(canvas, Offset(_yLabelW - tp.width - 4, y - tp.height / 2));
//     }

//     // ── Area fill ──────────────────────────────────────────
//     final areaPath = Path();
//     final linePath = Path();

//     for (int i = 0; i < values.length; i++) {
//       final x = toX(i);
//       final y = toY(values[i]);

//       if (i == 0) {
//         areaPath.moveTo(x, chartRect.bottom);
//         areaPath.lineTo(x, y);
//         linePath.moveTo(x, y);
//       } else {
//         final px = toX(i - 1);
//         final py = toY(values[i - 1]);
//         final cpx = (px + x) / 2;
//         areaPath.cubicTo(cpx, py, cpx, y, x, y);
//         linePath.cubicTo(cpx, py, cpx, y, x, y);
//       }
//       if (i == values.length - 1) {
//         areaPath.lineTo(x, chartRect.bottom);
//         areaPath.close();
//       }
//     }

//     // Gradient fill using a shader rect
//     final shaderRect = Rect.fromLTWH(
//       0,
//       chartRect.top,
//       size.width,
//       chartRect.height,
//     );
//     canvas.drawPath(
//       areaPath,
//       Paint()
//         ..shader = LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             lineColor.withValues(alpha: 0.22),
//             lineColor.withValues(alpha: 0.02),
//           ],
//         ).createShader(shaderRect),
//     );

//     // ── Line ──────────────────────────────────────────────
//     canvas.drawPath(
//       linePath,
//       Paint()
//         ..color = lineColor
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2.5
//         ..strokeCap = StrokeCap.round
//         ..strokeJoin = StrokeJoin.round,
//     );

//     // ── Dots ──────────────────────────────────────────────
//     for (int i = 0; i < values.length; i++) {
//       final x = toX(i);
//       final y = toY(values[i]);
//       // White ring
//       canvas.drawCircle(
//         Offset(x, y),
//         5,
//         Paint()
//           ..color = dotFill
//           ..style = PaintingStyle.fill,
//       );
//       // Coloured fill
//       canvas.drawCircle(
//         Offset(x, y),
//         3.5,
//         Paint()
//           ..color = lineColor
//           ..style = PaintingStyle.fill,
//       );
//     }

//     // ── X labels ──────────────────────────────────────────
//     for (int i = 0; i < labels.length; i++) {
//       final x = toX(i);
//       final tp = TextPainter(
//         text: TextSpan(
//           text: labels[i],
//           style: TextStyle(fontSize: 10, color: labelColor),
//         ),
//         textDirection: TextDirection.ltr,
//         textAlign: TextAlign.center,
//       )..layout(maxWidth: 40);
//       tp.paint(canvas, Offset(x - tp.width / 2, chartRect.bottom + 6));
//     }
//   }

//   static String _fmt(double v) {
//     if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
//     if (v == v.truncateToDouble()) return v.toInt().toString();
//     return v.toStringAsFixed(1);
//   }

//   static void _dashLine(Canvas c, Offset p1, Offset p2, Paint paint) {
//     const dash = 4.0, gap = 4.0;
//     final dir = p2 - p1;
//     final len = dir.distance;
//     if (len == 0) return;
//     final unit = dir / len;
//     double d = 0;
//     while (d < len) {
//       c.drawLine(p1 + unit * d, p1 + unit * math.min(d + dash, len), paint);
//       d += dash + gap;
//     }
//   }

//   @override
//   bool shouldRepaint(_AreaChartPainter old) =>
//       old.values != values || old.lineColor != lineColor;
// }

// // ============================================================
// // TRENDS ROW
// // ============================================================

// class _TrendsRow extends StatelessWidget {
//   const _TrendsRow({required this.trends});
//   final Map<String, dynamic> trends;

//   @override
//   Widget build(BuildContext context) {
//     final entries = [
//       ('Volume', trends['volume'] as String? ?? '-'),
//       ('Intensity', trends['intensity'] as String? ?? '-'),
//       ('Consistency', trends['consistency'] as String? ?? '-'),
//     ];
//     return Row(
//       children: entries.indexed.map((e) {
//         final i = e.$1;
//         final label = e.$2.$1;
//         final value = e.$2.$2;
//         return Expanded(
//           child: Padding(
//             padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.xs),
//             child: _TrendTile(label: label, value: value),
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// class _TrendTile extends StatelessWidget {
//   const _TrendTile({required this.label, required this.value});
//   final String label;
//   final String value;

//   Color _color(BuildContext ctx) {
//     if (value == 'up' || value == 'good') return AppColors.positive;
//     if (value == 'down') return AppColors.accent;
//     return Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.4);
//   }

//   IconData get _icon {
//     if (value == 'up') return PhosphorIconsRegular.trendUp;
//     if (value == 'down') return PhosphorIconsRegular.trendDown;
//     return PhosphorIconsRegular.checkCircle;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;
//     final color = _color(context);

//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.xs),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.08),
//         borderRadius: BorderRadius.circular(AppRadii.md),
//         border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(_icon, size: 18, color: color),
//           const SizedBox(height: AppSpacing.xxs),
//           Text(
//             label,
//             style: tt.labelSmall?.copyWith(
//               color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
//             ),
//           ),
//           Text(
//             value,
//             style: tt.bodySmall?.copyWith(
//               color: color,
//               fontWeight: AppTypography.wSemibold,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================
// // RECOVERY CARD
// // ============================================================

// class _RecoveryCard extends StatelessWidget {
//   const _RecoveryCard({required this.longestGap, required this.avgGap});
//   final int longestGap;
//   final double avgGap;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final recoveryColor = longestGap <= 1
//         ? AppColors.positive
//         : AppColors.accent;
//     final recoveryLabel = longestGap <= 1 ? 'Good' : 'Fair';

//     return Container(
//       decoration: BoxDecoration(
//         color: scheme.surface,
//         borderRadius: BorderRadius.circular(AppRadii.lg),
//         border: AppBorders.boxCard(scheme),
//         boxShadow: AppShadows.e1(scheme),
//       ),
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.md,
//         vertical: AppSpacing.sm,
//       ),
//       child: IntrinsicHeight(
//         child: Row(
//           children: [
//             _RecoveryMetric(value: '${longestGap}d', label: 'Longest gap'),
//             VerticalDivider(
//               width: AppSpacing.lg,
//               thickness: 1,
//               color: scheme.outline.withValues(alpha: 0.5),
//             ),
//             _RecoveryMetric(
//               value: '${avgGap.toStringAsFixed(1)}d',
//               label: 'Avg rest',
//             ),
//             VerticalDivider(
//               width: AppSpacing.lg,
//               thickness: 1,
//               color: scheme.outline.withValues(alpha: 0.5),
//             ),
//             _RecoveryMetric(
//               value: recoveryLabel,
//               label: 'Recovery',
//               valueColor: recoveryColor,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _RecoveryMetric extends StatelessWidget {
//   const _RecoveryMetric({
//     required this.value,
//     required this.label,
//     this.valueColor,
//   });
//   final String value;
//   final String label;
//   final Color? valueColor;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;

//     return Expanded(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             value,
//             style: tt.titleLarge?.copyWith(
//               color: valueColor ?? scheme.onSurface,
//               fontWeight: AppTypography.wBold,
//             ),
//           ),
//           const SizedBox(height: AppSpacing.xxs),
//           Text(
//             label,
//             style: tt.labelSmall?.copyWith(
//               color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================
// // INSIGHT CARD
// // ============================================================

// class _InsightCard extends StatelessWidget {
//   const _InsightCard({required this.text});
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;

//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.secondary.withValues(alpha: 0.07),
//         borderRadius: BorderRadius.circular(AppRadii.md),
//         border: Border.all(
//           color: AppColors.secondary.withValues(alpha: 0.25),
//           width: 1,
//         ),
//       ),
//       padding: const EdgeInsets.all(AppSpacing.sm),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(top: 1),
//             child: Icon(
//               PhosphorIconsRegular.lightbulb,
//               size: 18,
//               color: AppColors.secondary,
//             ),
//           ),
//           const SizedBox(width: AppSpacing.xs),
//           Expanded(child: Text(text, style: tt.bodySmall, softWrap: true)),
//         ],
//       ),
//     );
//   }
// }

// // ============================================================
// // SHARED HELPERS
// // ============================================================

// class _SectionLabel extends StatelessWidget {
//   const _SectionLabel({required this.label});
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Text(label, style: Theme.of(context).textTheme.titleMedium);
//   }
// }

// class _EmptyState extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final tt = Theme.of(context).textTheme;
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             PhosphorIconsRegular.chartBar,
//             size: 52,
//             color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           Text(
//             'No analytics data yet',
//             style: tt.bodyMedium?.copyWith(
//               color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
//             ),
//           ),
//           const SizedBox(height: AppSpacing.xs),
//           Text(
//             'Complete a few workouts to see your progress',
//             style: tt.bodySmall?.copyWith(
//               color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }
