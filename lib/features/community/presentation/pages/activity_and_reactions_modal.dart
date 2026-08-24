// ActivityAndReactionsModal.dart
// showDialog(context: context, builder: (_) => const ActivityAndReactionsModal());

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';


class ActivityAndReactionsModal extends StatelessWidget {
  const ActivityAndReactionsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxH = MediaQuery.of(context).size.height * 0.90;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420).copyWith(maxHeight: maxH),
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
            color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                boxShadow: AppShadows.e1(scheme),
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

/* -------------------- Content -------------------- */

class _ModalCard extends StatelessWidget {
  const _ModalCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
final isLight = Theme.of(context).brightness == Brightness.light;


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
            // Close
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  PhosphorIconsRegular.x,
                  size: 24,
                  color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                ),
              ),
            ),

            // Header: avatar + name + streak chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(initials: 'SM', scheme: scheme),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alex Chen', style: tt.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      _ChipPill(
                        scheme: scheme,
                        leading: Icon(
                          PhosphorIconsRegular.fireSimple,
                          size: 24,
                          color: AppColors.accent,
                        ),
                        label: '12 Day Streak',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            _Divider(scheme: scheme),
            const SizedBox(height: AppSpacing.md),

            // Completed workout card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: AppBorders.boxCard(scheme),
                boxShadow: AppShadows.e1(scheme),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceVariant,
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.trendUp,
                      size: 24,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completed Push Day',
                            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Duration: 20 min',
                          style: tt.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Reward earned callout
            _RewardCallout(
              scheme: scheme,
              leading: Icon(PhosphorIconsRegular.medal, size: 24, color: scheme.secondary),
              titleTop: 'REWARD EARNED',
              titleMain: '🥇 4X BUILDER BADGE',
            ),

            const SizedBox(height: AppSpacing.md),
            _Divider(scheme: scheme),
            const SizedBox(height: AppSpacing.md),

            // React section (inline)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('REACT', style: tt.titleSmall),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _ReactionBubble(emoji: '🔥', selected: true, onTap: () {}),
                const SizedBox(width: AppSpacing.xs),
                _ReactionBubble(emoji: '👏', onTap: () {}),
                const SizedBox(width: AppSpacing.xs),
                _ReactionBubble(emoji: '🙌', onTap: () {}),
                const SizedBox(width: AppSpacing.xs),
                _ReactionBubble(emoji: '💯', onTap: () {}),
                const Spacer(),
                Text(
                  '18',
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Actions
            Row(
              children: [
                Expanded(
                  child: _PrimaryButton(
                    label: 'Follow',
                    icon: PhosphorIconsRegular.userPlus,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _OutlineButton(
                    label: 'View Profile',
                    onPressed: () {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Footer helper
            Row(
              children: [
                Icon(
                  PhosphorIconsRegular.chatCircle,
                  size: 24,
                  color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Share encouragement (coming soon)',
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- Helpers -------------------- */

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.scheme});

  final String initials;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
final isLight = Theme.of(context).brightness == Brightness.light;


    return Container(
      width: 44, // 2 * radius
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
          border: Border.all(
      width: 2,
      color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
    ),
      ),
      
      alignment: Alignment.center,
      child: Text(
        initials,
        style: textTheme.labelLarge?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({required this.leading, required this.label, required this.scheme});

  final Widget leading;
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxs,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: AppBorders.boxCard(scheme),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color:AppColors.accent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(top: AppBorders.sideOnePx(scheme))),
    );
  }
}

class _RewardCallout extends StatelessWidget {
  const _RewardCallout({
    required this.scheme,
    required this.leading,
    required this.titleTop,
    required this.titleMain,
  });

  final ColorScheme scheme;
  final Widget leading;
  final String titleTop;
  final String titleMain;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(radius: 16, backgroundColor: scheme.surface, child: leading),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleTop,
                  style: tt.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  titleMain,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionBubble extends StatelessWidget {
  const _ReactionBubble({
    required this.emoji,
    this.selected = false,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.full),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? AppColors.accent.withValues(alpha: AppOpacities.secondary)
              : scheme.surface,
          border: selected
              ? Border.all(color: AppColors.accent, width: 2)
              : AppBorders.boxCard(scheme),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Text(emoji),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
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
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
final isLight = Theme.of(context).brightness == Brightness.light;

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isLight ? AppColors.neutralLight : AppColors.neutralDark,
          side: AppBorders.sideOnePx(scheme),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
