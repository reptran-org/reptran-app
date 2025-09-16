import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/auth/presentation/widgets/otp_input_row.dart';
import 'package:reptran_app/features/auth/presentation/widgets/resend_otp_button.dart';
import 'package:reptran_app/features/auth/services/auth_service.dart';
import 'package:reptran_app/features/auth/services/auth_services.dart';
import 'package:reptran_app/features/auth/presentation/widgets/primary_button.dart';
import 'package:reptran_app/core/network/api_client.dart';

class VerifyOtpPage extends StatefulWidget {
  final String? email;
  final String? purpose;

  const VerifyOtpPage({super.key, this.email, this.purpose});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _secureStorage = const FlutterSecureStorage();
  final Dio _dio = ApiClient().dio;

  String _enteredOtp = '';
  bool _loading = false;

  // --------------------
  // Timers: resend cooldown & OTP expiry
  // --------------------
  // Resend cooldown (seconds) — UI-level lock for resend button
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  // OTP expiry (seconds). 10 minutes = 600 seconds
  static const int _otpExpirySeconds = 10 * 60;
  int _expiryRemaining = 0;
  Timer? _expiryTimer;

  // --------------------
  // Helpers
  // --------------------
  String _formatSeconds(int total) {
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownRemaining = seconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldownRemaining > 0) {
        setState(() => _cooldownRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  void _startExpiryTimer([int? seconds]) {
    _expiryTimer?.cancel();
    setState(() => _expiryRemaining = seconds ?? _otpExpirySeconds);

    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_expiryRemaining > 0) {
        setState(() => _expiryRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  // --------------------
  // UI message helper
  // --------------------
  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  // --------------------
  // Verify OTP
  // --------------------
  Future<void> _verifyOtp() async {
    if (_enteredOtp.length != 6) {
      _showMessage('Please enter the 6-digit code', error: true);
      return;
    }

    final email = widget.email;
    final purpose = widget.purpose ?? 'verify';
    if (email == null || email.isEmpty) {
      _showMessage(
        'Email missing — please go back and re-enter email',
        error: true,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final resp = await AuthService().verifyOtp(
        email: email,
        purpose: purpose,
        otp: _enteredOtp,
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = resp.data as Map<String, dynamic>? ?? {};

        await AuthServices.markHasAccount();

        if (purpose == 'forgot_password') {
          final resetToken = data['resetToken'] as String?;
          if (resetToken != null) {
            await _secureStorage.write(
              key: 'password_reset_token',
              value: resetToken,
            );
            await _secureStorage.write(
              key: 'password_reset_email',
              value: email,
            );

            _showMessage('OTP verified. You may now set a new password.');
            if (mounted) context.go('/auth/create-new-password');
            return;
          }
          _showMessage('OTP verified but missing reset token.', error: true);
          return;
        }

        // normal signup/verify flow
        final token = data['token'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        if (token != null) {
          await _secureStorage.write(key: 'auth_token', value: token);
          if (refreshToken != null) {
            await _secureStorage.write(
              key: 'refresh_token',
              value: refreshToken,
            );
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isVerified', true);

          _dio.options.headers['Authorization'] = 'Bearer $token';
        }

        _showMessage('Verification successful');
        if (mounted) context.go('/onboarding/reason');
        return;
      }

      // non-200 case
      String msg = 'Invalid code';
      if (resp.data is Map) {
        final d = resp.data as Map;
        msg = (d['error'] ?? d['message'] ?? msg).toString();
      }
      _showMessage(msg, error: true);
    } on DioException catch (e) {
      String message;
      if (e.response?.data is Map) {
        final d = e.response?.data as Map;
        message = (d['error'] ?? d['message'])?.toString() ?? 'Server error';
      } else {
        message = 'Network error';
      }
      _showMessage(message, error: true);
    } catch (_) {
      _showMessage('Unexpected error. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --------------------
  // Resend OTP
  // --------------------
  Future<void> _resendOtp() async {
    final email = widget.email;
    final purpose = widget.purpose ?? 'verify';
    if (email == null || email.isEmpty) {
      _showMessage('Email missing — cannot resend', error: true);
      return;
    }

    try {
      final resp = await AuthService().resendOtp(
        email: email,
        purpose: purpose,
      );
      if (resp.statusCode == 200) {
        _showMessage('If an account exists, an OTP was sent to your email.');
        // start UI cooldown for resend
        _startCooldown(60);
        // reset the OTP expiry countdown to 10 minutes after resend
        _startExpiryTimer(_otpExpirySeconds);
      } else {
        _showMessage('Could not resend OTP', error: true);
      }
    } on DioException catch (e) {
      _showMessage('Error: ${e.message}', error: true);
    } catch (_) {
      _showMessage('Unexpected error while resending OTP', error: true);
    }
  }

  // --------------------
  // Lifecycle
  // --------------------
  @override
  void initState() {
    super.initState();
    // Start expiry countdown when the page opens (assumes OTP was just sent).
    _startExpiryTimer(_otpExpirySeconds);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  // --------------------
  // Build
  // --------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back + Logo row
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        scheme.brightness == Brightness.dark
                            ? 'assets/images/reptran_logo_white.png'
                            : 'assets/images/reptran_logo.png',
                        height: 48,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => context.pop(),
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.e1(scheme),
                            ),
                            child: Icon(
                              PhosphorIconsRegular.caretLeft,
                              size: 16,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Verify Your OTP',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter the OTP sent to your email to verify your identity.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // OTP input row
                OtpInputRow(length: 6, onChanged: (otp) => _enteredOtp = otp),
                const SizedBox(height: AppSpacing.lg),

                // expiry / status text
                if (_expiryRemaining > 0) ...[
                  Text(
                    'OTP expires in ${_formatSeconds(_expiryRemaining)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Code expired',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  onPressed: _verifyOtp,
                  loading: _loading,
                  loadingText: "Verifying code...",
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: AppTypography.wBold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Resend button (uses page-level cooldown)
                ResendOtpButton(onResend: _resendOtp, initialCooldown: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
