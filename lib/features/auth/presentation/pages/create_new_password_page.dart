import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:dio/dio.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:reptran_app/features/auth/presentation/widgets/auth_input.dart';
import 'package:reptran_app/features/auth/presentation/widgets/primary_button.dart';
import 'package:reptran_app/features/auth/services/auth_service.dart';

class CreateNewPasswordPage extends StatefulWidget {
  const CreateNewPasswordPage({super.key});

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  String? _emailFromStorage;
  String? _resetTokenFromStorage;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadStoredCreds();
    _passwordCtrl.addListener(() {
      if (mounted) setState(() {}); // update inline hint
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStoredCreds() async {
    final email = await _secureStorage.read(key: 'password_reset_email');
    final token = await _secureStorage.read(key: 'password_reset_token');
    setState(() {
      _emailFromStorage = email;
      _resetTokenFromStorage = token;
    });
  }

  // -----------------------
  // Modern password rules
  // -----------------------
  List<String> _passwordErrors(String pwd) {
    final errors = <String>[];
    if (pwd.length < 8) errors.add('At least 8 characters');
    if (!RegExp(r'[A-Z]').hasMatch(pwd)) errors.add('One uppercase letter');
    if (!RegExp(r'[a-z]').hasMatch(pwd)) errors.add('One lowercase letter');
    if (!RegExp(r'\d').hasMatch(pwd)) errors.add('One number');
    if (!RegExp(
      r'[!@#\$%\^&\*\(\)_\+\-=\[\]{};:"\\|,.<>\/?~`]',
    ).hasMatch(pwd)) {
      errors.add('One special character');
    }
    if (pwd.contains(' ')) errors.add('No spaces allowed');
    if (RegExp(r'(.)\1\1\1').hasMatch(pwd)) errors.add('Avoid repeated chars');
    return errors;
  }

  bool _validateInputs() {
    final pwd = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (pwd.isEmpty || confirm.isEmpty) {
      _showMessage('Please fill both fields', error: true);
      return false;
    }
    if (pwd != confirm) {
      _showMessage('Passwords do not match', error: true);
      return false;
    }
    final errs = _passwordErrors(pwd);
    if (errs.isNotEmpty) {
      _showMessage('Password must: ${errs.take(2).join(", ")}', error: true);
      return false;
    }
    if (_emailFromStorage == null) {
      _showMessage('Missing email. Restart reset flow.', error: true);
      return false;
    }
    if (_resetTokenFromStorage == null) {
      _showMessage(
        'Warning: missing reset token, server may reject.',
        error: false,
      );
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateInputs()) return;

    setState(() => _loading = true);

    try {
      final resp = await AuthService().resetPassword(
        resetToken: _resetTokenFromStorage ?? '',
        newPassword: _passwordCtrl.text.trim(),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        _showMessage('Password updated successfully.');
        await _secureStorage.delete(key: 'password_reset_token');
        await _secureStorage.delete(key: 'password_reset_email');
        if (mounted) context.go('/auth/login');
        return;
      }

      var msg = 'Could not reset password';
      final data = resp.data;
      if (data is Map && (data['error'] != null || data['message'] != null)) {
        msg = (data['error'] ?? data['message']).toString();
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

  void _showMessage(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pwd = _passwordCtrl.text;
    final errors = _passwordErrors(pwd);

    return AuthScaffold(
      title: 'Create New Password',
      subtitle:
          'Set a strong new password to enhance security and protect your account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthInput(
            hint: 'Password',
            icon: PhosphorIconsRegular.lock,
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
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

          // ---- progressive password hints ----
          if (pwd.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: errors.isEmpty
                  ? Text(
                      '• Strong password format',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade600,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: errors.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $e',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.orange.shade700),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          AuthInput(
            hint: 'Confirm Password',
            icon: PhosphorIconsRegular.lock,
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
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
          PrimaryButton(
            onPressed: _submit,
            loading: _loading,
            loadingText: "Updating password...",
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
    );
  }
}
