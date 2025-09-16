import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class WelcomeHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;

  const WelcomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.md + AppSpacing.sm,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            scheme.brightness == Brightness.dark
                ? 'assets/images/reptran_logo_white.png'
                : 'assets/images/reptran_logo.png',
            height: 80,
          ).animate().fadeIn(duration: AppDurations.medium),

          const SizedBox(height: AppSpacing.md),

          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: AppTypography.wBold,
              height: AppTypography.lhNormal,
            ),
          ).animate().fadeIn(duration: AppDurations.medium).slideY(begin: 0.1),

          const SizedBox(height: AppSpacing.xs),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.secondary,
              fontWeight: AppTypography.wSemibold,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: AppTypography.wRegular,
              height: AppTypography.lhNormal,
            ),
          ),
        ],
      ),
    );
  }
}
