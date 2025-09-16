import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class ProgressPrefCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtext;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  const ProgressPrefCard({
    super.key,
    required this.icon,
    required this.label,
    required this.subtext,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        constraints: const BoxConstraints(minHeight: 108),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: 2,
          ),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: AppTypography.wSemibold,
                      height: AppTypography.lhNormal,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtext,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                      fontWeight: AppTypography.wSemibold,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary)
            else
              const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}
