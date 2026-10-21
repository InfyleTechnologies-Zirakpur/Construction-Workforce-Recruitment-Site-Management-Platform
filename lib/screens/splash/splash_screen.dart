import 'dart:async';
import 'package:construction_workforce_recruitment_site_management_platform/core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/services/notification_service.dart';
import '../auth/choose_role_screen.dart';
import '../company/company_home_screen.dart';
import '../home/home_page.dart';
import '../profile/complete_profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final stopwatch = Stopwatch()..start();

    const storage = FlutterSecureStorage();

    bool isLoggedIn = false;
    bool isCompany = false;
    bool profileCompleted = false;
    String? phone;

    try {
      String? token = await storage.read(key: 'accessToken');
      String? role = await storage.read(key: 'role');
      phone = await storage.read(key: 'phone');
      profileCompleted = (await storage.read(key: 'profileCompleted')) == 'true';

      if (token == null || token.isEmpty) {
        const encryptedStorage = FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );
        token = await encryptedStorage.read(key: 'accessToken');
        role ??= await encryptedStorage.read(key: 'role');
        phone ??= await encryptedStorage.read(key: 'phone');
        profileCompleted = profileCompleted ||
            (await encryptedStorage.read(key: 'profileCompleted')) == 'true';
      }
      isLoggedIn = token != null && token.isNotEmpty;
      isCompany = role == 'company';
      if (isLoggedIn) {
        ApiClient.accessToken = token;
        NotificationService.instance.syncDeviceToken();
      }
    } catch (_) {
      isLoggedIn = false;
      isCompany = false;
    }

    // Keep splash visible for 2.2 seconds for a smooth branded experience
    final elapsed = stopwatch.elapsedMilliseconds;
    final remaining = 2200 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted) return;

    final Widget targetScreen = isLoggedIn
        ? (isCompany
            ? const CompanyHomeScreen()
            : (profileCompleted
                ? const HomePage(initialNavIndex: 0)
                : CompleteProfileScreen(phoneNumber: phone ?? '')))
        : const ChooseRoleScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SizedBox.expand(
            child: Image.asset(
              'assets/splash_screen_full.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
