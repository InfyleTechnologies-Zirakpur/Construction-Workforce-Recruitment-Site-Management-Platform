import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/utils/responsive.dart';
import '../../features/repositories/company_repository.dart';
import '../company/company_profile_form_screen.dart';

class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  State<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends State<CompanyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _pass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = CompanyRepository();
      final data = await repo.registerCompany(
        fullName: _fullName.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
      );

      const storage = FlutterSecureStorage();

      if (data['accessToken'] != null) {
        await storage.write(key: 'accessToken', value: data['accessToken'].toString());
      }
      if (data['refreshToken'] != null) {
        await storage.write(key: 'refreshToken', value: data['refreshToken'].toString());
      }
      await storage.write(key: 'role', value: 'company');

      // Persist userId & companyName from registration response
      final user = data['user'] ?? data['company'] ?? data;
      if (user is Map) {
        if (user['id'] != null) await storage.write(key: 'userId', value: user['id'].toString());
        final compName = user['companyName']?.toString() ??
            user['name']?.toString() ??
            user['fullName']?.toString() ??
            _fullName.text.trim();
        if (compName.isNotEmpty) {
          await storage.write(key: 'companyName', value: compName);
        }
      } else {
        if (_fullName.text.trim().isNotEmpty) {
          await storage.write(key: 'companyName', value: _fullName.text.trim());
        }
      }
      NotificationService.instance.syncDeviceToken();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account Created! Please complete your company profile details.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CompanyProfileFormScreen(
            isInitialSetup: true,
            initialEmail: _email.text.trim(),
            initialName: _fullName.text.trim(),
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = ApiErrorParser.extractMessage(
        e,
        fallback: 'Unable to register company account. Please check your details.',
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background building/crane graphic extending behind logo & titles
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
                // Top Navigation Bar
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
                        'Company Sign Up',
                        style: TextStyle(
                          fontSize: 18,
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

                        // Title: Create Employer Account
                        Text(
                          'Create Employer Account',
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
                          'Register your company to post site requirements and hire verified skilled workers.',
                          style: TextStyle(
                            fontSize: context.sp(14),
                            color: const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: context.h(24)),

                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full Name / Contact Representative *
                              TextFormField(
                                controller: _fullName,
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1E2A38)),
                                decoration: InputDecoration(
                                  hintText: 'Full Name / Contact Representative *',
                                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
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
                                    borderSide: const BorderSide(color: Color(0xFFFA6400), width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                                  ),
                                  errorMaxLines: 2,
                                  errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Representative full name is required';
                                  }
                                  if (v.trim().length < 3) {
                                    return 'Please enter a valid full name (minimum 3 characters)';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: context.h(14)),

                              // Official Company Email *
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1E2A38)),
                                decoration: InputDecoration(
                                  hintText: 'Official Company Email *',
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
                                    borderSide: const BorderSide(color: Color(0xFFFA6400), width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                                  ),
                                  errorMaxLines: 2,
                                  errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Official company email is required';
                                  }
                                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                  if (!emailRegex.hasMatch(v.trim())) {
                                    return 'Please enter a valid email address (e.g. name@company.com)';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: context.h(14)),

                              // Password *
                              TextFormField(
                                controller: _pass,
                                obscureText: _obscurePass,
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1E2A38)),
                                decoration: InputDecoration(
                                  hintText: 'Password *',
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
                                    borderSide: const BorderSide(color: Color(0xFFFA6400), width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                                  ),
                                  errorMaxLines: 2,
                                  errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) {
                                    return 'Password must be at least 6 characters long';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: context.h(14)),

                              // Confirm Password *
                              TextFormField(
                                controller: _confirmPass,
                                obscureText: _obscureConfirm,
                                style: const TextStyle(fontSize: 15, color: Color(0xFF1E2A38)),
                                decoration: InputDecoration(
                                  hintText: 'Confirm Password *',
                                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF6B7280),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
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
                                    borderSide: const BorderSide(color: Color(0xFFFA6400), width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                                  ),
                                  errorMaxLines: 2,
                                  errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (v != _pass.text) {
                                    return 'Passwords do not match. Please verify your password.';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: context.h(20)),

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
                                            fontSize: 13,
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

                              // Create Account Button
                              SizedBox(
                                width: double.infinity,
                                height: context.h(52),
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFA6400),
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
                                          'Create Account',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: context.h(18)),

                              // Already registered? Sign In Link
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text.rich(
                                    TextSpan(
                                      text: 'Already registered? ',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Sign In',
                                          style: TextStyle(
                                            color: Color(0xFFFA6400),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
    );
  }
}
