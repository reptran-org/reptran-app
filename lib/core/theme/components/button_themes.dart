import 'package:flutter/material.dart';
import '../../constants/tokens.dart';

ElevatedButtonThemeData buildElevatedButtonTheme(ColorScheme scheme) {
  return ElevatedButtonThemeData(
    style: ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.primary.withValues(alpha: 0.5);
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.all(scheme.onPrimary),
      elevation: WidgetStateProperty.all(0),
    ),
  );
}

TextButtonThemeData buildTextButtonTheme(ColorScheme scheme) {
  return TextButtonThemeData(
    style: ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
      ),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: AppOpacities.disabled);
        }
        return scheme.primary;
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    ),
  );
}

OutlinedButtonThemeData buildOutlinedButtonTheme(ColorScheme scheme) {
  return OutlinedButtonThemeData(
    style: ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppBorders.sideDisabled(scheme);
        }
        return AppBorders.sideOnePx(scheme);
      }),

      foregroundColor: WidgetStateProperty.all(scheme.primary),
      elevation: WidgetStateProperty.all(0),
    ),
  );
}
