// CommunityPulseScreen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class CommunityPulsePage extends StatelessWidget {
  const CommunityPulsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const _overlap = 130.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // firstSectionHasBg behavior: no horizontal padding at the page root
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======== HEADER (gradient) + OVERLAP CARD via Stack ========
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Gradient header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xxl,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [scheme.primary, scheme.secondary],
                          ),
                          boxShadow: AppShadows.e2(scheme),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.globe,
                                  size: 24,
                                  color: scheme.onPrimary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    'Community Pulse 🌍',
                                    style: text.headlineSmall!.copyWith(
                                      color: scheme.onPrimary,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Real-time stats from Builders, Explorers,\nand Athletes across RepTran.',
                              style: text.bodyMedium!.copyWith(
                                color: scheme.onPrimary,
                              ),
                              softWrap: true,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ),

                      // Overlapping stat card
                      Positioned(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: -_overlap,
                        child: _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon badge
                              _IconBadge(
                                icon: PhosphorIconsRegular.pulse,
                                color: scheme.primary,
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              // Big number
                              Text('3,240', style: text.titleMedium),

                              const SizedBox(height: AppSpacing.xs),

                              // Label
                              Text(
                                'WORKOUTS LOGGED TODAY',
                                style: text.bodySmall,
                              ),

                              const SizedBox(height: AppSpacing.xs),

                              // Live dot + text (dot is not an icon)
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: scheme
                                          .secondary, // your "positive" color
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.full,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text('Live updates', style: text.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Space below the overlap card
                  const SizedBox(height: _overlap + AppSpacing.sm),

                  // ======== Rest of page (standard horizontal padding) ========
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // People bounced back
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon Badge
                              _IconBadge(
                                icon: PhosphorIconsRegular.heart,
                                color: AppColors.positive,
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              // Big number
                              Text('491', style: text.titleMedium),

                              const SizedBox(height: AppSpacing.xs),

                              // Label
                              Text(
                                'PEOPLE BOUNCED BACK THIS WEEK',
                                style: text.bodySmall,
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              // Chip
                              _SoftChip(
                                label: '+12% from last week',
                                fg: AppColors.positive,
                                bg: AppColors.positive.withValues(alpha: 0.20),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Active streaks
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon badge
                              _IconBadge(
                                icon: PhosphorIconsRegular.fireSimple,
                                color: AppColors.accent,
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              // Big number
                              Text('1,876', style: text.titleMedium),

                              const SizedBox(height: AppSpacing.xs),

                              // Label
                              Text('ACTIVE STREAKS', style: text.bodySmall),

                              const SizedBox(height: AppSpacing.sm),

                              // Extra info
                              Row(
                                children: [
                                  Icon(
                                    PhosphorIconsRegular.lightning,
                                    size: 16, // ← Smaller for secondary info
                                    color: scheme.tertiary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Longest: 127 days',
                                    style: text.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 7-Day Activity Trend
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                             Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Icon(
      PhosphorIconsRegular.chartBar,
      size: 24,
      color: scheme.primary,
    ),
    const SizedBox(width: AppSpacing.xs),

    // ⬇️ Both title + subtitle now align together
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Activity Trend',
            style: text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs / 2),
          Text(
            'Community workouts by day',
            style: text.bodySmall,
          ),
        ],
      ),
    ),
  ],
),

                              const SizedBox(height: AppSpacing.sm),
                              _SoftChip(
                                label: '↗  +8%  week-over-week',
                                fg: AppColors.positive,
                                bg: AppColors.positive.withValues(alpha: 0.20),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Better looking smooth sparkline using CustomPainter
                              SizedBox(
                                height: AppSpacing.xl + AppSpacing.md,
                                child: CustomPaint(
                                  painter: _TrendChartPainter(
                                    scheme: scheme,
                                    // Static datapoints Mon..Sun (0..1 normalized)
                                    points: const [
                                      0.20,
                                      0.32,
                                      0.28,
                                      0.55,
                                      0.40,
                                      0.48,
                                      0.85,
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('MON', style: text.bodySmall),
                                          Text('TUE', style: text.bodySmall),
                                          Text('WED', style: text.bodySmall),
                                          Text('THU', style: text.bodySmall),
                                          Text('FRI', style: text.bodySmall),
                                          Text('SAT', style: text.bodySmall),
                                          Text('SUN', style: text.bodySmall),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Note inside the card
                               _InsetNote(
        title: 'Community consistency improving —',
        subtitle:
            "Together, we’re building lasting habits and supporting each other's growth.",
      ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // CTA
                        _PrimaryButton(
                          label: 'View Leaderboards',
                          icon: PhosphorIconsRegular.users,
                          onPressed: () {},
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        Center(
                          child: Text(
                            'Coming soon — celebrate your progress\nalongside the community',
                            style: text.labelSmall,
                            textAlign: TextAlign.center,
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
      ),
    );
  }
}

/// ===================================================================
/// Building Blocks
/// ===================================================================

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: child,
    );
  }
}

class _SoftChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _SoftChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(label, style: text.bodySmall!.copyWith(color: fg)),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10), // 10% style opacity
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 24,
        color: color, // icon uses full color
      ),
    );
  }
}

// --- Inset note: now takes two texts with different colors
class _InsetNote extends StatelessWidget {
  final String title;
  final String subtitle;
  const _InsetNote({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  softWrap: true,
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final ColorScheme scheme;
  final List<double> points; // normalized 0..1

  _TrendChartPainter({required this.scheme, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()
      ..color = scheme.onSurface.withValues(alpha: AppOpacities.disabled)
      ..style = PaintingStyle.fill;

    // Background track (soft area)
    final areaPath = Path();
    final linePath = Path();

    // Padding inside the painter so labels at bottom won't overlap
    final leftPad = AppSpacing.sm;
    final rightPad = AppSpacing.sm;
    final topPad = AppSpacing.sm;
    final bottomPad = AppSpacing.xl;

    final w = size.width - leftPad - rightPad;
    final h = size.height - topPad - bottomPad;

    // Convert points to offsets
    final step = w / (points.length - 1);
    List<Offset> pts = [];
    for (int i = 0; i < points.length; i++) {
      final x = leftPad + step * i;
      final y = topPad + (1 - points[i]) * h;
      pts.add(Offset(x, y));
    }

    // Smooth curve via Catmull-Rom to Bezier
    if (pts.isEmpty) return;

    // Area path
    areaPath.moveTo(pts.first.dx, h + topPad);
    areaPath.lineTo(pts.first.dx, pts.first.dy);

    // Line path
    linePath.moveTo(pts.first.dx, pts.first.dy);

    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : pts[i + 1];

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
      areaPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    areaPath.lineTo(pts.last.dx, h + topPad);
    areaPath.close();

    // Draw area
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scheme.secondary.withValues(alpha: 0.25),
          scheme.secondary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    // Draw line
    final linePaint = Paint()
      ..color = scheme.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    // Draw points
    final dotPaint = Paint()..color = scheme.secondary;
    for (final o in pts) {
      canvas.drawCircle(o, 2, dotPaint);
    }

    // Bottom axis baseline
    final baseline = Paint()
      ..color = scheme.onSurface.withValues(alpha: AppOpacities.tertiary)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(leftPad, h + topPad),
      Offset(size.width - rightPad, h + topPad),
      baseline,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.scheme != scheme;
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: scheme.onSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: text.titleMedium!.copyWith(
                      color: scheme.onSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
