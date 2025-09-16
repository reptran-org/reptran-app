import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class FutureSelfCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const FutureSelfCard({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outline,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.wSemibold,
            ),
          ),
        ),
      ),
    );
  }
}
