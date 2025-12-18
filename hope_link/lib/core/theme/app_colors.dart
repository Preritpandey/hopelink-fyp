import 'package:flutter/material.dart';

enum AppColorToken {
  textBackground(Color(0xffD9D9D9)),
  white(Color(0xFFFFFFFF)),
  grey(Colors.grey),
  error(Color(0xFFE74C3C)),
  lightGrey(Color(0xffF6F6F6)),
  black(Color(0xFF000000)),
  primary(Color(0XFF27AE60)),
  backgroundPrimary(Color(0xFF6FCF97)),
  lightBackgroundPrimary(Color(0xFFF4FBF6)),
  lightGreyAccent(Color(0xff6E6E6E));

  final Color color;
  const AppColorToken(this.color);
}

extension AppColorTokenExtension on AppColorToken {
  Color get value => color;

  Color getOpacity(double opacity) => color.withOpacity(opacity);
}

///  GRADIENT EXTENSION
extension AppGradients on AppColorToken {
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E8E55), // Darker Green shade
      Color(0xFF27AE60), // Primary Green
      Color(0xFF6FCF97), // Accent Green
    ],
  );
}
