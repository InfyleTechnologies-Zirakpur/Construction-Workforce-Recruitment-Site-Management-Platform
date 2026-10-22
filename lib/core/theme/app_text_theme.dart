import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
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
      // Splash brand title ("FlowHire") — kept at 36, no +2
      headlineMedium: GoogleFonts.poppins(
        fontSize: context.sp(36),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      // AppBar title / section headers ("Browse by Trade", "Latest Job Postings")
      titleLarge: GoogleFonts.poppins(
        fontSize: context.sp(22),
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: context.sp(18),
        fontWeight: FontWeight.bold,
      ),
      // Job card title / form field labels
      titleSmall: GoogleFonts.poppins(
        fontSize: context.sp(17),
        fontWeight: FontWeight.bold,
      ),
      // Hero subtitle, general body copy, button labels
      bodyMedium: GoogleFonts.roboto(fontSize: context.sp(15)),
      // Splash tagline ("Skilled people. Real work.")
      bodyLarge: GoogleFonts.roboto(
        fontSize: context.sp(16),
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
      // Job company, location, tags, trade names, helper text
      bodySmall: GoogleFonts.roboto(
        fontSize: context.sp(14.5),
        color: Colors.black54,
      ),
      // Stat numbers
      labelLarge: GoogleFonts.roboto(
        fontWeight: FontWeight.bold,
        fontSize: context.sp(20),
      ),
      // Badge labels, splash badge text ("Workforce Recruitment & Site Platform")
      labelMedium: GoogleFonts.roboto(
        fontSize: context.sp(13.5),
        fontWeight: FontWeight.w600,
        color: AppColors.peachText,
        letterSpacing: 0.2,
      ),
      // Timestamps, small captions, footer notes
      labelSmall: GoogleFonts.roboto(
        fontSize: context.sp(14),
        color: Colors.black38,
      ),
    );
  }
}

/// Centralized text styles for the entire app. Screens should call these
/// static methods instead of hardcoding fontSize values inline.
///
/// All sizes were bumped +2 from the original design (except headers).
/// To change a font size globally, update only this file.
class AppTextStyles {
  AppTextStyles._();

  // ─── Headers ────────────────────────────────────────────────────────

  /// 28sp - Hero / splash brand heading (NOT +2, kept as header)
  static TextStyle heroHeading(BuildContext context) => TextStyle(
        fontSize: context.sp(28),
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.5,
      );

  /// 26sp - Large profile name / prominent heading
  static TextStyle headingXL(BuildContext context) => TextStyle(
        fontSize: context.sp(26),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  /// 24sp - AppBar brand title ("FlowHire"), kept as header
  static TextStyle appBarTitle(BuildContext context) => TextStyle(
        fontSize: context.sp(24),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  /// 22sp - Large section heading / wage amount
  static TextStyle heading22(BuildContext context) => TextStyle(
        fontSize: context.sp(22),
        fontWeight: FontWeight.bold,
      );

  // ─── Titles ─────────────────────────────────────────────────────────

  /// 20sp - Section titles ("Personal Details", "Documents") (was 18 +2)
  static TextStyle sectionTitle(BuildContext context) => TextStyle(
        fontSize: context.sp(20),
        fontWeight: FontWeight.w700,
      );

  /// 18sp - Sheet/dialog titles (was 16 +2)
  static TextStyle sheetTitle(BuildContext context) => TextStyle(
        fontSize: context.sp(18),
        fontWeight: FontWeight.w700,
      );

  /// 17sp - Card title / job title (was 15 +2)
  static TextStyle cardTitle(BuildContext context) => TextStyle(
        fontSize: context.sp(17),
        fontWeight: FontWeight.w700,
      );

  /// 16sp - Stat numbers, mid-emphasis labels (was 14 +2)
  static TextStyle statNumber(BuildContext context) => TextStyle(
        fontSize: context.sp(16),
        fontWeight: FontWeight.bold,
      );

  // ─── Body ───────────────────────────────────────────────────────────

  /// 15sp - Primary body text, button labels (was 13 +2)
  static TextStyle body(BuildContext context) => TextStyle(
        fontSize: context.sp(15),
      );

  /// 15sp - Semibold body text, field labels (was 13 +2)
  static TextStyle bodySemiBold(BuildContext context) => TextStyle(
        fontSize: context.sp(15),
        fontWeight: FontWeight.w600,
      );

  /// 14.5sp - Secondary body text (was 12.5 +2)
  static TextStyle bodySecondary(BuildContext context) => TextStyle(
        fontSize: context.sp(14.5),
        color: AppColors.textSecondary,
      );

  /// 14sp - Detail/info text, input text (was 12 +2)
  static TextStyle detail(BuildContext context) => TextStyle(
        fontSize: context.sp(14),
      );

  /// 14sp - Detail text with muted color
  static TextStyle detailMuted(BuildContext context) => TextStyle(
        fontSize: context.sp(14),
        color: AppColors.textMuted,
      );

  // ─── Captions & Labels ──────────────────────────────────────────────

  /// 13.5sp - Badge / tag label (was 11.5 +2)
  static TextStyle badge(BuildContext context) => TextStyle(
        fontSize: context.sp(13.5),
        fontWeight: FontWeight.w600,
      );

  /// 13sp - Caption text, timestamps (was 11 +2)
  static TextStyle caption(BuildContext context) => TextStyle(
        fontSize: context.sp(13),
        color: AppColors.textMuted,
      );

  /// 12sp - Tiny caption, trade subtitles (was 10 +2)
  static TextStyle captionSmall(BuildContext context) => TextStyle(
        fontSize: context.sp(12),
        color: AppColors.textMuted,
      );
}
