import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

class IdentityPage extends StatelessWidget {
  const IdentityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
       final _isLight = scheme.brightness == Brightness.light;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            // ✅ Page-level horizontal and vertical padding
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxl,
              horizontal: AppSpacing.md,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Heading + Subheading ---
                    Text(
                      'My Fitness Identity',
                      style: textTheme.headlineSmall!.copyWith(
                        color: _isLight ? scheme.primary :  scheme.onSurface,
                        height: 1.2,
                        fontWeight: AppTypography.wBold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'This defines how RepTran supports your consistency.',
                      style: textTheme.bodyMedium!.copyWith(
                        height: 1.2,
                        fontWeight: AppTypography.wMedium,
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),

                      ),
                       textAlign: TextAlign.center,
                    ),

                    SizedBox(height: AppSpacing.md),

                    // --- Hero Card ---
                    _HeroCard(scheme: scheme, textTheme: textTheme),

                    SizedBox(height: AppSpacing.md),

                    // --- Identity Alignment Card ---
                    _Card(
                      scheme: scheme,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Title and value in one row ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Identity Alignment',
                                style: textTheme.titleMedium!.copyWith(
                                    color: _isLight ? scheme.primary :  scheme.onSurface,
                                ),
                              ),
                              Text(
                                '68%',
                                style: textTheme.bodyMedium!.copyWith(
                                  color: AppColors.positive,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: AppSpacing.md),

                          // --- Progress bar ---
                          _ProgressBar(
                            scheme: scheme,
                            percent: 0.68,
                            labelBuilder: (_) =>
                                const SizedBox.shrink(), // no label below bar
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppSpacing.md),

                    // --- Weekly Target Card ---
                    _Card(
                      scheme: scheme,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Weekly Target', style: textTheme.titleMedium),
                          SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _Segment(
                                label: '3x/week',
                                selected: false,
                                scheme: scheme,
                              ),
                              _Segment(
                                label: '4x/week',
                                selected: true,
                                scheme: scheme,
                              ),
                              _Segment(
                                label: '5x/week',
                                selected: false,
                                scheme: scheme,
                              ),
                            ],
                          ),

                          SizedBox(height: AppSpacing.lg),

