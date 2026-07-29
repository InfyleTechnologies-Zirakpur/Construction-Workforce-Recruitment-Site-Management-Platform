import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive.dart';

/// Builds the app's TextTheme with sizes scaled per-device via
/// [AppResponsive]. Keep every named style here — screens should read
/// styles from `Theme.of(context).textTheme`, never hardcode a TextStyle.
class AppTextTheme {
  AppTextTheme._();

  static TextTheme build(BuildContext context, TextTheme base) {
    final robotoBase = GoogleFonts.robotoTextTheme(base);

    return robotoBase.copyWith(
      // Hero heading ("Find skilled workers...")
      headlineSmall: GoogleFonts.poppins(
        fontSize: context.sp(24),
        fontWeight: FontWeight.bold,
        height: 1.3,
        color: Colors.white,
      ),
      // AppBar title / section headers ("Browse by Trade", "Latest Job Postings")
      titleLarge: GoogleFonts.poppins(
        fontSize: context.sp(20),
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: context.sp(16),
        fontWeight: FontWeight.bold,
      ),
      // Job card title / form field labels
      titleSmall: GoogleFonts.poppins(
        fontSize: context.sp(15),
        fontWeight: FontWeight.bold,
      ),
      // Hero subtitle, general body copy, button labels
      bodyMedium: GoogleFonts.roboto(fontSize: context.sp(13)),
      // Job company, location, tags, trade names, helper text
      bodySmall: GoogleFonts.roboto(
        fontSize: context.sp(12.5),
        color: Colors.black54,
      ),
      // Stat numbers
      labelLarge: GoogleFonts.roboto(
        fontWeight: FontWeight.bold,
        fontSize: context.sp(18),
      ),
      // Timestamps, small captions
      labelSmall: GoogleFonts.roboto(
        fontSize: context.sp(11),
        color: Colors.black38,
      ),
    );
  }
}
