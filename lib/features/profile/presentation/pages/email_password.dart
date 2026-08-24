import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/profile/services/profile_service.dart';
import 'package:dio/dio.dart';

String? passwordValidator(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';

  final password = v.trim();

  if (password.length < 8) {
    return 'Must be at least 8 characters';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Must include a lowercase letter';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Must include an uppercase letter';
  }
  if (!RegExp(r'\d').hasMatch(password)) {
    return 'Must include a number';
  }
  if (!RegExp(r'[\W_]').hasMatch(password)) {
    return 'Must include a special character';
  }

  return null;
}

List<String> getPasswordErrors(String password) {
  final errors = <String>[];

  if (password.length < 8) {
    errors.add('At least 8 characters');
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    errors.add('Lowercase letter');
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    errors.add('Uppercase letter');
  }
  if (!RegExp(r'\d').hasMatch(password)) {
    errors.add('Number');
  }
  if (!RegExp(r'[\W_]').hasMatch(password)) {
    errors.add('Special character');
  }

  return errors;
}



class EmailPasswordPage extends StatefulWidget {
  const EmailPasswordPage({super.key});

  @override
  State<EmailPasswordPage> createState() => _EmailPasswordPageState();
}

class _EmailPasswordPageState extends State<EmailPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  bool _isSavingEmail = false;
  String? _currentEmail;

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _currentPasswordFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  bool _isSavingPassword = false;
  bool _isGoogleUser = false;
  bool _isLoadingAuthType = true;
  bool _hasStartedTypingPassword = false;
List<String> _passwordErrors = [];

  bool get _isEmailValid =>
      _emailController.text.contains('@') && _isEmailChanged;

bool get _isPasswordValid =>
  _currentPasswordController.text.trim().isNotEmpty &&
  passwordValidator(_newPasswordController.text) == null &&
  _newPasswordController.text.trim() ==
      _confirmPasswordController.text.trim();

  bool get _passwordsMatch =>
      _confirmPasswordController.text.trim().isNotEmpty &&
      _newPasswordController.text.trim() ==
          _confirmPasswordController.text.trim();

  bool get _passwordsMismatch =>
      _confirmPasswordController.text.trim().isNotEmpty &&
      _newPasswordController.text.trim() !=
          _confirmPasswordController.text.trim();

  @override
  void initState() {
    super.initState();
    _loadEmail();
    _emailController.addListener(() => setState(() {}));
    _currentPasswordController.addListener(() => setState(() {}));
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
        _newPasswordController.addListener(() {
  final value = _newPasswordController.text.trim();

  setState(() {
    _hasStartedTypingPassword = value.isNotEmpty;
    _passwordErrors = getPasswordErrors(value);
  });
});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();

    super.dispose();
  }
Future<void> _loadEmail() async {
  try {
    final data = await ProfileService().getUserEmail();

    _emailController.text = data['email'];
    _currentEmail = data['email'];
    _isGoogleUser = data['isGoogleUser'] ?? false;
  } catch (e) {
  } finally {
    if (mounted) {
      setState(() => _isLoadingAuthType = false);
    }
  }
}
  bool get _isEmailChanged =>
      _emailController.text.trim() != (_currentEmail ?? '');

Future<void> _saveEmail() async {
  if (!_isEmailValid || !_isEmailChanged || _isGoogleUser) return;

  setState(() => _isSavingEmail = true);

  try {
    await ProfileService().updateEmail(
      newEmail: _emailController.text.trim(),
    );

    // ✅ update local state
    _currentEmail = _emailController.text.trim();

    _showSuccessSnackBar('Email updated successfully');
  } catch (e) {
    _showErrorSnackBar('Failed to update email');
  } finally {
    if (mounted) {
      setState(() => _isSavingEmail = false);
    }
  }
}
Future<void> _savePassword() async {
  if (!_isPasswordValid || _isGoogleUser) return;

  setState(() => _isSavingPassword = true);

  try {
    await ProfileService().updatePassword(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );

    _showSuccessSnackBar(
      'Password updated — you may need to log in again',
    );

    // ✅ clear fields
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  } catch (e) {
  String message = 'Something went wrong';

  if (e is DioException) {
    final data = e.response?.data;

    if (data is Map && data['message'] != null) {
      message = data['message'];
    } else if (e.response?.statusCode == 400) {
      message = 'Invalid input';
    } else {
      message = 'Server error';
    }
  }

  _showErrorSnackBar(message);
} finally {
    if (mounted) {
      setState(() => _isSavingPassword = false);
    }
  }
}

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 3),
        content: _SuccessSnackBarContent(message: message),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      duration: const Duration(seconds: 3),
      content: _ErrorSnackBarContent(message: message),
    ),
  );
}

