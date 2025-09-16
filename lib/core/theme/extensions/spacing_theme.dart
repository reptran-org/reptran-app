import 'package:flutter/material.dart';
import '../../constants/tokens.dart';
import 'dart:ui' show lerpDouble;

class SpacingTheme extends ThemeExtension<SpacingTheme> {
  final double xs, sm, md, lg, xl, xxl;

  const SpacingTheme({
    this.xs = AppSpacing.xs,
    this.sm = AppSpacing.sm,
    this.md = AppSpacing.md,
    this.lg = AppSpacing.lg,
    this.xl = AppSpacing.xl,
    this.xxl = AppSpacing.xxl,
  });

  @override
  SpacingTheme copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return SpacingTheme(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  SpacingTheme lerp(ThemeExtension<SpacingTheme>? other, double t) {
    if (other is! SpacingTheme) return this;
    return SpacingTheme(
      xs: lerpDouble(xs, other.xs, t) ?? xs,
      sm: lerpDouble(sm, other.sm, t) ?? sm,
      md: lerpDouble(md, other.md, t) ?? md,
      lg: lerpDouble(lg, other.lg, t) ?? lg,
      xl: lerpDouble(xl, other.xl, t) ?? xl,
      xxl: lerpDouble(xxl, other.xxl, t) ?? xxl,
    );
  }

  @override
  int get hashCode => Object.hash(xs, sm, md, lg, xl, xxl);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpacingTheme &&
          xs == other.xs &&
          sm == other.sm &&
          md == other.md &&
          lg == other.lg &&
          xl == other.xl &&
          xxl == other.xxl;
}

// Optional: handy context getter
extension SpacingX on BuildContext {
  SpacingTheme get spacing =>
      Theme.of(this).extension<SpacingTheme>() ?? const SpacingTheme();
}
