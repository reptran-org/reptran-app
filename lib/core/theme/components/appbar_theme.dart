import 'package:flutter/material.dart';
import '../../constants/tokens.dart';

AppBarTheme buildAppBarTheme(ColorScheme scheme) {
  return AppBarTheme(
    backgroundColor: scheme.surface,
    foregroundColor: scheme.onSurface,
    elevation: 0,
    centerTitle: true,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      fontSize: AppTypography.title,
      height: AppTypography.lhNormal,
      fontWeight: AppTypography.wSemibold,
      color: scheme.onSurface.withValues(alpha: AppOpacities.primary),
    ),
  );
}
