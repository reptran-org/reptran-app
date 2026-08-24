import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';


class BadgeModal extends StatelessWidget {
  const BadgeModal({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420, // modalWidthOptional set to 420
            maxHeight: maxHeight,
          ),
          child: _ModalCard(
            scheme: scheme,
            textTheme: textTheme,
          ),
        ),
      ),
    );
  }
}

/* -----------------------------
   Internal pieces (private)
   ----------------------------- */

class _ModalCard extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _ModalCard({
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    // Card surface tokens: background: scheme.surface, radius: AppRadii.lg, padding: AppSpacing.sm
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // ensure card does not exceed viewport
            maxHeight: maxHeight,
          ),
          child: SingleChildScrollView(
            // hero is placed first (full-bleed). All remaining content is wrapped with horizontal AppSpacing.sm
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HERO HEADER (full-bleed inside card)
                _HeroHeader(
                  scheme: scheme,
                  textTheme: textTheme,
                ),

                // All content after hero has horizontal padding = AppSpacing.sm
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    top: AppSpacing.md,     // space between hero and body
                    bottom: AppSpacing.lg,  // large bottom padding for modal
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Spotlight trophy circle
                      _Spotlight(scheme: scheme),
                      SizedBox(height: AppSpacing.xl),

                      // What this badge means (heading + body)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'What This Badge Means',
                          style: textTheme.titleMedium,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        "Earned by completing 4 workouts per week for 3 consecutive weeks. You're building the foundation of lasting change—consistency is your superpower.",
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),

                      // Progress row with metric + progress bar
                      _ProgressRow(
                        scheme: scheme,
                        textTheme: textTheme,
                        progressLabel: 'Your Progress',
                        progressMetricLabel: '12/15 sessions',
                        progressFraction: 12 / 15,
                      ),
                      SizedBox(height: AppSpacing.md),

                      // Next badge small info card
                      _SmallInfoCard(scheme: scheme, textTheme: textTheme),
                      SizedBox(height: AppSpacing.md),

                      // Primary and secondary actions stacked
                      _ActionButton(
                        scheme: scheme,
                        label: 'Close',
                        minHeight: 48,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      _OutlineButton(
                        scheme: scheme,
                        label: 'See All Badges',
                        minHeight: 48,
                        onPressed: () {
                          // Caller handles navigation; placeholder
                          Navigator.of(context).pop();
                        },
                      ),

                      SizedBox(height: AppSpacing.md),

                      // Footer note card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: scheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: AppBorders.boxCard(scheme),
                        ),
                        child: Text(
                          "Every badge you earn is proof of who you're becoming—not just what you've done.",
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                          ),
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
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _HeroHeader({
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.sm,
        right: AppSpacing.sm,
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top-right close icon
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              PhosphorIconsRegular.x,
              size: 24,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Centered title
          Text(
            '4x Week Builder Badge',
            style: textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Centered subtitle
          Text(
            'Proof of your consistent commitment.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Spotlight extends StatelessWidget {
  final ColorScheme scheme;

  const _Spotlight({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight, // 90° gradient
        ),
        border: Border.all(
          width: 2,
          color:  AppColors.whiteUtility ,
        ),
        boxShadow: AppShadows.e3(scheme),
      ),
      child: Center(
        child: Icon(
          PhosphorIconsRegular.trophy,
          size: 40,
          color: AppColors.whiteUtility,
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  final String progressLabel;
  final String progressMetricLabel;
  final double progressFraction;

  const _ProgressRow({
    required this.scheme,
    required this.textTheme,
    required this.progressLabel,
    required this.progressMetricLabel,
    required this.progressFraction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + metric row
        Row(
          children: [
            Expanded(
              child: Text(
                progressLabel,
                style: textTheme.bodyMedium,
              ),
            ),
            Text(
              progressMetricLabel,
              style: textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Progress bar (full width)
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.full),
          child: Container(
            width: double.infinity,
            height: AppSpacing.sm,
            color: scheme.outline, // background track
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressFraction.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.secondary, // fill color
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          'Just ${( (1 - progressFraction) * 3 ).ceil()} more sessions to unlock this badge!',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
        ),
      ],
    );
  }
}

class _SmallInfoCard extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _SmallInfoCard({
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: AppBorders.boxCard(scheme),
      ),
      child: Row(
        children: [
          // Medal circle
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surface,
              boxShadow: AppShadows.e1(scheme),
              border: Border.all(color: scheme.outline),
            ),
            child: Icon(
              PhosphorIconsRegular.medal,
              size: 24,
              color: scheme.onSurface,
            ),
          ),

          SizedBox(width: AppSpacing.sm),

          // Text column: first row contains trendUp icon + tiny gap + "Next Badge"
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row with small trendUp icon + small gap (AppSpacing.xs used for "xxs")
                Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.trendUp,
                      
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      'Next Badge',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppSpacing.xs),

                Text(
                  '5x Builder Tier',
                  style: textTheme.bodyMedium,
                ),

                SizedBox(height: AppSpacing.xs),

                Text(
                  '5 workouts/week for 4 weeks',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
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

class _ActionButton extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final VoidCallback onPressed;
  final double minHeight;

  const _ActionButton({
    required this.scheme,
    required this.label,
    required this.onPressed,
    this.minHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          // elevation: AppShadows.button(scheme),
        ),
        onPressed: onPressed,
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.whiteUtility)),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final VoidCallback onPressed;
  final double minHeight;

  const _OutlineButton({
    required this.scheme,
    required this.label,
    required this.onPressed,
    this.minHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
        final bool isLight = Theme.of(context).brightness == Brightness.light;
    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: AppBorders.sideOnePx(scheme),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        onPressed: onPressed,
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: isLight ? scheme.primary : scheme.onSurface)),
      ),
    );
  }
}
