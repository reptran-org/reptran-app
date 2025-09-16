import 'package:flutter/material.dart';

IconThemeData buildIconTheme(ColorScheme scheme) {
  return IconThemeData(
    color: scheme.onSurface.withValues(alpha: 1.0),
    size: 24,
  );
}
