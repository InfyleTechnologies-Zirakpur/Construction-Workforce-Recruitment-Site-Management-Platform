import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/utils/responsive.dart';
import '../../features/repositories/worker_repository.dart';
import '../home/home_page.dart';
import '../profile/complete_profile_screen.dart';
import 'company_login_screen.dart';
import 'job_seeker_register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  String? _contactError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Mobile number is required';
    }
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (!RegExp(r'^[0-9]+$').hasMatch(digits) || digits.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    if (!RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }
    return null;
  }

  Future<void> _handlePasswordLogin() async {
    final pErr = _validatePhone(_contactController.text);
    final pass = _passwordController.text;
    String? passErr;
    if (pass.isEmpty) {
      passErr = 'Password is required';
    } else if (pass.length < 6) {
      passErr = 'Password must be at least 6 characters';
    }

    setState(() {
      _contactError = pErr;
      _passwordError = passErr;
      _generalError = null;
    });

    if (pErr != null || passErr != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoggingIn = true);

    try {
      final phone = _contactController.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
      final repo = WorkerRepository();
      final data = await repo.loginWithPassword(phone: phone, password: pass);

      final accessToken = data['accessToken']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Login failed. Please check your phone number and password.');
      }

      ApiClient.accessToken = accessToken;
      ApiClient.instance.dio.options.headers['Authorization'] = 'Bearer $accessToken';

      const storageEncrypted = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      const storagePlain = FlutterSecureStorage();

      await storageEncrypted.write(key: 'accessToken', value: accessToken);
      await storagePlain.write(key: 'accessToken', value: accessToken);
      if (data['refreshToken'] != null) {
        await storageEncrypted.write(key: 'refreshToken', value: data['refreshToken'].toString());
        await storagePlain.write(key: 'refreshToken', value: data['refreshToken'].toString());
      }
      await storageEncrypted.write(key: 'role', value: 'job_seeker');
      await storagePlain.write(key: 'role', value: 'job_seeker');
      await storageEncrypted.write(key: 'phone', value: phone);
      await storagePlain.write(key: 'phone', value: phone);

      final user = data['user'] ?? data['worker'];
      bool profileCompleted = false;
      if (user is Map) {
        if (user['id'] != null) {
          await storageEncrypted.write(key: 'userId', value: user['id'].toString());
          await storagePlain.write(key: 'userId', value: user['id'].toString());
        }
        if (user['fullName'] != null && user['fullName'].toString().isNotEmpty) {
          await storageEncrypted.write(key: 'name', value: user['fullName'].toString());
          await storagePlain.write(key: 'name', value: user['fullName'].toString());
        }
        if (user['email'] != null && user['email'].toString().isNotEmpty) {
          await storageEncrypted.write(key: 'email', value: user['email'].toString());
          await storagePlain.write(key: 'email', value: user['email'].toString());
        }
      }

      // Authoritative server flag (present on OTP + password login responses).
      bool? serverFlag;
      if (data['isProfileComplete'] is bool) {
        serverFlag = data['isProfileComplete'] as bool;
      } else if (data['profileCompleted'] is bool) {
        serverFlag = data['profileCompleted'] as bool;
      } else if (data['isNewUser'] is bool) {
        serverFlag = !(data['isNewUser'] as bool);
      } else if (user is Map) {
        if (user['isProfileComplete'] is bool) {
          serverFlag = user['isProfileComplete'] as bool;
        } else if (user['profileCompleted'] is bool) {
          serverFlag = user['profileCompleted'] as bool;
        } else if (user['isNewUser'] is bool) {
          serverFlag = !(user['isNewUser'] as bool);
        }
      }

      if (serverFlag != null) {
        profileCompleted = serverFlag;
        await storageEncrypted.write(key: 'profileCompleted', value: serverFlag.toString());
        await storagePlain.write(key: 'profileCompleted', value: serverFlag.toString());
        await storageEncrypted.write(key: 'profileComplete', value: serverFlag.toString());
        await storagePlain.write(key: 'profileComplete', value: serverFlag.toString());
      } else {
        if (user is Map &&
            user['city'] != null &&
            user['city'].toString().isNotEmpty &&
            user['city'] != 'Delhi') {
          profileCompleted = true;
        }
        if (!profileCompleted) {
          profileCompleted = (await storagePlain.read(key: 'profileCompleted')) == 'true' ||
              (await storageEncrypted.read(key: 'profileCompleted')) == 'true';
        }
        if (profileCompleted) {
          await storageEncrypted.write(key: 'profileCompleted', value: 'true');
          await storagePlain.write(key: 'profileCompleted', value: 'true');
        }
      }

      NotificationService.instance.syncDeviceToken();

      if (!mounted) return;
      setState(() => _isLoggingIn = false);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => profileCompleted
              ? const HomePage()
              : CompleteProfileScreen(phoneNumber: phone),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingIn = false;
        _generalError = ApiErrorParser.extractMessage(
          e,
          fallback: 'Invalid credentials. Please check your details and try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141B),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 60;
          final screenHeight = constraints.maxHeight;
          final fullHeight = MediaQuery.sizeOf(context).height;
          final headerHeight = isKeyboardOpen
              ? 110.0
              : (fullHeight * 0.40).clamp(290.0, 380.0);

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // TOP HERO HEADER
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeInOut,
                      height: headerHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/worker_bg.jpg',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.65),
                                  Colors.black.withOpacity(0.25),
                                  Colors.black.withOpacity(0.75),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(24),
                                vertical: context.h(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Image.asset(
                                        'assets/logo_worker.png',
                                        width: isKeyboardOpen ? context.w(36) : context.w(48),
                                        height: isKeyboardOpen ? context.w(36) : context.w(48),
                                        fit: BoxFit.contain,
                                      ),
                                      IconButton(
                                        onPressed: () => Navigator.maybePop(context),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isKeyboardOpen) ...[
                                    const Spacer(),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Find your \n',
                                        style: TextStyle(
                                          fontSize: context.sp(26),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.15,
                                          letterSpacing: -0.5,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: 'next site job.',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: context.h(6)),
                                    Text(
                                      'Log in to browse site jobs, track applications & get hired.',
                                      style: TextStyle(
                                        fontSize: context.sp(14),
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                    SizedBox(height: context.h(12)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BOTTOM WHITE CARD SHEET
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          context.w(24),
                          context.h(24),
                          context.w(24),
                          context.h(20),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // GENERAL ERROR BANNER
                              if (_generalError != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFCA5A5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _generalError!,
                                          style: const TextStyle(
                                            color: Color(0xFF991B1B),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: context.h(14)),
                              ],

                              // PHONE NUMBER BLANK (NO COUNTRY CODE)
                              TextFormField(
                                controller: _contactController,
                                keyboardType: TextInputType.text,
                                maxLength: 10,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E2A38),
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'Phone Number or Email *',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 14.5,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.phone_android_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 19,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                                  ),
                                  errorText: _contactError,
                                  errorMaxLines: 2,
                                  errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 11.5),
                                ),
                                onChanged: (val) {
                                  if (_contactError != null) {
                                    setState(() => _contactError = _validatePhone(val));
                                  }
                                },
                              ),
                              SizedBox(height: context.h(14)),

                              // PASSWORD
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E2A38),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Password *',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF6B7280),
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                                  ),
                                  errorText: _passwordError,
                                  errorMaxLines: 2,
                                  errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                                ),
                                onChanged: (val) {
                                  if (_passwordError != null && val.isNotEmpty) {
                                    setState(() => _passwordError = null);
                                  }
                                },
                              ),
                              SizedBox(height: context.h(8)),

                              // FORGOT PASSWORD
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ResetPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.h(22)),

                              // LOGIN WITH PASSWORD BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: context.h(52),
                                child: ElevatedButton(
                                  onPressed: _isLoggingIn ? null : _handlePasswordLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoggingIn
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : const Text(
                                          'Log In',
                                          style: TextStyle(
                                            fontSize: 17.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: context.h(20)),

                              // SIGN UP LINK (Directly opens Page 1: Name, Phone, Skill)
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const JobSeekerRegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text.rich(
                                    TextSpan(
                                      text: "Don't have an account? ",
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 16,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Sign Up',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // COMPANY PORTAL LINK
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CompanyLoginScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    'Company login with email',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
