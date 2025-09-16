import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:reptran_app/features/auth/presentation/widgets/auth_input.dart';
import 'package:reptran_app/features/auth/presentation/widgets/primary_button.dart';
import 'package:reptran_app/features/auth/helpers/validators.dart';
import 'package:reptran_app/features/auth/services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim().toLowerCase();

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final resp = await AuthService().forgotPassword(email: email);

      if (resp.statusCode == 200) {
        // assume server sent success + maybe OTP; navigate to verify
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent. Check your email.')),
        );

        context.go(
          '/auth/verify-otp',
          extra: {'email': email, 'purpose': 'forgot_password'},
        );
        return;
      }

      // non-200 path
      String msg = 'Failed to send reset link';
      if (resp.data is Map &&
          (resp.data['error'] != null || resp.data['message'] != null)) {
        msg = (resp.data['error'] ?? resp.data['message']).toString();
      }
      setState(() => _errorMsg = msg);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } on DioException catch (e) {
      String message;
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && (data['error'] != null || data['message'] != null)) {
          message = (data['error'] ?? data['message']).toString();
        } else {
          message = 'Server error: ${e.response?.statusCode}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Connection timed out. Check your network.';
      } else {
        message = 'Network error. Please try again.';
      }
      setState(() => _errorMsg = message);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      const fallback = 'Unexpected error. Please try again.';
      setState(() => _errorMsg = fallback);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(fallback)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      title: 'Forgot Password',
      subtitle:
          'Enter your email to receive a reset link or OTP and regain access to your account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthInput(
              hint: 'Email Address',
              icon: Icons.email,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: emailValidator,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_errorMsg != null) ...[
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            PrimaryButton(
              onPressed: _sendResetLink,
              loading: _loading,
              loadingText: "Sending reset link...",
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: AppTypography.wBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