Widget _buildPasswordRules() {
  final password = _newPasswordController.text.trim();

  final rules = [
    'At least 8 characters',
    'Lowercase letter',
    'Uppercase letter',
    'Number',
    'Special character',
  ];

  final checks = [
    password.length >= 8,
    RegExp(r'[a-z]').hasMatch(password),
    RegExp(r'[A-Z]').hasMatch(password),
    RegExp(r'\d').hasMatch(password),
    RegExp(r'[\W_]').hasMatch(password),
  ];

  final isTyping = password.isNotEmpty;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(rules.length, (index) {
      final isValid = checks[index];

      final color = !isTyping
          ? Colors.grey
          : isValid
              ? Colors.green
              : Colors.red;

      return Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            rules[index],
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      );
    }),
  );
}

  int _passwordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  ColorScheme get _cs => Theme.of(context).colorScheme;
  bool get _isLight => Theme.of(context).brightness == Brightness.light;

  @override
  Widget build(BuildContext context) {
    final cs = _cs;

      if (_isLoadingAuthType) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────
            Container(
              color: cs.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxl,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(
                      PhosphorIcons.arrowLeft(),
                      size: 22,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Login & Security',
                    style: TextStyle(
                      fontSize: AppTypography.heading,
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                      height: AppTypography.lhTight,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Email card ───────────────────────
                  _SectionCard(
                    icon: PhosphorIcons.envelopeSimple(),
                    iconColor: AppColors.primary,
                    title: 'Email Address',
                    subtitle: _isGoogleUser
                        ? 'Managed by Google'
                        : 'Change the email you use to sign in',
                    cs: cs,
                    isLight: _isLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InputField(
                          label: 'Email Address',
                          hint: 'you@example.com',
                          controller: _emailController,
                          focusNode: _emailFocus,
                          prefixIcon: PhosphorIcons.envelopeSimple(),
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isGoogleUser,
                          cs: cs,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (_isGoogleUser) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  PhosphorIcons.info(),
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    'You’re signed in with Google. Your email is managed by your Google account and can’t be changed here.',
                                    style: TextStyle(
                                      fontSize: AppTypography.micro,
                                      color: AppColors.primary.withValues(
                                        alpha: 0.85,
                                      ),
                                      height: AppTypography.lhNormal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _ActionButton(
                          label: 'Update Email',
                          isLoading: _isSavingEmail,
                          isDisabled:
                              _isGoogleUser ||
                              !_isEmailValid ||
                              _isSavingEmail ||
                              !_isEmailChanged,
                          onTap: _saveEmail,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Password card ────────────────────
                  if (!_isGoogleUser) ...[
                    _SectionCard(
                      icon: PhosphorIcons.shieldCheck(),
                      iconColor: AppColors.accent,
                      title: 'Password',
                      subtitle:
                          'Use a strong password you don\'t use elsewhere',
                      cs: cs,
                      isLight: _isLight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InputField(
                            label: 'Current Password',
                            hint: '••••••••',
                            controller: _currentPasswordController,
                            focusNode: _currentPasswordFocus,
                            prefixIcon: PhosphorIcons.lockSimple(),
                            isPassword: true,
                            cs: cs,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _InputField(
                            label: 'New Password',
                            hint: 'Min. 8 characters',
                            controller: _newPasswordController,
                            focusNode: _newPasswordFocus,
                            prefixIcon: PhosphorIcons.lockKey(),
                            isPassword: true,
                            cs: cs,
                          ),
                          if (_newPasswordController.text.isNotEmpty) ...[
  const SizedBox(height: AppSpacing.sm),
  _buildPasswordRules(),
],
                          if (_newPasswordController.text.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _PasswordStrengthMeter(
                              strength: _passwordStrength(
                                _newPasswordController.text,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          _InputField(
                            label: 'Confirm New Password',
                            hint: '••••••••',
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocus,
                            prefixIcon: PhosphorIcons.lockKeyOpen(),
                            isPassword: true,
                            cs: cs,
                            validationState:
                                _confirmPasswordController.text.isEmpty
                                ? _FieldValidation.none
                                : _passwordsMatch
                                ? _FieldValidation.valid
                                : _FieldValidation.invalid,
                          ),
                          if (_passwordsMismatch) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            _ValidationHint(
                              message: 'Passwords don\'t match',
                              isError: true,
                            ),
                          ] else if (_passwordsMatch) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            _ValidationHint(
                              message: 'Passwords match',
                              isError: false,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          _InfoBanner(cs: cs, isLight: _isLight),
                          const SizedBox(height: AppSpacing.md),
                          _ActionButton(
                            label: 'Update Password',
                            isLoading: _isSavingPassword,
                            isDisabled: !_isPasswordValid || _isSavingPassword,
                            onTap: _savePassword,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _SectionCard(
                      icon: PhosphorIcons.shieldCheck(),
                      iconColor: AppColors.accent,
                      title: 'Password',
                      subtitle: 'Managed by Google',
                      cs: cs,
                      isLight: _isLight,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              PhosphorIcons.info(),
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'You’re signed in with Google. Passwords are managed by your Google account, so you won’t need one here.',
                                style: TextStyle(
                                  fontSize: AppTypography.micro,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.85,
                                  ),
                                  height: AppTypography.lhNormal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;
  final ColorScheme cs;
  final bool isLight;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.cs,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isLight ? 0.08 : 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppTypography.body,
                          fontWeight: AppTypography.wSemibold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppTypography.micro,
                          fontWeight: AppTypography.wRegular,
                          color: cs.onSurface.withValues(
                            alpha: AppOpacities.secondary,
                          ),
                          height: AppTypography.lhNormal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outline.withValues(alpha: 0.5),
          ),
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Field
// ─────────────────────────────────────────────────────────────────────────────

enum _FieldValidation { none, valid, invalid }

class _InputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final _FieldValidation validationState;
  final ColorScheme cs;
  final bool enabled;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.prefixIcon,
    required this.cs,
    this.isPassword = false,
    this.keyboardType,
    this.enabled = true,
    this.validationState = _FieldValidation.none,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _isFocused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  Color get _borderColor {
    if (widget.validationState == _FieldValidation.valid) {
      return AppColors.positive;
    }
    if (widget.validationState == _FieldValidation.invalid) {
      return widget.cs.error;
    }
    if (_isFocused) return AppColors.primary;
    return widget.cs.outline.withValues(alpha: 0.5);
  }

  Color get _fillColor {
    if (widget.validationState == _FieldValidation.valid) {
      return AppColors.positive.withValues(alpha: 0.05);
    }
    if (widget.validationState == _FieldValidation.invalid) {
      return widget.cs.error.withValues(alpha: 0.05);
    }
    if (_isFocused) return AppColors.primary.withValues(alpha: 0.04);
    return widget.cs.onSurface.withValues(alpha: 0.04);
  }

  Color get _prefixColor {
    if (widget.validationState == _FieldValidation.valid) {
      return AppColors.positive;
    }
    if (widget.validationState == _FieldValidation.invalid) {
      return widget.cs.error;
    }
    if (_isFocused) return AppColors.primary;
    return widget.cs.onSurface.withValues(alpha: AppOpacities.tertiary);
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;

    Widget? suffix;
    if (widget.validationState == _FieldValidation.valid) {
      suffix = Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(
          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
          size: 17,
          color: AppColors.positive,
        ),
      );
    } else if (widget.validationState == _FieldValidation.invalid) {
      suffix = Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Icon(
          PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
          size: 17,
          color: cs.error,
        ),
      );
    } else if (widget.isPassword) {
      suffix = GestureDetector(
        onTap: () => setState(() => _obscure = !_obscure),
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            _obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
            size: 17,
            color: cs.onSurface.withValues(alpha: AppOpacities.tertiary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: AppTypography.micro,
            fontWeight: AppTypography.wMedium,
            color: cs.onSurface.withValues(alpha: AppOpacities.secondary),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: widget.isPassword ? _obscure : false,
          keyboardType: widget.keyboardType,
          style: TextStyle(fontSize: AppTypography.body, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: AppTypography.body,
              color: cs.onSurface.withValues(alpha: AppOpacities.tertiary),
            ),
            filled: true,
            fillColor: _fillColor,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 13,
              horizontal: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 10),
              child: Icon(widget.prefixIcon, size: 17, color: _prefixColor),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(minWidth: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: _borderColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password Strength Meter
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrengthMeter extends StatelessWidget {
  final int strength;

  const _PasswordStrengthMeter({required this.strength});

  static const _labels = ['Too weak', 'Weak', 'Fair', 'Strong', 'Very strong'];
  static const _colors = [
    Color(0xFFE53E3E),
    Color(0xFFED8936),
    Color(0xFFECC94B),
    Color(0xFF48BB78),
    Color(0xFF38A169),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final idx = strength.clamp(0, 4);
    final color = _colors[idx];
    final label = _labels[idx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? AppSpacing.xxs : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: i < strength
                      ? color
                      : cs.onSurface.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.micro,
            fontWeight: AppTypography.wMedium,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Validation Hint
// ─────────────────────────────────────────────────────────────────────────────

class _ValidationHint extends StatelessWidget {
  final String message;
  final bool isError;

  const _ValidationHint({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isError ? cs.error : AppColors.positive;

    return Row(
      children: [
        Icon(
          isError
              ? PhosphorIcons.xCircle(PhosphorIconsStyle.fill)
              : PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
          size: 13,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          message,
          style: TextStyle(
            fontSize: AppTypography.micro,
            fontWeight: AppTypography.wMedium,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Banner
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final ColorScheme cs;
  final bool isLight;

  const _InfoBanner({required this.cs, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isLight ? 0.06 : 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isLight ? 0.15 : 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              PhosphorIcons.info(),
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'You may need to log in again after updating your password.',
              style: TextStyle(
                fontSize: AppTypography.micro,
                fontWeight: AppTypography.wRegular,
                color: AppColors.primary.withValues(alpha: 0.85),
                height: AppTypography.lhNormal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final disabledColor = color.withOpacity(0.3);
    final textColor = isDisabled
        ? AppColors.whiteUtility.withOpacity(0.6)
        : AppColors.whiteUtility;

    return Opacity(
      opacity: isDisabled ? 0.7 : 1.0, // 👈 subtle fade
      child: GestureDetector(
        onTap: isDisabled || isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: AppDurations.xShort,
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: isDisabled ? disabledColor : color,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: color.withOpacity(0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.whiteUtility,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: AppTypography.wSemibold,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Success Snackbar
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorSnackBarContent extends StatelessWidget {
  final String message;

  const _ErrorSnackBarContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessSnackBarContent extends StatelessWidget {
  final String message;

  const _SuccessSnackBarContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isLight ? AppColors.neutralDark : cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.positive.withValues(alpha: 0.30)),
        boxShadow: AppShadows.e3(cs),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            decoration: BoxDecoration(
              color: AppColors.positive.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 17,
              color: AppColors.positive,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppTypography.caption,
                fontWeight: AppTypography.wMedium,
                color: isLight ? AppColors.whiteUtility : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
