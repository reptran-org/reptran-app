import 'package:flutter/material.dart';

/// =============================================================
/// RepTran — Design Tokens (raw values only)
/// Used by app_theme.dart to build ThemeData.
/// =============================================================

/// Brand & neutral colors
class AppColors {
  // Brand
  static const primary = Color(0xFF0F6F6E);
  static const primaryDark = Color(0xFF0A5655);
  static const secondary = Color(0xFF38BFB2);
  static const accent = Color(0xFFFF6B5A);
  static const accentDark = Color(0xFFE55A4A);
  static const positive = Color(0xFF4CD964);

  // Neutral
  static const neutralDark = Color(0xFF1E1E1E);
  static const neutralLight = Color(0xFFF8F9FA);

  // Utility
  static const whiteUtility = Color(0xFFFFFFFF);
  static const whiteBorder = Color(0xFFE9ECEF);
  static const blackUtility = Color(0xFF2A2A2A);
  static const blackBorder = Color(0xFF404040);
}

/// Spacing (8pt grid)
class AppSpacing {
  static const xxs = 4.0; // tight: heading→subheading, icon→text
  static const xs = 8.0; // tight: heading→subheading, icon→text
  static const sm = 16.0; // related items: option→option, input→input
  static const md = 24.0; // section gaps: heading→content, input→button
  static const lg = 32.0; // strong separation: info→CTA
  static const xl = 40.0; // large blocks (rare)
  static const xxl = 48.0; // page framing top/bottom
}

/// Corner radii
class AppRadii {
  static const xs = 4.0; // chips, tags, subtle UI
  static const sm = 8.0; // small elements, inputs
  static const md = 12.0; // buttons, focused inputs
  static const lg = 16.0; // cards
  static const xl = 24.0; // larger cards, illustrations
  static const xxl = 32.0; // modals, big surfaces
  static const full = 999.0; // pills/circles
}

class AppShadows {
  static const e0 = <BoxShadow>[];

  static List<BoxShadow> e1(ColorScheme scheme) => [
    BoxShadow(
      offset: const Offset(0, 1),
      blurRadius: 2,
      color: scheme.brightness == Brightness.light
          ? Colors.black.withValues(alpha: 0.05) // ~5%
          : Colors.white.withValues(alpha: 0.10), // ~10%
    ),
  ];

  static List<BoxShadow> e2(ColorScheme scheme) => [
    BoxShadow(
      offset: const Offset(0, 2),
      blurRadius: 6,
      color: scheme.brightness == Brightness.light
          ? Colors.black.withValues(alpha: 0.08) // ~8%
          : Colors.white.withValues(alpha: 0.12), // ~12%
    ),
  ];

  static List<BoxShadow> e3(ColorScheme scheme) => [
    BoxShadow(
      offset: const Offset(0, 4),
      blurRadius: 12,
      color: scheme.brightness == Brightness.light
          ? Colors.black.withValues(alpha: 0.12) // ~12%
          : Colors.white.withValues(alpha: 0.14), // ~14%
    ),
  ];

  static List<BoxShadow> e4(ColorScheme scheme) => [
    BoxShadow(
      offset: const Offset(0, 8),
      blurRadius: 24,
      color: scheme.brightness == Brightness.light
          ? Colors.black.withValues(alpha: 0.18) // ~18%
          : Colors.white.withValues(alpha: 0.16), // ~16%
    ),
  ];

  static List<BoxShadow> button(ColorScheme scheme) => [
    BoxShadow(
      offset: const Offset(0, 4),
      blurRadius: 16,
      // Slightly stronger in dark to read against darker bg
      color: AppColors.accent.withValues(
        alpha: scheme.brightness == Brightness.light ? 0.25 : 0.30,
      ),
    ),
  ];
}

/// Opacities for text hierarchy (applied to neutralDark)
class AppOpacities {
  static const primary = 1.0; // headings, body
  static const secondary = 0.60; // subheads, metadata
  static const tertiary = 0.40; // helper text, placeholders
  static const disabled = 0.20; // disabled states
}

/// Typography scale (sizes in px, line-heights as multiple)
class AppTypography {
  // Font sizes
  static const display = 28.0; // big headings
  static const heading = 22.0; // section headings
  static const title = 18.0; // sub-section titles, button labels
  static const body = 16.0; // main body text
  static const caption = 14.0; // helper text, metadata
  static const micro = 12.0; // footnotes, input hints

  // Line heights (unitless multipliers)
  static const lhTight = 1.2; // headings, labels
  static const lhNormal = 1.4; // body text
  static const lhLoose = 1.6; // large headings, relaxed sections

  // Weights
  static const wBold = FontWeight.w700;
  static const wSemibold = FontWeight.w600;
  static const wMedium = FontWeight.w500;
  static const wRegular = FontWeight.w400;
  static const wLight = FontWeight.w300;
}

/// Motion / durations
class AppDurations {
  static const xShort = Duration(milliseconds: 120); // taps, micro
  static const short = Duration(milliseconds: 200); // small fades/slide
  static const medium = Duration(milliseconds: 300); // standard UI anims
  static const long = Duration(milliseconds: 450); // page transitions
  static const xLong = Duration(milliseconds: 600); // staged/staggered

  // Commonly used for staggering child animations
  static const stagger = Duration(milliseconds: 100);
}

class AppAnimation {
  // Duration used for subtle UI micro-interactions (buttons, chips, etc.)
  static const Duration microInteraction = Duration(milliseconds: 120);

  // How much the button scales when pressed (1.0 = normal).
  // 0.96 is a subtle press-in effect. Change to taste.
  static const double pressScale = 0.96;
}

/// Z-indices (semantic layering; higher = on top)
class AppZ {
  static const base = 0; // normal content
  static const raised = 10; // cards
  static const fab = 50; // floating buttons
  static const overlay = 100; // dropdowns, popovers
  static const navigation = 900; // app bars, drawers
  static const modal = 1000; // dialogs
  static const loader = 1500; // global loaders/spinners
  static const toast = 2000; // toasts/snackbars
}

/// Utility helpers for consistent borders
class AppBorders {
  // 🔹 BorderSide tokens (for buttons, inputs, etc.)
  static BorderSide sideOnePx(ColorScheme scheme) =>
      BorderSide(color: scheme.outline, width: 1);

  static BorderSide sideDisabled(ColorScheme scheme) => BorderSide(
    color: scheme.onSurface.withValues(alpha: AppOpacities.disabled),
    width: 1,
  );

  static BorderSide sideFocus(ColorScheme scheme) =>
      BorderSide(color: scheme.primary, width: 2);

  static BorderSide sideError(ColorScheme scheme) =>
      BorderSide(color: scheme.error, width: 2);

  // 🔹 Full BoxBorder tokens (for containers/cards)
  static Border boxOnePx(ColorScheme scheme) =>
      Border.all(color: scheme.outline, width: 1);

  static Border boxCard(ColorScheme scheme) =>
      Border.all(color: scheme.outline, width: 1);
}

class AppScale {
  static double _scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final rawScale = width / 375;

    return rawScale.clamp(0.9, 1.1);
  }

  static double s(BuildContext context, double size) {
    return size * _scaleFactor(context);
  }

  static double t(BuildContext context, double size) {
    final scale = _scaleFactor(context).clamp(0.95, 1.1);
    return size * scale;
  }
}