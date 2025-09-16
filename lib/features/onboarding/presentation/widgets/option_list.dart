import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';

/// Option config:
/// { 'icon': IconData, 'label': String, 'color': Color? }
typedef OptionConfig = Map<String, Object?>;

class OptionList extends StatelessWidget {
  final List<OptionConfig> options;
  final bool multiSelect;
  final Set<String> initialSelection;
  final ValueChanged<Set<String>> onSelectionChanged;
  final EdgeInsetsGeometry? itemSpacing;

  const OptionList({
    super.key,
    required this.options,
    required this.onSelectionChanged,
    this.multiSelect = false,
    this.initialSelection = const {},
    this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return _OptionListInternal(
      options: options,
      multiSelect: multiSelect,
      initialSelection: initialSelection,
      onSelectionChanged: onSelectionChanged,
      itemSpacing: itemSpacing ?? const EdgeInsets.only(bottom: 16),
    );
  }
}

class _OptionListInternal extends StatefulWidget {
  final List<OptionConfig> options;
  final bool multiSelect;
  final Set<String> initialSelection;
  final ValueChanged<Set<String>> onSelectionChanged;
  final EdgeInsetsGeometry itemSpacing;

  const _OptionListInternal({
    required this.options,
    required this.multiSelect,
    required this.initialSelection,
    required this.onSelectionChanged,
    required this.itemSpacing,
  });

  @override
  State<_OptionListInternal> createState() => _OptionListInternalState();
}

class _OptionListInternalState extends State<_OptionListInternal> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelection);
  }

  void _toggle(String label) {
    setState(() {
      if (widget.multiSelect) {
        if (_selected.contains(label)) {
          _selected.remove(label);
        } else {
          _selected.add(label);
        }
      } else {
        // single select: replace selection
        if (_selected.contains(label)) {
          _selected.clear();
        } else {
          _selected.clear();
          _selected.add(label);
        }
      }
    });

    // notify parent
    widget.onSelectionChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < widget.options.length; i++) {
      final opt = widget.options[i];
      final label = opt['label'] as String;
      final icon = opt['icon'] as IconData? ?? PhosphorIconsFill.pencil;
      final color = opt['color'] as Color?;
      final selected = _selected.contains(label);

      children.add(
        _OptionTile(
          label: label,
          icon: icon,
          color: color ?? Theme.of(context).colorScheme.onSurface,
          selected: selected,
          onTap: () => _toggle(label),
        ),
      );

      // spacing between items
      if (i < widget.options.length - 1) {
        children.add(SizedBox(height: 16));
      }
    }

    return Column(children: children);
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 12,
        ),
        child: Row(
          children: [
            // checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? AppColors.positive : scheme.surface,
                border: Border.all(color: scheme.outline, width: 2),
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 24),
            Icon(icon, color: (color ?? scheme.onSurface), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppTypography.wSemibold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
