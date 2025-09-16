import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? iconColor;

  const OptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.iconColor,
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
            width: selected ? 2 : 1,
          ),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),

            const SizedBox(width: AppSpacing.xs),
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
              Icon(Icons.check_circle, color: scheme.primary)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
