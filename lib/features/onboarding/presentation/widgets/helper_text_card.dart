import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class HelperTextCard extends StatelessWidget {
  final String text;
  final Color? color;

  const HelperTextCard({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.20)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: effectiveColor,
          fontWeight: AppTypography.wRegular,
        ),
      ),
    );
  }
}
