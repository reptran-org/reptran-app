import 'package:flutter/material.dart';
import '../constants/tokens.dart';

TextTheme buildTextTheme(ColorScheme scheme) {
  final base = scheme.onSurface;
  return TextTheme(
    displaySmall: TextStyle(
      fontSize: AppTypography.display,
      height: AppTypography.lhLoose,
      fontWeight: AppTypography.wBold,
      color: base.withValues(alpha: AppOpacities.primary),
    ),
    headlineSmall: TextStyle(
      fontSize: AppTypography.heading,
      height: AppTypography.lhLoose,
      fontWeight: AppTypography.wBold,
      color: base.withValues(alpha: AppOpacities.primary),
    ),
    titleMedium: TextStyle(
      fontSize: AppTypography.title,
      height: AppTypography.lhNormal,
      fontWeight: AppTypography.wSemibold,
      color: base.withValues(alpha: AppOpacities.secondary),
    ),
    bodyMedium: TextStyle(
      fontSize: AppTypography.body,
      height: AppTypography.lhNormal,
      fontWeight: AppTypography.wRegular,
      color: base.withValues(alpha: AppOpacities.primary),
    ),
    bodySmall: TextStyle(
      fontSize: AppTypography.caption,
      height: AppTypography.lhNormal,
      fontWeight: AppTypography.wRegular,
      color: base.withValues(alpha: AppOpacities.secondary),
    ),
    labelSmall: TextStyle(
      fontSize: AppTypography.micro,
      height: AppTypography.lhTight,
      fontWeight: AppTypography.wMedium,
      color: base.withValues(alpha: AppOpacities.tertiary),
    ),
  );
}
