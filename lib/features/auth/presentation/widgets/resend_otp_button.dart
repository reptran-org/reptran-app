import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reptran_app/core/constants/tokens.dart';

class ResendOtpButton extends StatefulWidget {
  final Future<void> Function() onResend;
  final int initialCooldown;

  const ResendOtpButton({
    super.key,
    required this.onResend,
    this.initialCooldown = 60,
  });

  @override
  State<ResendOtpButton> createState() => _ResendOtpButtonState();
}

class _ResendOtpButtonState extends State<ResendOtpButton> {
  int _cooldown = 0;
  Timer? _timer;

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown > 0) {
        setState(() => _cooldown--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    await widget.onResend();
    _startTimer(widget.initialCooldown);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: _cooldown > 0 ? null : _handleResend,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xxl),
        ),
        minimumSize: const Size.fromHeight(56),
      ),
      child: Text(
        _cooldown > 0 ? 'Resend ($_cooldown s)' : 'Send Again',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: AppTypography.wSemibold,
          color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
        ),
      ),
    );
  }
}
