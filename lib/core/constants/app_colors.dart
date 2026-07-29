import 'package:flutter/material.dart';

/// Centralized color palette for the app. Pull colors from here instead of
/// hardcoding hex values in widgets, so a rebrand only touches one file.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFF7A00); // construction orange
  static const Color dark = Color(0xFF1E2A38); // steel navy
  static const Color background = Color(0xFFF4F5F7);

  static const Color textSecondary = Colors.black54;
  static const Color textMuted = Colors.black38;
  static const Color border = Colors.black12;
  static const Color error = Color(0xFFD32F2F);
}
