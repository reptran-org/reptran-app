// CustomExerciseModal.dart
// showDialog(context: context, builder: (_) => const CustomExerciseModal());

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';


class CustomExerciseModal extends StatelessWidget {
  const CustomExerciseModal({super.key});

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

/* --------------------------- CONTENT --------------------------- */

class _ModalCard extends StatefulWidget {
  const _ModalCard();

  @override
  State<_ModalCard> createState() => _ModalCardState();
}

class _ModalCardState extends State<_ModalCard> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _category; // e.g., Strength, Mobility, Cardio
  String? _equipment; // e.g., Bodyweight, Dumbbells, Bands

  final Set<String> _muscles = {};

  final _categoryOptions = const ['Strength', 'Mobility', 'Cardio'];
  final _equipmentOptions = const ['Bodyweight', 'Dumbbells', 'Barbell', 'Bands', 'Machines'];

  final _muscleOptions = const [
    'Chest',
    'Shoulders',
    'Triceps',
    'Back',
    'Biceps',
    'Forearms',
    'Quads',
    'Hamstrings',
    'Glutes',
    'Calves',
    'Abs',
    'Obliques',
  ];

  Future<void> _pickFromMenu(
    Offset position, {
    required List<String> items,
    required void Function(String value) onSelect,
  }) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, 0),
      items: items
          .map(
            (e) => PopupMenuItem<String>(
              value: e,
              child: Text(e),
            ),
          )
          .toList(),
    );
    if (selected != null) onSelect(selected);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  PhosphorIconsRegular.x,
                  size: 24,
                  color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                ),
              ),
            ),

            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: AppOpacities.tertiary),
                    border: AppBorders.boxCard(scheme),
                        borderRadius: BorderRadius.circular(AppRadii.md),

                  ),
                  child: Icon(PhosphorIconsRegular.barbell, size: 24, color: scheme.secondary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Custom Exercise', style: tt.headlineSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        "Name your move — we'll track it like any other exercise.",
                        style: tt.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            _Divider(scheme: scheme),
            const SizedBox(height: AppSpacing.md),

            // Exercise Name *
            _FieldLabel('Exercise Name *'),
            const SizedBox(height: AppSpacing.xs),
            _TextFieldCard(controller: _nameCtrl),

            const SizedBox(height: AppSpacing.md),

            // Category *
            _FieldLabel('Category *'),
            const SizedBox(height: AppSpacing.xs),
            _SelectCard(
              placeholder: 'Select Category...',
              value: _category,
              onTap: (tapOffset) => _pickFromMenu(
                tapOffset,
                items: _categoryOptions,
                onSelect: (v) => setState(() => _category = v),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Equipment *
            _FieldLabel('Equipment *'),
            const SizedBox(height: AppSpacing.xs),
            _SelectCard(
              placeholder: 'Select Equipment...',
              value: _equipment,
              onTap: (tapOffset) => _pickFromMenu(
                tapOffset,
                items: _equipmentOptions,
                onSelect: (v) => setState(() => _equipment = v),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Target Muscles (optional)
            Row(
              children: [
                _FieldLabel('Target Muscles'),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '(optional)',
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _muscleOptions
                  .map(
                    (m) => _TogglePill(
                      label: m,
                      selected: _muscles.contains(m),
                      onTap: () => setState(() {
                        _muscles.contains(m) ? _muscles.remove(m) : _muscles.add(m);
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_muscles.length} muscle${_muscles.length == 1 ? '' : 's'} selected',
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Notes (optional)
            Row(
              children: [
                _FieldLabel('Notes'),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '(optional)',
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _MultilineFieldCard(controller: _notesCtrl, hint: 'Describe technique, cues, or variations...'),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add any form cues or technique notes that help you perform this exercise correctly.',
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Info callout
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(AppSpacing.sm),
  decoration: BoxDecoration(
    color: scheme.secondary.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(AppRadii.lg),
    border: Border.all(color: scheme.secondary),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        PhosphorIconsRegular.info,
        size: 24,
        color: scheme.secondary,
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Builder(
          builder: (context) {
            const text =
                "You're defining your movement library. Every custom exercise becomes part of your training identity.";

            // Split first sentence
            final i = text.indexOf('.');
            final first = i != -1 ? text.substring(0, i + 1) : text;
            final rest = i != -1 ? text.substring(i + 1) : '';

            return RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: first + " ", // preserve spacing
                    style: tt.bodyMedium?.copyWith(
                      color: scheme.secondary, // highlighted sentence
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: rest,
                    style: tt.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  ),
)
,
            const SizedBox(height: AppSpacing.md),
            _Divider(scheme: scheme),
            const SizedBox(height: AppSpacing.md),

            // Actions
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: AppBorders.sideOnePx(scheme),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      ),
                      child: Text('Cancel', style: tt.labelLarge),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // return payload to caller if needed
                        Navigator.of(context).pop({
                          'name': _nameCtrl.text.trim(),
                          'category': _category,
                          'equipment': _equipment,
                          'muscles': _muscles.toList(),
                          'notes': _notesCtrl.text.trim(),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        elevation: 0,
                      ),
                      child: Text('Save Exercise', style: tt.labelLarge!.copyWith(color: AppColors.whiteUtility)),
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

/* --------------------------- HELPERS --------------------------- */

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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _TextFieldCard extends StatelessWidget {
  const _TextFieldCard({required this.controller, this.hint});

  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint ?? 'e.g., Single-Arm Cable Row',
          filled: true,
          fillColor: scheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 12, // 48px target height feel (tune if needed)
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            borderSide: AppBorders.boxCard(scheme).top,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            borderSide: AppBorders.boxCard(scheme).top,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            borderSide: AppBorders.boxCard(scheme).top.copyWith(
              width: AppBorders.boxCard(scheme).top.width + 0.5,
            ),
          ),
        ),
      ),
    );
  }
}


class _MultilineFieldCard extends StatelessWidget {
  const _MultilineFieldCard({required this.controller, this.hint});

  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: 5,
        decoration: InputDecoration(
          hintText: hint ?? 'Describe technique, cues, or variations...',
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.placeholder,
    required this.value,
    required this.onTap,
  });

  final String placeholder;
  final String? value;
  final void Function(Offset tapOffset) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => onTap(details.globalPosition),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: AppBorders.boxCard(scheme),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                style: value == null
                    ? tt.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
                      )
                    : tt.bodyMedium,
              ),
            ),
            Icon(PhosphorIconsRegular.caretDown, size: 24, color: scheme.onSurface),
          ],
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
    final tt = Theme.of(context).textTheme;
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
          color: selected ? scheme.secondary.withValues(alpha: AppOpacities.secondary) : isLight ? AppColors.neutralLight : AppColors.neutralDark,
          border: selected ? Border.all(color: scheme.secondary, width: 2) : AppBorders.boxCard(scheme),
          boxShadow: AppShadows.e1(scheme),
        ),
        child: Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: selected ? scheme.onSecondary : scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
