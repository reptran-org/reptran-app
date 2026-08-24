import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';


class IntentModal extends StatelessWidget {
  const IntentModal({super.key, required this.onSelect});

  final void Function(int weeklyIntent) onSelect;

  static Future<void> show(
    BuildContext context, {
    required void Function(int weeklyIntent) onSelect,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      barrierDismissible: true,
      builder: (_) => IntentModal(onSelect: onSelect),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.xxl),
              boxShadow: AppShadows.e4(scheme),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.xxl),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _ModalContent(scheme: scheme, onSelect: onSelect),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Content
// ─────────────────────────────────────────────────────────────

class _ModalContent extends StatelessWidget {
  const _ModalContent({required this.scheme, required this.onSelect});

  final ColorScheme scheme;
  final void Function(int) onSelect;

  static const List<int> _options = [1, 2, 3, 4, 5, 6];

  void _handleSelect(BuildContext context, int value) {
    onSelect(value);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CloseRow(scheme: scheme),
          const SizedBox(height: AppSpacing.xs),
          _HeadingBlock(scheme: scheme),
          const SizedBox(height: AppSpacing.md),
          _DividerLine(scheme: scheme),
          const SizedBox(height: AppSpacing.md),
          _OptionsGrid(
            scheme: scheme,
            options: _options,
            onTap: (v) => _handleSelect(context, v),
          ),
          const SizedBox(height: AppSpacing.md),
          _FooterHint(scheme: scheme),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Close row
// ─────────────────────────────────────────────────────────────

class _CloseRow extends StatelessWidget {
  const _CloseRow({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: AppSpacing.lg,
          height: AppSpacing.lg,
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Icon(
            Icons.close_rounded,
            size: AppTypography.body,
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Heading block
// ─────────────────────────────────────────────────────────────

class _HeadingBlock extends StatelessWidget {
  const _HeadingBlock({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You showed up 👊',
          style: TextStyle(
            fontSize: AppTypography.heading,
            fontWeight: AppTypography.wBold,
            height: AppTypography.lhTight,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'What feels realistic for you in a week?',
          style: TextStyle(
            fontSize: AppTypography.body,
            fontWeight: AppTypography.wRegular,
            height: AppTypography.lhNormal,
            color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Subtle divider
// ─────────────────────────────────────────────────────────────

class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: scheme.onSurface.withValues(alpha: 0.08),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2-column pill grid
// ─────────────────────────────────────────────────────────────

class _OptionsGrid extends StatelessWidget {
  const _OptionsGrid({
    required this.scheme,
    required this.options,
    required this.onTap,
  });

  final ColorScheme scheme;
  final List<int> options;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    // Pair options into rows of 2
    final rows = <List<int>>[];
    for (var i = 0; i < options.length; i += 2) {
      rows.add(options.sublist(i, (i + 2).clamp(0, options.length)));
    }

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  for (var i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _PillOption(
                        scheme: scheme,
                        days: row[i],
                        onTap: () => onTap(row[i]),
                      ),
                    ),
                  ],
                  // If row has only 1 item (odd total), fill the other half
                  if (row.length == 1) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual pill option with press animation
// ─────────────────────────────────────────────────────────────

class _PillOption extends StatefulWidget {
  const _PillOption({
    required this.scheme,
    required this.days,
    required this.onTap,
  });

  final ColorScheme scheme;
  final int days;
  final VoidCallback onTap;

  @override
  State<_PillOption> createState() => _PillOptionState();
}

class _PillOptionState extends State<_PillOption> {
  bool _pressed = false;

  String get _label =>
      '${widget.days} ${widget.days == 1 ? 'day' : 'days'} / week';

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppAnimation.pressScale : 1.0,
        duration: AppAnimation.microInteraction,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: AppAnimation.microInteraction,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed
                ? scheme.primary.withValues(alpha: 0.88)
                : scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: _pressed
                  ? scheme.primary
                  : scheme.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Text(
            _label,
            style: TextStyle(
              fontSize: AppTypography.caption,
              fontWeight: AppTypography.wSemibold,
              height: AppTypography.lhTight,
              color: _pressed
                  ? scheme.onPrimary
                  : scheme.primary,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Footer hint
// ─────────────────────────────────────────────────────────────

class _FooterHint extends StatelessWidget {
  const _FooterHint({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      'You can adjust this later',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: AppTypography.micro,
        fontWeight: AppTypography.wRegular,
        height: AppTypography.lhNormal,
        color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
      ),
    );
  }
}