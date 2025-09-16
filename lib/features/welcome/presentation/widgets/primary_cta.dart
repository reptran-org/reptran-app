import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class PrimaryCta extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final double minWidth;
  final bool loading;
  final String? loadingText;

  const PrimaryCta({
    super.key,
    required this.onPressed,
    this.text = 'Get Started',
    this.minWidth = 220,
    this.loading = false,
    this.loadingText,
  });

  @override
  State<PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<PrimaryCta> {
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ],
            ],
          )
        : Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: AppTypography.wBold,
            ),
          );

    return Center(
      child: GestureDetector(
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
          child: SizedBox(
            width: widget.minWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                boxShadow: AppShadows.button(scheme),
              ),
              child:
                  ElevatedButton(
                        onPressed: widget.loading ? null : widget.onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          fixedSize: Size(widget.minWidth, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [scheme.tertiary, AppColors.accentDark],
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            height: 64,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: content,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: AppDurations.medium, delay: 50.ms)
                      .scale(begin: const Offset(0.98, 0.98)),
            ),
          ),
        ),
      ),
    );
  }
}
