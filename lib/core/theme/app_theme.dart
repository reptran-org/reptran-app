import 'package:flutter/material.dart';
import '../constants/tokens.dart';
import 'schemes.dart';
import 'text_theme.dart';
import 'extensions/spacing_theme.dart';

// components
import 'components/appbar_theme.dart';
import 'components/button_themes.dart';
import 'components/card_theme.dart';
import 'components/chip_theme.dart';
import 'components/divider_theme.dart';
import 'components/icon_theme.dart';
import 'components/input_theme.dart';
import 'components/list_tile_theme.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = lightScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.neutralLight,
      textTheme: buildTextTheme(scheme),
      fontFamily: 'Inter',
      appBarTheme: buildAppBarTheme(scheme),
      cardTheme: buildCardTheme(scheme),
      elevatedButtonTheme: buildElevatedButtonTheme(scheme),
      outlinedButtonTheme: buildOutlinedButtonTheme(scheme),
      textButtonTheme: buildTextButtonTheme(scheme),
      inputDecorationTheme: buildInputDecorationTheme(scheme),
      chipTheme: buildChipTheme(scheme),
      iconTheme: buildIconTheme(scheme),
      listTileTheme: buildListTileTheme(scheme),
      dividerTheme: buildDividerTheme(scheme),

      extensions: const [SpacingTheme()],
    );
  }

  static ThemeData dark() {
    final scheme = darkScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.neutralDark,
      textTheme: buildTextTheme(scheme),

      appBarTheme: buildAppBarTheme(scheme),
      cardTheme: buildCardTheme(scheme),
      elevatedButtonTheme: buildElevatedButtonTheme(scheme),
      outlinedButtonTheme: buildOutlinedButtonTheme(scheme),
      textButtonTheme: buildTextButtonTheme(scheme),
      inputDecorationTheme: buildInputDecorationTheme(scheme),
      chipTheme: buildChipTheme(scheme),
      iconTheme: buildIconTheme(scheme),
      listTileTheme: buildListTileTheme(scheme),
      dividerTheme: buildDividerTheme(scheme),

      extensions: const [SpacingTheme()],
    );
  }
}
