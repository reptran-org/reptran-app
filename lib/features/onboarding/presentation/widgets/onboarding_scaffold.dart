import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class OnboardingScaffold extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle; // optional override
  final bool titleGradient; // draw gradient on title when true

  const OnboardingScaffold({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xxl,
    ),
    this.titleStyle,
    this.titleGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final baseTitleStyle =
        titleStyle ??
        Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: AppTypography.wBold,
          height: AppTypography.lhNormal,
        );

    Widget titleWidget = Text(
      title,
      textAlign: TextAlign.center,
      style: baseTitleStyle,
    );

    if (titleGradient) {
      titleWidget = ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: (baseTitleStyle ?? const TextStyle()).copyWith(
            color: Colors.white,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                icon,
                const SizedBox(height: AppSpacing.md),
                titleWidget,
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                      fontWeight: AppTypography.wRegular,
                      height: AppTypography.lhNormal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
