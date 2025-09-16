import 'package:flutter/material.dart';
import '../../constants/tokens.dart';

ChipThemeData buildChipTheme(ColorScheme scheme) {
  return ChipThemeData(
    backgroundColor: scheme.surface,
    selectedColor: scheme.secondary.withValues(alpha: 0.15),
    labelStyle: TextStyle(
      fontSize: AppTypography.caption,
      height: AppTypography.lhNormal,
      color: scheme.onSurface.withValues(alpha: AppOpacities.primary),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.xs),
      side: AppBorders.sideOnePx(scheme), // ✅ use BorderSide token
    ),
    side: AppBorders.sideOnePx(scheme), // ✅ use BorderSide token
    iconTheme: IconThemeData(
      color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
    ),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
  );
}
