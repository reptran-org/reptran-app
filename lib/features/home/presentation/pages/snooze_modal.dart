import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class SnoozeModal extends StatelessWidget {
  const SnoozeModal({super.key});

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
            maxWidth: 420,
            maxHeight: maxHeight,
          ),
          child: Material(
            color: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _SnoozeContent(
                    scheme: scheme,
                    textTheme: textTheme,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* --------------------------- */

class _SnoozeContent extends StatefulWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _SnoozeContent({
    required this.scheme,
    required this.textTheme,
  });

  @override
  State<_SnoozeContent> createState() => _SnoozeContentState();
}

class _SnoozeContentState extends State<_SnoozeContent> {
  int? _selectedIndex;

  void _select(int idx) => setState(() => _selectedIndex = idx);

void _confirm() {
  if (_selectedIndex == null) {
    return;
  }

  Navigator.of(context).pop(_selectedIndex);
}


  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final textTheme = widget.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
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

        SizedBox(height: AppSpacing.xs),

        Text(
          'Need more time?',
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'No worries — choose what works for you.',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(
              alpha: AppOpacities.secondary,
            ),
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: AppSpacing.md),

        Column(
          children: [
            _OptionCard(
              scheme: scheme,
              selected: _selectedIndex == 0,
              onTap: () => _select(0),
              leading: Icon(
                PhosphorIconsRegular.clock,
                size: 24,
                color: scheme.primary,
              ),
              title: 'Remind me in 2 hours',
            ),
            SizedBox(height: AppSpacing.sm),
            _OptionCard(
              scheme: scheme,
              selected: _selectedIndex == 1,
              onTap: () => _select(1),
              leading: Icon(
                PhosphorIconsRegular.lightning,
                size: 24,
                color: scheme.primary,
              ),
              title: '10-min express session',
            ),
            SizedBox(height: AppSpacing.sm),
            _OptionCard(
              scheme: scheme,
              selected: _selectedIndex == 2,
              onTap: () => _select(2),
              leading: Icon(
                PhosphorIconsRegular.calendarBlank,
                size: 24,
                color: scheme.primary,
              ),
              title: 'Skip today — adjust plan',
            ),
          ],
        ),

        SizedBox(height: AppSpacing.md),

        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 360;

          final confirm = _PrimaryAction(
            scheme: scheme,
            label: 'Confirm',
            onPressed: _confirm,
            enabled: _selectedIndex != null,
          );

          final cancel = _SecondaryAction(
            scheme: scheme,
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          );

          return isWide
              ? Row(
                  children: [
                    Expanded(child: cancel),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(child: confirm),
                  ],
                )
              : Column(
                  children: [
                    cancel,
                    SizedBox(height: AppSpacing.sm),
                    confirm,
                  ],
                );
        }),

        SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/* --------------------------- */

class _OptionCard extends StatelessWidget {
  final ColorScheme scheme;
  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;

  const _OptionCard({
    required this.scheme,
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.md),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: selected
              ? Border.all(color: scheme.secondary, width: 2)
              : AppBorders.boxCard(scheme),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outline),
              ),
              child: leading,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title)),
            if (selected)
              Icon(
                PhosphorIconsRegular.check,
                size: 24,
                color: scheme.secondary,
              ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- */

class _PrimaryAction extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const _PrimaryAction({
    required this.scheme,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: Text(label),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final VoidCallback onPressed;

  const _SecondaryAction({
    required this.scheme,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
