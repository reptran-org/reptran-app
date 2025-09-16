import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class PrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;
  final double minHeight;
  final String? loadingText;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loading = false,
    this.minHeight = 56,
    this.loadingText,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // spinner color: use onPrimary so it contrasts with gradient.
    final spinner = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.whiteUtility),
      ),
    );

    final content = widget.loading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              spinner,
              const SizedBox(width: 10),
              Text(
                widget.loadingText ?? 'Loading...',
                style: TextStyle(
                  color: AppColors.whiteUtility,
                  fontWeight: AppTypography.wBold,
                ),
              ),
            ],
          )
        : widget.child;

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.loading && widget.onPressed != null) _setPressed(true);
      },
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? AppAnimation.pressScale : 1.0,
        duration: AppAnimation.microInteraction,
        curve: Curves.easeOut,
        child: Container(
          // draw the rounded shadow here
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            boxShadow: AppShadows.button(scheme),
          ),
          child: ElevatedButton(
            onPressed: widget.loading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: EdgeInsets.zero,
              minimumSize: Size.fromHeight(widget.minHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.xxl),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.tertiary, AppColors.accentDark],
                ),
                borderRadius: BorderRadius.circular(AppRadii.xxl),
                // remove boxShadow from here (it's now on the parent Container)
              ),
              child: Container(
                constraints: BoxConstraints(minHeight: widget.minHeight),
                padding: const EdgeInsets.all(AppSpacing.sm),
                width: double.infinity,
                alignment: Alignment.center,
                child: DefaultTextStyle(
                  style: TextStyle(color: scheme.onPrimary),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
