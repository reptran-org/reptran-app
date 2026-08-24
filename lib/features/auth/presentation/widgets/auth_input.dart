import 'package:flutter/material.dart';

import 'package:reptran_app/core/constants/tokens.dart';

class AuthInput extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
   final FocusNode? focusNode; 

  const AuthInput({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
     this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        focusNode: focusNode, 
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.sm,
            ),
            child: Icon(
              icon,
              size: 22,
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: suffix,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
          ),
          filled: true,
          fillColor: scheme.surface,

          // Normal / unfocused border
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            borderSide: BorderSide(color: scheme.outline, width: 1),
          ),

          // Focused border
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),

          // When there's an error but not focused
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            borderSide: BorderSide(color: scheme.error, width: 1),
          ),

          // When there's an error and the field is focused
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            borderSide: BorderSide(color: scheme.error, width: 2),
          ),

          // Generic border fallback
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            borderSide: BorderSide(color: scheme.outline, width: 1),
          ),

          // Optional: style the error text if you want
          errorStyle: TextStyle(color: scheme.error),
          errorMaxLines: 2,
        ),
      ),
    );
  }
}
