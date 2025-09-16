import 'package:flutter/material.dart';
import '../../constants/tokens.dart';

ListTileThemeData buildListTileTheme(ColorScheme scheme) {
  return ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    iconColor: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
    textColor: scheme.onSurface.withValues(alpha: AppOpacities.primary),
    tileColor: scheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      side: AppBorders.sideOnePx(scheme), // ✅ theme-aware BorderSide
    ),
  );
}
