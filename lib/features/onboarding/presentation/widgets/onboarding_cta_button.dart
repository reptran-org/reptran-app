import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class OnboardingCtaButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String label;
  final String? loadingText;

  const OnboardingCtaButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Continue',
    this.loadingText,
  });

  @override
  State<OnboardingCtaButton> createState() => _OnboardingCtaButtonState();
}

class _OnboardingCtaButtonState extends State<OnboardingCtaButton> {
  bool _pressed = false;

  void _setPressed(bool val) {
    if (mounted) setState(() => _pressed = val);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
              if ((widget.loadingText ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  widget.loadingText!,
                  style: TextStyle(
                    color: AppColors.whiteUtility,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          )
        : Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.whiteUtility,
              fontWeight: AppTypography.wBold,
            ),
          );

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.loading && widget.onPressed != null) _setPressed(true);
      },
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? AppAnimation.pressScale : 1.0,
        duration: AppAnimation.microInteraction,
        curve: Curves.easeOut,
        child: Container(
          // 👇 shadow applied here, with the same border radius
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: AppShadows.button(scheme),
          ),
          child: ElevatedButton(
            onPressed: widget.loading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: EdgeInsets.zero,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.tertiary, AppColors.accentDark],
                ),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.all(AppSpacing.sm),
                alignment: Alignment.center,
                child: DefaultTextStyle(
                  style: TextStyle(color: AppColors.whiteUtility),
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
