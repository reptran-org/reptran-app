import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:reptran_app/features/auth/presentation/widgets/auth_input.dart';
import 'package:reptran_app/features/auth/presentation/widgets/primary_button.dart';
import 'package:reptran_app/features/auth/presentation/widgets/social_icons_row.dart';
import 'package:reptran_app/features/auth/helpers/validators.dart';
import 'package:reptran_app/features/auth/services/auth_service.dart';
import 'package:reptran_app/features/auth/services/social_auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _errorMsg;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text,
    };

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final resp = await AuthService().signup(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (mounted) {
          context.push(
            '/auth/verify-otp',
            extra: {'email': data['email'], 'purpose': 'verify'},
          );
        }
      } else {
        final d = resp.data;
        String msg = 'Signup failed';
        if (d is Map && (d['error'] != null || d['message'] != null)) {
          msg = (d['error'] ?? d['message']).toString();
        }
        setState(() => _errorMsg = msg);
      }
    } on DioException catch (e) {
      String message;
      if (e.response != null) {
        final d = e.response?.data;
        if (d is Map && (d['error'] != null || d['message'] != null)) {
          message = (d['error'] ?? d['message']).toString();
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
    } catch (_) {
      setState(() => _errorMsg = 'Unexpected error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      title: 'Create Account',
      subtitle:
          'Create a new account to get started and enjoy seamless access to our features.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthInput(
              hint: 'Name',
              icon: PhosphorIconsRegular.user,
              controller: _nameCtrl,
              validator: requiredValidator,
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthInput(
              hint: 'Email Address',
              icon: PhosphorIconsRegular.envelopeSimple,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: emailValidator,
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthInput(
              hint: 'Password',
              icon: PhosphorIconsRegular.lock,
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              validator: passwordValidator,
              suffix: GestureDetector(
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                behavior: HitTestBehavior.translucent,
                child: Icon(
                  _obscurePassword
                      ? PhosphorIconsRegular.eyeSlash
                      : PhosphorIconsRegular.eye,
                  size: 22,
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AuthInput(
              hint: 'Confirm Password',
              icon: PhosphorIconsRegular.lock,
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
              suffix: GestureDetector(
                onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                behavior: HitTestBehavior.translucent,
                child: Icon(
                  _obscureConfirm
                      ? PhosphorIconsRegular.eyeSlash
                      : PhosphorIconsRegular.eye,
                  size: 22,
                  color: scheme.onSurface.withValues(
                    alpha: AppOpacities.secondary,
                  ),
                ),
              ),
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
              onPressed: _submit,
              loading: _loading,
              loadingText: "Signing In...",
              child: const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: AppTypography.wBold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Already have an account?",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                    fontWeight: AppTypography.wRegular,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/auth/login'),
                  child: Text(
                    "Sign In here",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: AppTypography.wSemibold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(thickness: 2, color: scheme.outline),
            const SizedBox(height: AppSpacing.lg),
            Column(
              children: [
                Text(
                  "Or Continue With Account",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                    fontWeight: AppTypography.wRegular,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SocialIconsRow(
                  onFacebook: () =>
                      SocialAuthService.handleFacebookSignIn(context),
                  onGoogle: () => SocialAuthService.handleGoogleSignIn(context),
                  onTwitter: () =>
                      SocialAuthService.handleTwitterSignIn(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
