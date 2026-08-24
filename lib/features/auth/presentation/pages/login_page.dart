import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;

  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _errorMsg;
  bool _obscurePassword = true;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final resp = await AuthService().login(email: email, password: password);

      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>? ?? {};
        final token = data['token'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (token != null) {
          await _secureStorage.write(key: 'auth_token', value: token);
        }

        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        // Optionally set Authorization header on ApiClient elsewhere.
        // Mark that device/user has an account
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_account', true);

        if (user != null) {
          await prefs.setString('me_user', jsonEncode(user));
        }

        final onboarded = user != null
            ? (user['onboardingCompleted'] as bool? ?? false)
            : false;
        if (!onboarded) {
          if (!mounted) return;
          context.go('/onboarding/reason');
        } else {
          if (!mounted) return;
          context.go('/home');
        }
        return;
      }

      // Non-200: parse message
      String msg = 'Login failed';
      if (resp.data is Map &&
          (resp.data['error'] != null || resp.data['message'] != null)) {
        msg = (resp.data['error'] ?? resp.data['message']).toString();
      }
      setState(() => _errorMsg = msg);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      setState(() => _errorMsg = 'Unexpected error. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      title: 'Log In',
      subtitle:
          'Enter your email and password to securely access your account and manage your services.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.xs),
                        ),
                        side: BorderSide(
                          color: scheme.onSurface.withValues(
                            alpha: AppOpacities.secondary,
                          ),
                          width: 1,
                        ),
                        checkColor: Colors.white,
                        fillColor: WidgetStateProperty.resolveWith<Color>((
                          states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.positive;
                          }
                          return Colors.transparent;
                        }),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Remember Me",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(
                          alpha: AppOpacities.secondary,
                        ),
                        fontWeight: AppTypography.wRegular,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/auth/forgot-password'),
                  child: Text(
                    "Forgot Password?",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                      fontWeight: AppTypography.wRegular,
                      decoration: TextDecoration.underline,
                      decorationColor: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              onPressed: _login,
              loading: _loading,
              loadingText: "Logging In...",
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: AppTypography.wBold,
                ),
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Don’t have an account?",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                    fontWeight: AppTypography.wRegular,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/auth/signup'),
                  child: Text(
                    "Sign Up here",
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
               GoogleSignInButton(
  onTap: () => SocialAuthService.handleGoogleSignIn(context),
),
              ],
            ),
         
         
          ],
        ),
      ),
    );
  }
}
