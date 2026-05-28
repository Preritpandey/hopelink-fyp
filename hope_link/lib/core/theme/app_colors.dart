import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE5E5E5);
  static const Color grey300 = Color(0xFFD4D4D4);
  static const Color grey400 = Color(0xFFA3A3A3);
  static const Color grey500 = Color(0xFF737373);
  static const Color grey600 = Color(0xFF525252);
  static const Color grey700 = Color(0xFF404040);
  static const Color grey800 = Color(0xFF262626);
  static const Color grey900 = Color(0xFF171717);
  static const MaterialColor grey = Colors.grey;

  static const Color primary = Color(0xFF27AE60);
  static const Color primaryLight = Color(0xFF6FCF97);
  static const Color primaryDark = Color(0xFF1E8E55);
  static const Color primarySoft = Color(0xFFF4FBF6);
  static const Color primaryBackground = primarySoft;
  static const Color lightBackgroundPrimary = primarySoft;
  static const Color backgroundPrimary = primaryLight;

  static const Color accent = Color(0xFF5F8B4C);
  static const Color accentLight = Color(0xFF87B56E);
  static const Color accentDark = Color(0xFF2F5D50);

  static const Color background = Color(0xFFFAF6F1);
  static const Color surface = white;
  static const Color cardBackground = white;
  static const Color surfaceVariant = Color(0xFFF6F6F6);
  static const Color mutedSurface = Color(0xFFF2F2F7);
  static const Color inputFill = Color(0xFFF8F9FB);

  static const Color textPrimary = Color(0xFF2D2016);
  static const Color textSecondary = Color(0xFF6B5344);
  static const Color textMuted = Color(0xFF9B8578);
  static const Color textBackground = Color(0xFFD9D9D9);

  static const Color divider = Color(0xFFEDE5DC);
  static const Color shimmer = Color(0xFFEDE5DC);
  static const Color borderSubtle = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD4D4D4);

  static const Color starColor = Color(0xFFE8A838);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFF4CC);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorColor = error;
  static const Color success = Color(0xFF5F8B4C);
  static const Color successColor = success;
  static const Color info = Color(0xFF2D9CDB);

  static const MaterialColor blue = Colors.blue;
  static const Color blueLight = Color(0xFFBEE3F8);
  static const Color blueDark = Color(0xFF1E5AA8);

  static const MaterialColor green = Colors.green;
  static const Color greenLight = primaryLight;
  static const Color greenDark = primaryDark;

  static const MaterialColor orange = Colors.orange;
  static const Color orangeLight = Color(0xFFF2C89B);
  static const Color orangeDark = Color(0xFFA46745);

  static const MaterialColor red = Colors.red;
  static const Color redLight = Color(0xFFD59A9D);
  static const Color redDark = Color(0xFFB5453C);
  static const Color redAccent = Color(0xFFE53E3E);

  static const MaterialColor amber = Colors.amber;
  static const Color amberLight = Color(0xFFFCE7D7);

  static const MaterialColor purple = Colors.purple;
  static const Color purpleLight = Color(0xFFD8B4FE);

  static const MaterialColor teal = Colors.teal;
  static const Color tealLight = Color(0xFF99F6E4);

  static const Color black87 = Color(0xDE000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black12 = Color(0x1F000000);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white60 = Color(0x99FFFFFF);

  static const Color shadow = Color(0x14B85C38);
  static const Color overlayLight = Color(0x33000000);
  static const Color overlayMedium = Color(0x88000000);
}

enum AppColorToken {
  textBackground(AppColors.textBackground),
  transparent(AppColors.transparent),
  white(AppColors.white),
  grey(AppColors.grey),
  error(AppColors.error),
  lightGrey(AppColors.surfaceVariant),
  black(AppColors.black),
  primary(AppColors.primary),
  backgroundPrimary(AppColors.backgroundPrimary),
  lightBackgroundPrimary(AppColors.lightBackgroundPrimary),
  lightGreyAccent(AppColors.grey500);

  final Color color;
  const AppColorToken(this.color);
}

extension AppColorTokenExtension on AppColorToken {
  Color get value => color;

  Color getOpacity(double opacity) => color.withOpacity(opacity);
}

extension AppGradients on AppColorToken {
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryDark,
      AppColors.primary,
      AppColors.primaryLight,
    ],
  );
}
