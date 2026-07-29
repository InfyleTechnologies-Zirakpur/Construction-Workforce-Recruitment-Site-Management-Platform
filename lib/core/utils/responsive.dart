import 'package:flutter/material.dart';

/// Lightweight responsive scaling helper — no external package required.
///
/// All sizes in the design were built against a 375x812 baseline (a typical
/// phone screen). On other screen sizes we scale proportionally, clamped so
/// text/spacing never gets absurdly small (tiny phones) or huge (tablets).
class AppResponsive {
  AppResponsive._();

  static const double _designWidth = 375;
  static const double _designHeight = 812;

  /// Scale factor derived from screen width, clamped to a sane range.
  static double _widthScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width / _designWidth).clamp(0.85, 1.30);
  }

  static double _heightScale(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return (height / _designHeight).clamp(0.85, 1.30);
  }

  /// Scaled font size — use for every TextStyle fontSize in the app.
  static double sp(BuildContext context, double size) =>
      size * _widthScale(context);

  /// Scaled horizontal spacing / width.
  static double w(BuildContext context, double size) =>
      size * _widthScale(context);

  /// Scaled vertical spacing / height.
  static double h(BuildContext context, double size) =>
      size * _heightScale(context);

  /// True when the current width looks like a tablet (>= 600 logical px).
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;
}

/// Sugar so call sites can write `context.sp(14)` instead of
/// `AppResponsive.sp(context, 14)`.
extension ResponsiveContext on BuildContext {
  double sp(double size) => AppResponsive.sp(this, size);
  double w(double size) => AppResponsive.w(this, size);
  double h(double size) => AppResponsive.h(this, size);
  bool get isTablet => AppResponsive.isTablet(this);
}
