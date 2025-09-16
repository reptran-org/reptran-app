import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class MotivationOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  const MotivationOptionCard({
    super.key,
    required this.icon,
    required this.label,
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
        constraints: const BoxConstraints(minHeight: 64),
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
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppTypography.wSemibold,
                  height: AppTypography.lhNormal,
                ),
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
