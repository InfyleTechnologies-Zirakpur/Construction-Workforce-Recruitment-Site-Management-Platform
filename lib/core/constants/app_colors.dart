import 'package:flutter/material.dart';

/// Centralized color palette for the app. Pull colors from here instead of
/// hardcoding hex values in widgets, so a rebrand only touches one file.
class AppColors {
  AppColors._();

  /// Brand primary color (Blue for Job Seeker #1E75E8)
  static const Color primary = Color(0xFF1E75E8);

  /// Dark typography and prominent headers
  static const Color dark = Color(0xFF101828);

  /// App scaffold and surface background
  static const Color background = Color(0xFFF9FAFB);

  /// Card surface
  static const Color card = Colors.white;

  /// Secondary muted text
  static const Color textSecondary = Color(0xFF667085);

  /// Muted placeholders and icons
  static const Color textMuted = Color(0xFF98A2B3);

  /// Crisp card borders and dividers
  static const Color border = Color(0xFFEAECF0);

  /// Danger / error actions
  static const Color error = Color(0xFFD92D20);

  /// Success actions
  static const Color success = Color(0xFF16A34A);

  /// Blue accents
  static const Color blue = Color(0xFF007BFF);
  static const Color backgroundBlue = Color(0xFF007BFF);

  /// Job Seeker Soft Blue tag/surface accents (harmonized with primary #1E75E8)
  static const Color peachBackground = Color(0xFFEBF3FE);
  static const Color peachBorder = Color(0xFFBFDBFE);
  static const Color peachText = Color(0xFF1D4ED8);

  /// Centralized Company Brand Yellow / Amber Palette (#F7B532)
  static const Color companyPrimary = Color(0xFFF7B532);
  static const Color companyPrimaryDark = Color(0xFFD99B1E);
  static const Color companyPrimaryLight = Color(0xFFFFFBEB);
  static const Color companySurface = Color(0xFFFDF9EA);
  static const Color companyBorder = Color(0xFFFBE4B4);
  static const Color companyWave = Color(0xFFFFDF94);
  static const Color companyButtonBg = Color(0xFFFEEDC8);
  static const Color companyTagBackground = Color(0xFFFFFBEB);
  static const Color companyTagBorder = Color(0xFFFDE68A);
  static const Color companyTagText = Color(0xFFB45309);
}
