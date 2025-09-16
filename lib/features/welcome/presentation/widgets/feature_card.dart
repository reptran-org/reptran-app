import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final int index;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.label,
    required this.bg,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final card = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: AppTypography.wSemibold,
              ),
            ),
          ),
        ],
      ),
    );

    return card
        .animate(delay: (100 * index).ms)
        .fadeIn(duration: AppDurations.medium)
        .slideY(
          begin: 0.1,
          curve: Curves.easeOut,
          duration: AppDurations.medium,
        );
  }
}
