import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import 'company_login_screen.dart';
import 'login_screen.dart';

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  int? _pressedIndex;

  void _onRoleSelected(int index) {
    if (index == 0) {
   
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    } else {
      // Company -> CompanyLoginScreen (Email / Password)
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const CompanyLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }
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
        backgroundColor: const Color(0xFFFBFBFC),
        body: Stack(
          children: [
            // Background with organic corner curves
            Positioned.fill(
              child: Image.asset(
                'assets/choose_role_bg.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),

            // Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 28),

                              // FlowHire Logo
                              _buildLogo(),

                              const SizedBox(height: 36),

                              // "Choose your role" Title
                              Text(
                                'Choose your role',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF071D3E),
                                  letterSpacing: -0.6,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Subtitle
                              Text(
                                'Select how you want to get started today',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B788E),
                                  height: 1.35,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Role Card 1: Job Seeker (Blue theme)
                              _buildRoleCard(
                                index: 0,
                                title: 'Job Seeker',
                                description:
                                    'Your next job is just a tap away. Explore verified site work & assured wages.',
                                imageAsset: 'assets/role_job_seeker.png',
                                cardBgColor: const Color(0xFFF0F7FE),
                                cardBorderColor: const Color(0xFFD2E5FC),
                                waveColor: const Color(0xFFA2D1FD),
                                buttonBgColor: const Color(0xFFD8E9FE),
                                arrowColor: AppColors.primary,
                                onTap: () => _onRoleSelected(0),
                              ),

                              const SizedBox(height: 18),

                              // Role Card 2: Company (Yellow theme)
                              _buildRoleCard(
                                index: 1,
                                title: 'Company',
                                description:
                                    'Your next skilled crew is ready. Hire verified tradesmen & manage site hiring.',
                                imageAsset: 'assets/role_company.png',
                                cardBgColor: AppColors.companySurface,
                                cardBorderColor: AppColors.companyBorder,
                                waveColor: AppColors.companyWave,
                                buttonBgColor: AppColors.companyButtonBg,
                                arrowColor: AppColors.companyPrimary,
                                onTap: () => _onRoleSelected(1),
                              ),

                              const Spacer(),

                              const SizedBox(height: 24),

                              // Footer note about the app
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'FlowHire • Your next job, your next crew, all in one place.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
            children: const [
              TextSpan(
                text: 'Flow',
                style: TextStyle(
                  color: Color(0xFF071D3E),
                ),
              ),
              TextSpan(
                text: 'Hire',
                style: TextStyle(
                  color: Color(0xFFF5A623),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Workforce Recruitment',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B788E),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required int index,
    required String title,
    required String description,
    required String imageAsset,
    required Color cardBgColor,
    required Color cardBorderColor,
    required Color waveColor,
    required Color buttonBgColor,
    required Color arrowColor,
    required VoidCallback onTap,
  }) {
    final isPressed = _pressedIndex == index;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) => setState(() => _pressedIndex = null),
      onTapCancel: () => setState(() => _pressedIndex = null),
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 144),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cardBorderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: cardBorderColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.5),
            child: Stack(
              children: [
                // Inner bottom-right organic wave
                Positioned(
                  right: 0,
                  bottom: 0,
                  width: 170,
                  height: 80,
                  child: CustomPaint(
                    painter: _CardCornerWavePainter(color: waveColor),
                  ),
                ),

                // Card content row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 3D Illustration
                      SizedBox(
                        width: 104,
                        height: 104,
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Title & Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF071D3E),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF6B788E),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Arrow Button
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: buttonBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: arrowColor,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the smooth organic wave in the bottom-right corner of the role card
class _CardCornerWavePainter extends CustomPainter {
  final Color color;

  const _CardCornerWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // Starts at the bottom left of the wave canvas, curves smoothly up and to the right edge
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.1,
      size.width,
      size.height * 0.45,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CardCornerWavePainter oldDelegate) =>
      oldDelegate.color != color;
}
