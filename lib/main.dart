import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const BuildHireApp(),
    ),
  );
}

/// Root App
class BuildHireApp extends StatelessWidget {
  const BuildHireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildHire',
      debugShowCheckedModeBanner: false,

      // Required for device_preview to work correctly
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      theme: AppTheme.build(context),
      home: const LoginScreen(),
    );
  }
}
