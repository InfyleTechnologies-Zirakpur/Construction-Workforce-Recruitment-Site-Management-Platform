import 'package:construction_workforce_recruitment_site_management_platform/core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/utils/responsive.dart';
import '../company/company_home_screen.dart';
import '../company/company_profile_form_screen.dart';
import '../../features/repositories/company_repository.dart';
import 'company_register_screen.dart';
import 'reset_password_screen.dart';

class CompanyLoginScreen extends StatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  State<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<CompanyLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  bool _rememberMe = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = CompanyRepository();
      final data = await repo.loginCompany(
        email: _email.text.trim(),
        password: _pass.text,
      );

      final accessToken = data['accessToken']?.toString();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Login failed: No access token received from server.');
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
        final refresh = data['refreshToken'].toString();
        await storageEncrypted.write(key: 'refreshToken', value: refresh);
        await storagePlain.write(key: 'refreshToken', value: refresh);
      }

      await storageEncrypted.write(key: 'role', value: 'company');
      await storagePlain.write(key: 'role', value: 'company');
      await storageEncrypted.write(key: 'email', value: _email.text.trim());
      await storagePlain.write(key: 'email', value: _email.text.trim());

      final user = data['user'] ?? data['company'] ?? data;
      String compName = '';
      if (user is Map) {
        if (user['isBlocked'] == true) {
          throw Exception('This company account has been blocked. Please contact support.');
        }

        final role = user['role']?.toString();
        if (role != null && role != 'company' && role != 'admin') {
          throw Exception('This account is registered as a $role. Please login via the job seeker login.');
        }

        if (user['id'] != null) {
          final uid = user['id'].toString();
          await storageEncrypted.write(key: 'userId', value: uid);
          await storagePlain.write(key: 'userId', value: uid);
        }

        compName = user['companyName']?.toString() ??
            user['businessName']?.toString() ??
            user['name']?.toString() ??
            user['fullName']?.toString() ??
            '';
        if (compName.isNotEmpty) {
          await storageEncrypted.write(key: 'companyName', value: compName);
          await storagePlain.write(key: 'companyName', value: compName);
        }
      }

      // Check profile completeness per backend specification
      bool profileComplete = false;
      if (data['isProfileComplete'] == true ||
          (user is Map && (user['profileCompleted'] == true || user['isProfileComplete'] == true))) {
        profileComplete = true;
      }

   
      if (!profileComplete) {
        try {
          final uid = user is Map ? user['id']?.toString() : null;
          final existingProfile = await repo.getCompanyByUserId(uid);
          if (existingProfile != null && existingProfile['id'] != null) {
            profileComplete = true;
            final existingName = existingProfile['name']?.toString() ?? compName;
            if (existingName.isNotEmpty) {
              await storageEncrypted.write(key: 'companyName', value: existingName);
              await storagePlain.write(key: 'companyName', value: existingName);
            }
          }
        } catch (_) {}
      }

      await storageEncrypted.write(key: 'profileCompleted', value: profileComplete.toString());
      await storagePlain.write(key: 'profileCompleted', value: profileComplete.toString());
      await storageEncrypted.write(key: 'isProfileComplete', value: profileComplete.toString());
      await storagePlain.write(key: 'isProfileComplete', value: profileComplete.toString());

      NotificationService.instance.syncDeviceToken();

      if (!mounted) return;
      if (profileComplete) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CompanyHomeScreen()),
          (_) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => CompanyProfileFormScreen(
              isInitialSetup: true,
              initialEmail: _email.text.trim(),
              initialName: compName,
            ),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() => _error = ApiErrorParser.extractMessage(
        e,
        fallback: 'Invalid email or password. Please verify your credentials.',
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.companyTheme(context),
      child: Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background building graphic extending behind logo & titles
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: context.h(290),
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.black, Colors.transparent],
                  stops: [0.0, 0.75, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  'assets/company_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topRight,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(16),
                    vertical: context.h(8),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.arrow_back, color: Color(0xFF1E2A38), size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Company Login',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2A38),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: context.w(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: context.h(16)),

                        // Company Brand Logo
                        Image.asset(
                          'assets/logo_company.png',
                          width: context.w(62),
                          height: context.w(62),
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: context.h(22)),

                        // Title
                        Text(
                          'Hire workers faster',
                          style: TextStyle(
                            fontSize: context.sp(28),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: context.h(8)),

                        // Subtitle
                        Text(
                          'Sign in with your company email to manage jobs, applications and more.',
                          style: TextStyle(
                            fontSize: context.sp(16),
                            color: const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: context.h(28)),

                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email Input
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(fontSize: 17, color: Color(0xFF1E2A38)),
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 20,
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
                                    borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                                  ),
                                ),
                                validator: (v) {
                                  final email = v?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return 'Email address is required';
                                  }
                                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                  if (!emailRegex.hasMatch(email)) {
                                    return 'Enter a valid email address (e.g. name@company.com)';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: context.h(14)),

                              // Password Input
                              TextFormField(
                                controller: _pass,
                                obscureText: _obscurePass,
                                style: const TextStyle(fontSize: 17, color: Color(0xFF1E2A38)),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF6B7280),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
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
                                    borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),


                              SizedBox(height: context.h(14)),

                              // Remember Me & Forgot Password Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                          activeColor: const Color(0xFF1E2A38),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          side: const BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Remember me',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF374151),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Company forgot-password = email OTP flow.
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ResetPasswordScreen(initialMethod: 'email'),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.companyPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.h(16)),

                              if (_error != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _error!.toLowerCase().contains('internet') ||
                                                _error!.toLowerCase().contains('connection') ||
                                                _error!.toLowerCase().contains('server') ||
                                                _error!.toLowerCase().contains('network') ||
                                                _error!.toLowerCase().contains('timed out')
                                            ? Icons.wifi_off_rounded
                                            : Icons.error_outline_rounded,
                                        color: const Color(0xFFDC2626),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Color(0xFF991B1B),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: context.h(16)),
                              ],

                              // Sign In Button
                              SizedBox(
                                width: double.infinity,
                                height: context.h(52),
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.companyPrimary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: context.h(18)),

                              // Sign Up Link
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CompanyRegisterScreen(),
                                    ),
                                  ),
                                  child: const Text.rich(
                                    TextSpan(
                                      text: "Don't have a company account? ",
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 16,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Sign Up',
                                          style: TextStyle(
                                            color: AppColors.companyPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.h(12)),

                              // Back to seeker login Link
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Back to seeker login',
                                    style: TextStyle(
                                      color: AppColors.companyPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: context.h(24)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
