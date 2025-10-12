import 'package:flutter/material.dart';

enum AppColorToken {
  textBackground(Color(0xffD9D9D9)),
  lightGreyAccent(Color(0xff6E6E6E));

  final Color color;
  const AppColorToken(this.color);
}

extension AppColorTokenExtension on AppColorToken {
  Color get value => color;

  Color getOpacity(double opacity) => color.withValues(alpha: opacity);
}
