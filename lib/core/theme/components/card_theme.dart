import 'package:flutter/material.dart';
import '../../constants/tokens.dart';

CardThemeData buildCardTheme(ColorScheme scheme) {
  return CardThemeData(
    color: scheme.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      side: BorderSide(color: scheme.outline, width: 1),
    ),
  );
}
