// EnvironmentCheckInModal.dart
// showDialog(context: context, builder: (_) => const EnvironmentCheckInModal());

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:go_router/go_router.dart';

class EnvironmentCheckInModal extends StatelessWidget {
  const EnvironmentCheckInModal({super.key});

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
            maxWidth: 420, // modalWidthOptional
            maxHeight: maxHeight,
          ),
          child: Material(
            color: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: const _ModalCard(),
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------------------------------------
   Modal card (scrollable content only)
   ---------------------------------------- */

class _ModalCard extends StatefulWidget {
  const _ModalCard();

  @override
  State<_ModalCard> createState() => _ModalCardState();
}

class _ModalCardState extends State<_ModalCard> {
  int? travelingIndex; // 0 = Yes, 1 = No
  final Set<String> equipment = {};
  int? daysIndex; // 0=2, 1=3, 2=4+

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
          bottom: AppSpacing.lg, // extra bottom padding
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close affordance
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  PhosphorIconsRegular.x,
                  size: 24,
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),
            ),

            // Heading + sub
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Quick Check-In 🌍', style: textTheme.headlineSmall),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Looks like your routine shifted. Help us keep your plan realistic.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            _SectionDivider(scheme: scheme),

            // Traveling section
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(
              icon: PhosphorIconsRegular.mapPin,
              title: 'Are you traveling this week?',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ChoiceChipCard(
                    label: 'Yes',
                    selected: travelingIndex == 0,
                    onTap: () => setState(() => travelingIndex = 0),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ChoiceChipCard(
                    label: 'No',
                    selected: travelingIndex == 1,
                    onTap: () => setState(() => travelingIndex = 1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            _SectionDivider(scheme: scheme),

            // Equipment section
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(
              icon: PhosphorIconsRegular.barbell,
              title: 'What equipment do you currently have?',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _TogglePill(
                  label: 'Bodyweight',
                  selected: equipment.contains('Bodyweight'),
                  onTap: () => setState(() {
                    equipment.toggle('Bodyweight');
                  }),
                ),
                _TogglePill(
                  label: 'Bands',
                  selected: equipment.contains('Bands'),
                  onTap: () => setState(() {
                    equipment.toggle('Bands');
                  }),
                ),
                _TogglePill(
                  label: 'Dumbbells',
                  selected: equipment.contains('Dumbbells'),
                  onTap: () => setState(() {
                    equipment.toggle('Dumbbells');
                  }),
                ),
                _TogglePill(
                  label: 'None',
                  selected: equipment.contains('None'),
                  onTap: () => setState(() {
                    // Make "None" mutually exclusive
                    if (equipment.contains('None')) {
                      equipment.remove('None');
                    } else {
                      equipment
                        ..clear()
                        ..add('None');
                    }
                  }),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            _SectionDivider(scheme: scheme),

            // Days per week section
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(
              icon: PhosphorIconsRegular.calendar,
              title: 'How many days feel doable this week?',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ChoiceChipCard(
                    label: '2',
                    selected: daysIndex == 0,
                    onTap: () => setState(() => daysIndex = 0),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ChoiceChipCard(
                    label: '3',
                    selected: daysIndex == 1,
                    onTap: () => setState(() => daysIndex = 1),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ChoiceChipCard(
                    label: '4+',
                    selected: daysIndex == 2,
                    onTap: () => setState(() => daysIndex = 2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Actions
            _PrimaryAction(
              scheme: scheme,
              label: 'Update My Plan',
              minHeight: 48,
              onPressed: () {
                context.push('/profile/environment-summary');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _SecondaryAction(
              scheme: scheme,
              label: 'Skip for now',
              minHeight: 48,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------
   Helpers
   ------------------------ */

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 24, color: scheme.secondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(title, style: textTheme.titleMedium)),
      ],
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
        border: Border(top: AppBorders.sideOnePx(scheme)),
      ),
    );
  }
}

class _ChoiceChipCard extends StatelessWidget {
  const _ChoiceChipCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;


    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? scheme.secondary.withValues(alpha: AppOpacities.secondary)
              : isLight ? AppColors.neutralLight : AppColors.neutralDark,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: selected
              ? Border.all(color: scheme.secondary, width: 2)
              : AppBorders.boxCard(scheme),
          boxShadow: AppShadows.e1(scheme),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: selected ? scheme.onSecondary : scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = scheme.brightness == Brightness.light;


    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          color: selected
              ? scheme.secondary.withValues(alpha: AppOpacities.secondary)
              : isLight ? AppColors.neutralLight : AppColors.neutralDark,
          border: selected
              ? Border.all(color: scheme.secondary, width: 2)
              : AppBorders.boxCard(scheme),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: selected ? scheme.onSecondary : scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final VoidCallback onPressed;
  final double minHeight;

  const _PrimaryAction({
    required this.scheme,
    required this.label,
    required this.onPressed,
    this.minHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge!.copyWith(color: AppColors.whiteUtility)),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final VoidCallback onPressed;
  final double minHeight;

  const _SecondaryAction({
    required this.scheme,
    required this.label,
    required this.onPressed,
    this.minHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: AppBorders.sideOnePx(scheme),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

/* ------------------------
   Small Set helper
   ------------------------ */

extension on Set<String> {
  void toggle(String value) {
    contains(value) ? remove(value) : add(value);
  }
}
