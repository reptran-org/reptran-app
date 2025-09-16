import 'package:flutter/material.dart';
import '../../constants/tokens.dart';

InputDecorationTheme buildInputDecorationTheme(ColorScheme scheme) {
  OutlineInputBorder outlined(BorderSide side) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: side,
  );

  return InputDecorationTheme(
    filled: true,
    fillColor: scheme.surface,
    hintStyle: TextStyle(
      fontSize: AppTypography.caption,
      height: AppTypography.lhNormal,
      color: scheme.onSurface.withValues(alpha: AppOpacities.tertiary),
    ),
    labelStyle: TextStyle(
      fontSize: AppTypography.caption,
      height: AppTypography.lhNormal,
      color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
      fontWeight: AppTypography.wMedium,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: 14,
    ),

    // ✅ use theme-aware BorderSide tokens
    enabledBorder: outlined(AppBorders.sideOnePx(scheme)),
    focusedBorder: outlined(AppBorders.sideFocus(scheme)),
    errorBorder: outlined(AppBorders.sideError(scheme)),
    focusedErrorBorder: outlined(AppBorders.sideError(scheme)),
    disabledBorder: outlined(AppBorders.sideDisabled(scheme)),
  );
}
