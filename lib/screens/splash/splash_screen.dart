import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/responsive.dart';
import '../auth/login_screen.dart';
import '../company/company_home_screen.dart';
import '../home/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curved);

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

    try {
      final token = await storage.read(key: 'accessToken');
      final role = await storage.read(key: 'role');
      isLoggedIn = token != null && token.isNotEmpty;
      isCompany = role == 'company';
      if (isLoggedIn) {
        NotificationService.instance.syncDeviceToken();
      }
    } catch (_) {
      isLoggedIn = false;
      isCompany = false;
    }

    // Ensure the splash screen stays visible for at least 2 seconds
    // to give a smooth, branded entrance experience without flickering.
    final elapsed = stopwatch.elapsedMilliseconds;
    final remaining = 2000 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted) return;

    final Widget targetScreen = isLoggedIn
        ? (isCompany
            ? const CompanyHomeScreen()
            : const HomePage(initialNavIndex: 0))
        : const LoginScreen();

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
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFFDF5),
                AppColors.background,
                Color(0xFFF3F4F6),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Subtle background ambient glow top right
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // Subtle background ambient glow bottom left
              Positioned(
                bottom: -80,
                left: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Main Centered Content
              SafeArea(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(28),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(flex: 3),

                              // App Logo Badge
                              Container(
                                width: context.w(96),
                                height: context.w(96),
                                padding: EdgeInsets.all(context.w(12)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(context.w(24)),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.22),
                                      blurRadius: 28,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(context.w(16)),
                                  child: Image.asset(
                                    'assets/appLogo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      'assets/logo_worker.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, st) => Icon(
                                        Icons.construction_rounded,
                                        size: context.w(48),
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: context.h(20)),

                              // Header Design: Flow (Dark) + Hire (Primary Gold #F7B532)
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Flow',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: AppColors.dark,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Hire',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: context.h(6)),

                              // Tagline from Header
                              Text(
                                'Skilled people. Real work.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),

                              SizedBox(height: context.h(12)),

                              // Subtitle Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(14),
                                  vertical: context.h(6),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.peachBackground,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.engineering_rounded,
                                      size: context.sp(16),
                                      color: AppColors.peachText,
                                    ),
                                    SizedBox(width: context.w(6)),
                                    Text(
                                      'Workforce Recruitment & Site Platform',
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(flex: 3),

                              // Bottom Loading Spinner
                              SizedBox(
                                width: context.w(26),
                                height: context.w(26),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),

                              SizedBox(height: context.h(16)),

                              // Footer note
                              Text(
                                'Connecting workers & construction sites',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),

                              SizedBox(height: context.h(20)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
