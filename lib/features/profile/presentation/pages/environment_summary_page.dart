// EnvironmentSummaryScreen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/profile/presentation/pages/context_adjustment_confirmation_modal.dart';

class EnvironmentSummaryPage extends StatelessWidget {
  const EnvironmentSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xxl,
            horizontal: AppSpacing.md,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading + Subheading
                Center(
  child: Text(
    'Current Environment',
    style: textTheme.headlineSmall,
    textAlign: TextAlign.center,
  ),
),

                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'RepTran adjusts to match your real-life conditions.',
                    style: textTheme.bodyMedium!.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ================= Main Environment Card =================
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: AppBorders.boxCard(scheme),
                      boxShadow: AppShadows.e1(scheme),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top accent bar
                        Container(
                          height: AppSpacing.xs,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(AppRadii.lg),
                              topRight: Radius.circular(AppRadii.lg),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Environment mode header row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: scheme.secondary.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.full,
                                      ),
                                    ),
                                    child: Icon(
                                      PhosphorIconsRegular.airplaneTilt,
                                      size: 24,
                                      color: scheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Traveling ✈️',
                                          style: textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Active mode',
                                          style: textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              // Equipment block
                              _EnvironmentBlock(
                                icon: PhosphorIconsRegular.barbell,
                                label: 'EQUIPMENT',
                                value: 'Bodyweight only',
                              ),
                              const SizedBox(height: AppSpacing.xs),

                              // Weekly target with small "Adjusted" chip
                              _EnvironmentBlock(
                                icon: PhosphorIconsRegular.target,
                                label: 'WEEKLY TARGET',
                                value: '2 Sessions/week',
                                trailing: _SoftChip(
                                  label: 'Adjusted',
                                  fg: AppColors.accent,
                                  bg: AppColors.accent.withValues(alpha: 0.10),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),

                              // Last audit
                              _EnvironmentBlock(
                                icon: PhosphorIconsRegular.calendarCheck,
                                label: 'LAST AUDIT',
                                value: '2 days ago',
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // Plan optimized notice
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.positive.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.lg,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      PhosphorIconsRegular.checkCircle,
                                      size: 24,
                                      color: AppColors.positive,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Plan optimized for your current environment',
                                        style: textTheme.bodySmall!.copyWith(
                                          color: AppColors.positive,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ================= Active Adjustments =================
                  Text('Active Adjustments', style: textTheme.titleMedium,textAlign: TextAlign.right,),
                  const SizedBox(height: AppSpacing.sm),

                  _AdjustmentCard(
                    leadingIcon: PhosphorIconsRegular.timer,
                    title: 'Workouts shortened',
                    subtitle: '20 min average',
                    statusLabel: 'Active',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _AdjustmentCard(
                    leadingIcon: PhosphorIconsRegular.personSimpleRun,
                    title: 'Bodyweight format',
                    subtitle: 'No equipment needed',
                    statusLabel: 'Active',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _AdjustmentCard(
                    leadingIcon: PhosphorIconsRegular.bell,
                    title: 'Reminder timing',
                    subtitle: 'Shifted to evenings',
                    statusLabel: 'Active',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Coach note
  _Card(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Vertical line (centered)
      Container(
        width: 4,
        height: 32, // tune this height as needed
        decoration: BoxDecoration(
          color: scheme.secondary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),

      Expanded(
        child: Text(
          "Coach’s Note: Your plan automatically adapts when life changes. No guilt, no pressure — just realistic expectations that keep you moving forward.",
          style: textTheme.bodySmall,
          softWrap: true,
        ),
      ),
    ],
  ),
),


                  const SizedBox(height: AppSpacing.md),

                  // Buttons
                  _PrimaryButton(
                    label: 'Run Environment Audit Again',
                    icon: PhosphorIconsRegular.repeat,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ContextAdjustConfirmModal(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _OutlineButton(
                    label: 'Return to Home',
                    icon: PhosphorIconsRegular.houseLine,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =====================
/// Building Blocks
/// =====================

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: child,
    );
  }
}

class _SoftChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _SoftChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: fg),
      ),
    );
  }
}

class _EnvironmentBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _EnvironmentBlock({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;


    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.neutralLight : AppColors.neutralDark,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
      
   Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: textTheme.bodySmall, softWrap: true),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(value, style: textTheme.bodyMedium, softWrap: true),
    ],
  ),
),

          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _AdjustmentCard extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final String statusLabel;

  const _AdjustmentCard({
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha:0.10),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Icon(leadingIcon, size: 24, color: scheme.secondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.positive.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              statusLabel,
              style: textTheme.bodySmall!.copyWith(color: AppColors.positive),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.button(scheme),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: scheme.onSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: textTheme.titleMedium!.copyWith(
                      color: scheme.onSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;


    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: AppBorders.boxCard(scheme),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24,  color: isLight ?   scheme.primary : scheme.onSurface,),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: textTheme.titleMedium!.copyWith(
                      color: isLight ?   scheme.primary : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