                          // Confidence Level Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Title and Value in the same line ---
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Confidence Level',
                                    style: textTheme.titleMedium,
                                  ),
                                  Text(
                                    '7/10',
                                    style: textTheme.bodyMedium!.copyWith(
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: AppSpacing.md),

                              // --- Static slider ---
                              _StaticSlider(scheme: scheme, valueFraction: 0.7),

                              SizedBox(height: AppSpacing.xs),

                              // --- Low / High labels ---
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Low',
                                    style: textTheme.labelSmall!.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: AppOpacities.secondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'High',
                                    style: textTheme.labelSmall!.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: AppOpacities.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: AppSpacing.lg),
                          Text(
                            'Frictional Tags (optional)',
                            style: textTheme.titleMedium,
                          ),
                          SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: const [
                              _TagChip(label: 'Travel'),
                              _TagChip(label: 'Busy Work'),
                              _TagChip(label: 'Low Sleep'),
                              _TagChip(label: 'Motivation Dip'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppSpacing.md),

                    // --- Stats Row ---
                    // Inside your _Card child
                    _Card(
                      scheme: scheme,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceEvenly, // distribute centers evenly
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // vertical centering
                        children: [
                          _StatColumn(
                            icon: PhosphorIconsRegular.trendUp,
                            value: '5',
                            label: 'Day Streak',
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                          _StatColumn(
                            icon: PhosphorIconsRegular.medal,
                            value: '68',
                            label: 'Identity Score',
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                          _StatColumn(
                            icon: PhosphorIconsRegular.calendarBlank,
                            value: '3 days ago',
                            label: 'Last Updated',
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    // --- Buttons Row ---
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryButton(
                            label: 'Save Updates',
                            scheme: scheme,
                            textTheme: textTheme,
                            onPressed: () =>
                                context.push('/profile/identity-check-in'),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _OutlineButton(
                            label: 'Reset Identity',
                            scheme: scheme,
                            textTheme: textTheme,
                          ),
                        ),
                      ],
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

/* ---------------------------
   Small reusable components
   --------------------------- */

class _HeroCard extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _HeroCard({required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // ✅ 45° gradient background using theme tokens
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [scheme.primary, scheme.secondary],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.e1(scheme),
        border: AppBorders.boxCard(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.md),

          // ✅ Icon container (80x80, white @ 20%)
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsRegular.user,
                size: 40,
                color: scheme.onPrimary, // maintains contrast on gradient
              ),
            ),
          ),

          SizedBox(height: AppSpacing.sm),

          Center(
            child: Text(
              'I am the type of person who\ntrains 4x/week.',
              style: textTheme.headlineSmall!.copyWith(
                color: scheme.onPrimary,
                height: 1.2,
                fontWeight: AppTypography.wBold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final ColorScheme scheme;
  const _Card({required this.child, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _ProgressBar extends StatelessWidget {
  final ColorScheme scheme;
  final double percent;
  final Widget Function(BuildContext) labelBuilder;

  const _ProgressBar({
    required this.scheme,
    required this.percent,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 12,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.positive,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Align(alignment: Alignment.centerLeft, child: labelBuilder(context)),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme scheme;

  const _Segment({
    required this.label,
    required this.selected,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primaryContainer
            : (isLight ? AppColors.neutralLight : AppColors.neutralDark),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: AppBorders.boxCard(scheme),
      ),
      child: Text(
        label,
        style: textTheme.bodyMedium!.copyWith(
          color: selected
              ? scheme.onPrimaryContainer
              : scheme.onSurface.withValues(alpha: 0.60),
        ),
      ),
    );
  }
}

class _FakeSlider extends StatelessWidget {
  final double valueFraction;
  final ColorScheme scheme;

  const _FakeSlider({required this.valueFraction, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: AppSpacing.xs,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: scheme.onSurface.withOpacity(AppOpacities.secondary),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              FractionallySizedBox(
                widthFactor: valueFraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: AppBorders.boxCard(scheme),
      ),
      child: Text(
        label,
        style: textTheme.bodyMedium!.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.60),
        ),
      ),
    );
  }
}

// tokenized stat column
class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      mainAxisSize: MainAxisSize.min, // size to content
      crossAxisAlignment: CrossAxisAlignment.center, // center horizontally
      children: [
        Icon(icon, size: 24, color: AppColors.positive),
        SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: textTheme.titleMedium!.copyWith(
            color: isLight ? scheme.primary : scheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: textTheme.bodySmall!.copyWith(
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback? onPressed; // <-- add this

  const _PrimaryButton({
    required this.label,
    required this.scheme,
    required this.textTheme,
    this.onPressed, // <-- optional
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Material(
        color: Colors.transparent, // needed for InkWell ripple
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onPressed, // <-- handle click here
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.secondary ?? scheme.secondary,
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: AppShadows.button(scheme),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Center(
                child: Text(
                  label,
                  style: textTheme.bodyMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.wBold,
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

class _OutlineButton extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _OutlineButton({
    required this.label,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
     final isLight = scheme.brightness == Brightness.light;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
        border: isLight
      ? Border.all(
          color: scheme.primary,
          width: 1,
        )
      : AppBorders.boxOnePx(scheme),
        ),
        child: Center(
          child: Text(
            label,
            style: textTheme.bodyMedium!.copyWith(
              color: isLight ?  scheme.primary : scheme.onSurface,
              fontWeight: AppTypography.wBold,
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticSlider extends StatelessWidget {
  final double valueFraction;
  final ColorScheme scheme;

  const _StaticSlider({required this.valueFraction, required this.scheme});

  @override
  Widget build(BuildContext context) {
    const trackHeight = 8.0; // allowed literal for control size
    const thumbSize = 20.0; // allowed literal for control size

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final clamped = valueFraction.clamp(0.0, 1.0);
        final thumbLeft = (trackWidth - thumbSize) * clamped;

        return SizedBox(
          height: thumbSize, // gives room for the thumb; center = thumbSize / 2
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // --- Inactive track (centered vertically) ---
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: trackHeight,
                  width: trackWidth,
                  decoration: BoxDecoration(
                    color: scheme.outline,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),

              // --- Active track (centered vertically) ---
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: trackHeight,
                  width: trackWidth * clamped,
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),

              // --- Thumb (ball) placed at top: 0 so its center == container center ---
              Positioned(
                left: thumbLeft,
                top:
                    0, // <-- crucial: top = 0 centers the thumb vertically in SizedBox(height: thumbSize)
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: scheme.secondary, // visible color
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                    boxShadow: AppShadows.e1(scheme),
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
