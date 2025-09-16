import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class LocationOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final bool isActive;
  final VoidCallback onTap;

  const LocationOptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.08)
              : (scheme.brightness == Brightness.light
                    ? AppColors.neutralLight
                    : AppColors.neutralDark),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isActive ? scheme.primary : scheme.outline,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isActive ? scheme.primary : scheme.onSurface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isActive
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.outline.withValues(alpha: 0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
