import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class IdentityCheckInPage extends StatelessWidget {
  const IdentityCheckInPage({super.key});

  // NOTE: Static page — no state, no interactions. Values are tokenized/text only.

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              // firstSectionHasBg == false -> apply horizontal padding here
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top & bottom framing must be present
                  const SizedBox(height: AppSpacing.xxl),

                  // Heading + Subheading (includeHeadingSubheading == true)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Identity Check-In',
                          style: textTheme.headlineSmall?.copyWith(
                            color: isLight
                                ? scheme.primary
                                : textTheme.headlineSmall?.color,
                            height: 1.2,
                            fontWeight: AppTypography.wBold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Let's see if your identity still fits your current rhythm.",
                          style: textTheme.bodyMedium?.copyWith(
                            color: textTheme.bodyMedium?.color?.withValues(
                              alpha: AppOpacities.secondary,
                            ),
                            height: 1.2,
                            fontWeight: AppTypography.wMedium,
                          ),
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 1) Identity summary card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primary, scheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      boxShadow: AppShadows.e1(scheme),
                      border: AppBorders.boxCard(scheme),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm, // left
                      AppSpacing.sm + AppSpacing.md, // top = sm + md
                      AppSpacing.sm, // right
                      AppSpacing.sm + AppSpacing.md, // bottom = sm + md
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.sparkle,
                          size: 40,
                          color: AppColors.whiteUtility,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'I am the type of person who trains 4x/week.',
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.whiteUtility,
                            height: 1.2,
                            fontWeight: AppTypography.wBold,
                          ),
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Sub-card as before...
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.whiteUtility.withOpacity(
                              AppOpacities.disabled,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            // border: AppBorders.boxCard(scheme),
                            boxShadow: AppShadows.e1(scheme),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Consistency This Month',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppColors.whiteUtility,
                                        height: 1.2,
                                        fontWeight: AppTypography.wSemibold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '85%',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.whiteUtility,
                                      height: 1.2,
                                      fontWeight: AppTypography.wSemibold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                                child: Container(
                                  height: AppSpacing.xs,
                                  width: double.infinity,
                                  color: AppColors.neutralLight,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor:
                                          0.85, // static visual fill (85%)
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.positive,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.md,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 2) Suggestion / action card
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge + title + description
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.positive,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.full,
                                ),
                              ),
                              child: const Icon(
                                PhosphorIconsRegular.trendUp,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "You've been rock-solid. Want to evolve into the 5x Builder identity?",
                                    style: textTheme.titleMedium?.copyWith(
                                      color: isLight
                                          ? scheme.primary
                                          : scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    "You've hit your goal 3 weeks straight. Time to level up?",
                                    style: textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurface.withOpacity(
                                        AppOpacities.secondary,
                                      ),
                                      height: 1.2,
                                      fontWeight: AppTypography.wMedium,
                                    ),
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // CTA Buttons (Primary + Outline) stacked
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Primary
                            Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              decoration: BoxDecoration(
                                color: scheme.secondary,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                                boxShadow: AppShadows.button(scheme),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                  onTap: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        // 32x32 container with translucent white background
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.whiteUtility
                                                .withOpacity(
                                                  AppOpacities.disabled,
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.sm,
                                            ),
                                          ),
                                          child: const Icon(
                                            PhosphorIconsRegular.trendUp,
                                            size: 20,
                                            color: AppColors.whiteUtility,
                                          ),
                                        ),

                                        const SizedBox(width: AppSpacing.xs),

                                        // Text
                                        Text(
                                          'Yes, upgrade to 5x/week',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: scheme.onSecondary,
                                            fontWeight: AppTypography.wSemibold,
                                          ),
                                        ),

                                        const SizedBox(width: AppSpacing.xs),

                                        // Arrow icon
                                        const Icon(
                                          PhosphorIconsRegular.arrowRight,
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sm),

                            // Outline button
                            Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              decoration: BoxDecoration(
                                color: scheme.brightness == Brightness.light
                                    ? AppColors.neutralLight
                                    : scheme
                                          .surface, // keeps it visible in dark mode too
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                                border: AppBorders.boxOnePx(
                                  scheme,
                                ), // normal 1px border
                                boxShadow: AppShadows.e1(scheme),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                  onTap: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        // 32x32 outlined icon container
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: scheme.outline,
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.sm,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              PhosphorIconsRegular.spiral,
                                              size: 24,
                                              color: isLight
                                                  ? scheme.primary
                                                  : scheme.onSurface,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: AppSpacing.xs),

                                        // Button text (primary color)
                                        Text(
                                          'Keep it as is',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: isLight
                                                    ? scheme.primary
                                                    : scheme.onSurface,
                                                fontWeight:
                                                    AppTypography.wSemibold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Divider
                        Divider(color: scheme.outline),

                        const SizedBox(height: AppSpacing.md),

                        // Confidence row: label + score chip + slider representation (static)
                       

Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Title row: text wraps safely, score chip stays on right
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrap title safely
        Flexible(
          child: Text(
            'How confident do you feel about this change?',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: AppTypography.wSemibold,
              color: isLight ?  scheme.primary : scheme.onSurface,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Score chip
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.positive,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Text(
            '6/10',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSecondary,
              fontWeight: AppTypography.wSemibold,
            ),
          ),
        ),
      ],
    ),

    const SizedBox(height: AppSpacing.sm),

    // Confidence slider section
    Column(
      children: [
        // Gradient progress bar + knob
// inside your Stack (slider section)
Stack(
  clipBehavior: Clip.none, // 🔹 allows knob to overflow above bar
  alignment: Alignment.centerLeft,
  children: [
    // Gradient progress bar (background)
    ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        height: 12.0, // token-allowed literal
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.accent,
              AppColors.positive,
            ],
          ),
        ),
      ),
    ),

    // True floating knob
    Positioned(
      top: -6, // 🔹 lifts knob so the ring sits fully visible above bar
      left: MediaQuery.of(context).size.width * 0.6 - 12, // center at 60%
      child: CustomPaint(
        painter: _GradientRingPainter(), // same painter from earlier
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.whiteUtility,
              shape: BoxShape.circle,
              boxShadow: AppShadows.e1(scheme),
            ),
          ),
        ),
      ),
    ),
  ],
),


        const SizedBox(height: AppSpacing.xs),

        // Labels below
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Uncertain',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withOpacity(AppOpacities.secondary),
                ),
                softWrap: true,
              ),
            ),
            Flexible(
              child: Text(
                'Very confident',
                textAlign: TextAlign.right,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withOpacity(AppOpacities.secondary),
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
),

                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Bottom actions (primary + outline side-by-side)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          decoration: BoxDecoration(
                            color: scheme.secondary,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            boxShadow: AppShadows.button(scheme),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Center(
                                  child: Text(
                                    'Confirm Update',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSecondary,
                                      fontWeight: AppTypography.wBold
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Center(
                                  child: Text(
                                    'Decide Later',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: isLight ? scheme.primary :  scheme.onSurface,
                                       fontWeight: AppTypography.wSemibold
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------
/// Private helpers
/// ---------------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: child,
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double percent;
  final ColorScheme scheme;
  final double? height;

  const _ProgressBar({
    Key? key,
    required this.percent,
    required this.scheme,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Height uses token default or provided value (no raw numeric except allowed)
    final barHeight = height ?? AppSpacing.sm / 2; // small thickness
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        height: barHeight,
        color: scheme.onSurface.withOpacity(AppOpacities.tertiary),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: percent.clamp(0.0, 1.0),
          child: Container(color: scheme.secondary),
        ),
      ),
    );
  }
}


class _GradientRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 2.0; // 2px gradient border
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Define gradient shader (accent → positive)
    final gradient = const SweepGradient(
      colors: [
        AppColors.accent,
        AppColors.positive,
      ],
      startAngle: 0.0,
      endAngle: 3.14 * 2,
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: size.center(Offset.zero), radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the gradient ring
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
