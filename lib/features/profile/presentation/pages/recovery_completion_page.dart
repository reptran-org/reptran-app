// RecoverCompletionScreen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';

/// RepTran — Recover Completion Screen
/// Matches the provided design using tokens & theme only.
class RecoverCompletionPage extends StatelessWidget {
  const RecoverCompletionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xxl,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Heading + Subheading
                    Text('Nice — You Came Back 🔥', style: textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "That's the move that builds identity.",
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Avatar
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.secondary.withValues(alpha: AppOpacities.secondary),
                              scheme.primary.withValues(alpha: AppOpacities.primary),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.e2(scheme),
                          border: Border.all(width: 2, color: AppColors.whiteUtility),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'A',
                          style: textTheme.displaySmall?.copyWith(
                            color: scheme.onSecondary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Completed card
                    _Card(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.positive.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              PhosphorIconsRegular.checkCircle,
                              size: 24,
                              color: AppColors.positive,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Completed', style: textTheme.titleMedium),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '10-min walk recovery',
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Badge unlocked card (positive outline)
Container(
  width: double.infinity, // <— add this
  padding: const EdgeInsets.all(AppSpacing.sm),
  decoration: BoxDecoration(
    color: scheme.surface,
    borderRadius: BorderRadius.circular(AppRadii.lg),
    border: Border.all(color: AppColors.positive, width: 1),
    boxShadow: AppShadows.e1(scheme),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // soft circle icon
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.positive.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          PhosphorIconsRegular.medalMilitary,
          size: 24,
          color: AppColors.positive,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Badge Unlocked',
        style: textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Bounce Back',
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.positive,
          fontWeight: AppTypography.wSemibold,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'You turned a setback into a comeback',
        style: textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    ],
  ),
),

                    const SizedBox(height: AppSpacing.lg),

                    // Primary CTA
                    _PrimaryButton(
                      label: 'Back to Home',
                      icon: PhosphorIconsRegular.house,
                      onPressed: () {},
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Outline CTA
                    _OutlineButton(
                      label: 'Plan next session',
                      icon: PhosphorIconsRegular.calendarBlank,
                      onPressed: () {},
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Footer notes
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Consistency isn't perfection.",
                            style: textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            "It's showing up again after you slip.",
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                            ),
                            textAlign: TextAlign.center,
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
      ),
    );
  }
}

/// Default tokenized card
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
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

/// Primary button (scheme.secondary), optional icon
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondary,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.button(scheme),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24, color: scheme.onSecondary),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    label,
                    style: textTheme.titleMedium?.copyWith(
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

/// Outline button with primary border
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: scheme.primary, width: 2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: scheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
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
