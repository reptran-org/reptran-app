import 'package:flutter/material.dart';
import '../constants/tokens.dart';

final lightScheme = ColorScheme.light(
  primary: AppColors.primary,
  onPrimary: AppColors.whiteUtility,
  secondary: AppColors.secondary,
  onSecondary: AppColors.whiteUtility,
  tertiary: AppColors.accent,
  onTertiary: AppColors.whiteUtility,
  surface: AppColors.whiteUtility,
  onSurface: AppColors.neutralDark,
  error: const Color(0xFFB00020),
  onError: AppColors.whiteUtility,
  outline: AppColors.whiteBorder,
);

final darkScheme = ColorScheme.dark(
  primary: AppColors.primary,
  onPrimary: AppColors.whiteUtility,
  secondary: AppColors.secondary,
  onSecondary: AppColors.whiteUtility,
  tertiary: AppColors.accent,
  onTertiary: AppColors.whiteUtility,
  surface: AppColors.blackUtility,
  onSurface: AppColors.neutralLight,
  error: const Color(0xFFCF6679),
  onError: AppColors.whiteUtility,
  outline: AppColors.blackBorder,
);
