// ContextAdjustConfirmModal.dart
// showDialog(context: context, builder: (_) => const ContextAdjustConfirmModal());

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';


class ContextAdjustConfirmModal extends StatelessWidget {
  const ContextAdjustConfirmModal({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420, // modalWidthOptional: 420
            maxHeight: maxHeight,
          ),
          child: Material(
  color: Colors.transparent,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.lg),
  ),
  child: Container(
    decoration: BoxDecoration(
      color: scheme.surface, // <- move color here
      borderRadius: BorderRadius.circular(AppRadii.lg),
      boxShadow: AppShadows.e1(scheme),
      border: AppBorders.boxCard(scheme),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: const _ModalCard(),
    ),
  ),
),
        ),
      ),
    );
  }
}

/* ----------------------------------------
   Modal content
   ---------------------------------------- */

class _ModalCard extends StatelessWidget {
  const _ModalCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          top: AppSpacing.sm,
          bottom: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close (top-right)
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  PhosphorIconsRegular.x,
                  size: 24,
                  color:
                      scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                ),
              ),
            ),

            // Heading + subtitle
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Update Your Plan?', style: textTheme.headlineSmall),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "We noticed your context changed. Here's our new suggestion.",
                style: textTheme.bodyMedium?.copyWith(
                  color:
                      scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Divider
            _SectionDivider(scheme: scheme),

            const SizedBox(height: AppSpacing.md),

            // Differences table card
            _DiffTableCard(),

            const SizedBox(height: AppSpacing.md),

            // Info callout
            _InfoCallout(),

            const SizedBox(height: AppSpacing.md),

            // Divider
            _SectionDivider(scheme: scheme),

            const SizedBox(height: AppSpacing.md),

            // Actions
            _PrimaryAction(
              label: 'Confirm Adjustments',
              icon: PhosphorIconsRegular.checkCircle,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SecondaryAction(
              label: 'Keep Current Plan',
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------------------
   Pieces
   ---------------------------------------- */

class _DiffTableCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;


Widget row({
  required String label,
  required String oldVal,
  required String newVal,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      vertical: AppSpacing.sm,
      horizontal: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      border: Border(
        top: AppBorders.sideOnePx(scheme),
      ),
    ),
    child:Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    // Label - now narrower, but allowed to wrap naturally
    Flexible(
      flex: 1, // was 2, now labels take less width
      child: Text(
        label,
        style: textTheme.bodyMedium,
        softWrap: true,
        maxLines: 2,
      ),
    ),

    const SizedBox(width: AppSpacing.sm),

    // Old chip
    Flexible(
      flex: 1,
      child: _Chip(
        label: oldVal,
        tone: _ChipTone.neutral,
      ),
    ),

    const SizedBox(width: AppSpacing.xs),

    Icon(
      PhosphorIconsRegular.arrowRight,
      size: 20,
      color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
    ),

    const SizedBox(width: AppSpacing.xs),

    // New chip
    Flexible(
      flex: 1,
      child: _Chip(
        label: newVal,
        tone: _ChipTone.accent,
      ),
    ),
  ],
),
  );
}

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: Column(
        children: [
          // Header row (Old/New)
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadii.lg),
                topRight: Radius.circular(AppRadii.lg),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(),
                ),
                Expanded(
                  child: Text(
                    'Old',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface
                          .withValues(alpha: AppOpacities.secondary),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.xs), // spacer before arrow
                Expanded(
                  child: Text(
                    'New',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface
                          .withValues(alpha: AppOpacities.secondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          row(
            label: 'Weekly Target',
            oldVal: '4 sessions',
            newVal: '2 sessions',
          ),
          row(
            label: 'Equipment',
            oldVal: 'Gym',
            newVal: 'Bodyweight',
          ),
          row(
            label: 'Preferred Time',
            oldVal: 'Morning',
            newVal: 'Evening',
          ),
        ],
      ),
    );
  }
}

enum _ChipTone { neutral, accent }

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.tone,
  });

  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAccent = tone == _ChipTone.accent;
    final isLight = scheme.brightness == Brightness.light;


    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,     // ↓ smaller vertical
        horizontal: AppSpacing.xs,   // ↓ smaller horizontal
      ),
      decoration: BoxDecoration(
        color: isAccent
            ? scheme.secondary.withValues(alpha: 0.10)
            : isLight ? AppColors.neutralLight : AppColors.neutralDark,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: AppBorders.boxCard(scheme),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isAccent ? scheme.secondary : scheme.onSurface.withValues(alpha: AppOpacities.secondary),
        ),
      ),
    );
  }
}

class _InfoCallout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.positive
            .withValues(alpha: 0.10), // gentle success tint
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIconsRegular.checkCircle,
            size: 24,
            color: AppColors.positive,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'These adjustments will make your plan more realistic and sustainable for your current situation.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface
                    .withValues(alpha: AppOpacities.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: AppBorders.sideOnePx(scheme),
        ),
      ),
    );
  }
}

/* ----------------------------------------
   Actions
   ---------------------------------------- */

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          elevation: 0,
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
              style: Theme.of(context).textTheme.labelLarge!.copyWith(color: AppColors.whiteUtility),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: AppBorders.sideOnePx(scheme),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.secondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
