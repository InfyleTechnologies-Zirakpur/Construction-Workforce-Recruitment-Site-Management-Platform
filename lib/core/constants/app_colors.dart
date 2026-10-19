import 'package:flutter/material.dart';

/// Centralized color palette for the app. Pull colors from here instead of
/// hardcoding hex values in widgets, so a rebrand only touches one file.
class AppColors {
  AppColors._();

  /// Brand primary color (#F7B532)
  static const Color primary = Color(0xFFF7B532);

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

  /// Warm amber / gold tag accents (harmonized with primary #F7B532)
  static const Color peachBackground = Color(0xFFFFFBEB);
  static const Color peachBorder = Color(0xFFFDE68A);
  static const Color peachText = Color(0xFFB45309);
}
