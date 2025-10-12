import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hope_link/core/theme/app_colors.dart';

class AppTextStyle {
  AppTextStyle._();

  static final _baseStyle = GoogleFonts.outfit();

  static TextStyle size(double fontSize) {
    return _baseStyle.copyWith(fontSize: fontSize);
  }

  static TextStyle dp(double fontSize) {
    return _baseStyle.copyWith(fontSize: fontSize);
  }

  static TextStyle sp(double fontSize) {
    return _baseStyle.copyWith(fontSize: fontSize);
  }

  // Common text sizes using sizer
  static TextStyle get h1 => dp(24);
  static TextStyle get h2 => dp(20);
  static TextStyle get h3 => dp(18);
  static TextStyle get h4 => dp(16);
  static TextStyle get h5 => dp(14);
  static TextStyle get h6 => dp(12);

  static TextStyle get bodyLarge => dp(16);
  static TextStyle get bodyMedium => dp(14);
  static TextStyle get bodySmall => dp(12);

  static TextStyle get labelLarge => dp(14);
  static TextStyle get labelMedium => dp(12);
  static TextStyle get labelSmall => dp(10);

  static TextStyle get caption => dp(10);
  static TextStyle get overline => dp(8);
}

extension TextStyleWeightExtension on TextStyle {
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
}

extension TextStyleColorExtension on TextStyle {
  TextStyle withColor(AppColorToken token) => copyWith(color: token.color);
}

class TextStyleBuilder {
  final TextStyle _style;

  TextStyleBuilder(this._style);

  TextStyle call(AppColorToken token) => _style.withColor(token);
}

extension TextStyleUsageExtension on TextStyle {
  TextStyle get outFitFont =>
      copyWith(fontFamily: GoogleFonts.outfit().fontFamily);
  TextStyleBuilder get color => TextStyleBuilder(this);
}
