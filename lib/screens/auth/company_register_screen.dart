import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/utils/responsive.dart';
import '../../features/repositories/company_repository.dart';
import '../company/company_profile_form_screen.dart';
import 'company_login_screen.dart';

/// Company Multi-Step Signup Screen implementing the official Backend Auth flow:
/// Step 1: Send OTP to Email (POST /auth/signup/company/send-otp)
/// Step 2: Verify 6-digit OTP (POST /auth/signup/company/verify-otp) -> receives signupToken
/// Step 3: Set Strong Password (POST /auth/signup/company/set-password) -> receives accessToken/refreshToken
/// Step 4: Transitions seamlessly to CompanyProfileFormScreen (POST /companies)
class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  State<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends State<CompanyRegisterScreen> {
  final _repo = CompanyRepository();
  int _step = 0; // 0 = Info, 1 = Verify OTP, 2 = Set Password

  // Step 1 Controllers & State
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _step1FormKey = GlobalKey<FormState>();

  // Step 2 Controllers & State
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 30;
  final _otpCtrl = TextEditingController();
  final _otpFocusNode = FocusNode();
  Timer? _resendTimer;
  int _secondsLeft = _resendCooldownSeconds;
  String? _signupToken;

  // Step 3 Controllers & State
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _step3FormKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Real-time password rules
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  bool _loading = false;
  bool _isVerifyingOtp = false;
  String? _error;
  bool _isConflictEmail = false;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(_evaluatePassword);
    _otpCtrl.addListener(_onOtpChanged);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    _passCtrl.removeListener(_evaluatePassword);
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _evaluatePassword() {
    final text = _passCtrl.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(text);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(text);
      _hasDigit = RegExp(r'\d').hasMatch(text);
      _hasSpecialChar = RegExp(r'[^\da-zA-Z]').hasMatch(text);
    });
  }

  void _onOtpChanged() {
    final text = _otpCtrl.text.trim();
    if (text.length == _otpLength && !_loading && !_isVerifyingOtp && _step == 1) {
      _verifyOtp();
    }
    setState(() {});
  }

  void _startResendTimer() {
    _secondsLeft = _resendCooldownSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  // ===================== STEP 1: SEND OTP =====================
  Future<void> _sendOtp({bool isResend = false}) async {
    if (!isResend && !_step1FormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _isConflictEmail = false;
    });

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    try {
      final res = await _repo.sendCompanySignupOtp(
        name: name,
        email: email,
      );

      final inner = (res['data'] is Map) ? Map<String, dynamic>.from(res['data']) : <String, dynamic>{};
      final merged = {...res, ...inner};

      final otpSent = merged['otpSent'] == true || merged['success'] == true;
      if (otpSent) {
        setState(() {
          _step = 1;
          _otpCtrl.clear();
          _error = null;
        });
        _startResendTimer();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _otpFocusNode.requestFocus();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(merged['message']?.toString() ?? 'OTP sent to your email'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        setState(() => _error = merged['message']?.toString() ?? 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      final msg = ApiErrorParser.extractMessage(e, fallback: 'Failed to send verification code.');
      final isConflict = msg.toLowerCase().contains('already registered') ||
          msg.toLowerCase().contains('conflict') ||
          msg.toLowerCase().contains('login');
      setState(() {
        _error = msg;
        _isConflictEmail = isConflict;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===================== STEP 2: VERIFY OTP =====================
  Future<void> _verifyOtp() async {
    if (_loading || _isVerifyingOtp) return;

    final otp = _otpCtrl.text.trim();
    if (otp.length != _otpLength) {
      setState(() => _error = 'Please enter the complete 6-digit verification code.');
      return;
    }

    _isVerifyingOtp = true;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _isConflictEmail = false;
    });

    final email = _emailCtrl.text.trim();

    try {
      final res = await _repo.verifyCompanySignupOtp(
        email: email,
        otp: otp,
      );

      final inner = (res['data'] is Map) ? Map<String, dynamic>.from(res['data']) : <String, dynamic>{};
      final merged = {...res, ...inner};

      final verified = merged['verified'] == true ||
          merged['emailVerified'] == true ||
          merged['success'] == true;
      final token = merged['signupToken']?.toString();

      if (verified && token != null && token.isNotEmpty) {
        _signupToken = token;
        _resendTimer?.cancel();
        setState(() {
          _step = 2;
          _error = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified! Please set your secure password.'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() => _error = merged['message']?.toString() ?? 'Invalid or expired OTP. Please check and retry.');
      }
    } catch (e) {
      final msg = ApiErrorParser.extractMessage(e, fallback: 'Invalid or expired OTP.');
      setState(() => _error = msg);
    } finally {
      _isVerifyingOtp = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===================== STEP 3: SET PASSWORD =====================
  Future<void> _setPassword() async {
    if (!_step3FormKey.currentState!.validate()) return;

    if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasDigit || !_hasSpecialChar) {
      setState(() => _error = 'Please fulfill all password strength requirements.');
      return;
    }

    if (_signupToken == null || _signupToken!.isEmpty) {
      setState(() => _error = 'Verification session expired. Please verify your email again.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    try {
      final data = await _repo.setCompanySignupPassword(
        signupToken: _signupToken!,
        password: _passCtrl.text,
        confirmPassword: _confirmPassCtrl.text,
      );

      final accessToken = data['accessToken']?.toString() ??
          (data['data'] is Map ? data['data']['accessToken']?.toString() : null);
      final refreshToken = data['refreshToken']?.toString() ??
          (data['data'] is Map ? data['data']['refreshToken']?.toString() : null);

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Password set, but no session token was received.');
      }

      // Configure ApiClient for authenticated profile setup
      ApiClient.accessToken = accessToken;
      ApiClient.instance.dio.options.headers['Authorization'] = 'Bearer $accessToken';

      // Persist session tokens (dual storage: encrypted + plain for maximum compatibility)
      const storageEncrypted = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      const storagePlain = FlutterSecureStorage();

      await storageEncrypted.write(key: 'accessToken', value: accessToken);
      await storagePlain.write(key: 'accessToken', value: accessToken);

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await storageEncrypted.write(key: 'refreshToken', value: refreshToken);
        await storagePlain.write(key: 'refreshToken', value: refreshToken);
      }

      await storageEncrypted.write(key: 'role', value: 'company');
      await storagePlain.write(key: 'role', value: 'company');
      await storageEncrypted.write(key: 'email', value: email);
      await storagePlain.write(key: 'email', value: email);
      await storageEncrypted.write(key: 'emailVerified', value: 'true');
      await storagePlain.write(key: 'emailVerified', value: 'true');
      await storageEncrypted.write(key: 'profileCompleted', value: 'false');
      await storagePlain.write(key: 'profileCompleted', value: 'false');
      await storageEncrypted.write(key: 'isProfileComplete', value: 'false');
      await storagePlain.write(key: 'isProfileComplete', value: 'false');

      final user = data['user'] ?? (data['data'] is Map ? data['data']['user'] : null);
      if (user is Map && user['id'] != null) {
        final uid = user['id'].toString();
        await storageEncrypted.write(key: 'userId', value: uid);
        await storagePlain.write(key: 'userId', value: uid);
      }

      if (name.isNotEmpty) {
        await storageEncrypted.write(key: 'companyName', value: name);
        await storagePlain.write(key: 'companyName', value: name);
      }

      NotificationService.instance.syncDeviceToken();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account verified! Complete your company profile details.'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Route directly to CompanyProfileFormScreen (isInitialSetup: true)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CompanyProfileFormScreen(
            isInitialSetup: true,
            initialEmail: email,
            initialName: name,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      final msg = ApiErrorParser.extractMessage(e, fallback: 'Failed to set password. Please try again.');
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===================== UI BUILDERS =====================

  Widget _buildStepProgressBar() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepIndicator(0, 'Company Info', Icons.business_rounded),
            _buildStepConnector(0),
            _buildStepIndicator(1, 'Verify Email', Icons.mark_email_read_rounded),
            _buildStepConnector(1),
            _buildStepIndicator(2, 'Set Password', Icons.lock_rounded),
          ],
        ),
        SizedBox(height: context.h(16)),
      ],
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, IconData icon) {
    final bool isCompleted = _step > stepIndex;
    final bool isCurrent = _step == stepIndex;

    Color badgeBg;
    Color iconColor;
    Color textColor;

    if (isCompleted) {
      badgeBg = const Color(0xFF16A34A);
      iconColor = Colors.white;
      textColor = const Color(0xFF16A34A);
    } else if (isCurrent) {
      badgeBg = AppColors.companyPrimary;
      iconColor = Colors.white;
      textColor = AppColors.companyPrimary;
    } else {
      badgeBg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF94A3B8);
      textColor = const Color(0xFF94A3B8);
    }

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: context.w(36),
            height: context.w(36),
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.companyPrimary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                  : Icon(icon, color: iconColor, size: 18),
            ),
          ),
          SizedBox(height: context.h(6)),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.sp(11.5),
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int leftStep) {
    final isDone = _step > leftStep;
    return Container(
      width: context.w(28),
      height: 2.5,
      margin: EdgeInsets.only(bottom: context.h(20)),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildErrorBanner() {
    if (_error == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: EdgeInsets.only(bottom: context.h(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (_isConflictEmail) ...[
            SizedBox(height: context.h(10)),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const CompanyLoginScreen()),
                  );
                },
                icon: const Icon(Icons.login_rounded, size: 16),
                label: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.companyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===================== STEP 1 VIEW =====================
  Widget _buildStep1Info() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company / Contact Name *',
            style: TextStyle(
              fontSize: context.sp(14),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E2A38),
            ),
          ),
          SizedBox(height: context.h(6)),
          TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 16, color: Color(0xFF1E2A38)),
            decoration: InputDecoration(
              hintText: 'e.g. Tudoo Constructions',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14.5),
              prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF6B7280), size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5)),
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return 'Company / Contact name is required';
              if (s.length < 2) return 'Enter a valid company name (minimum 2 characters)';
              return null;
            },
          ),
          SizedBox(height: context.h(16)),

          Text(
            'Official Company Email *',
            style: TextStyle(
              fontSize: context.sp(14),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E2A38),
            ),
          ),
          SizedBox(height: context.h(6)),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 16, color: Color(0xFF1E2A38)),
            decoration: InputDecoration(
              hintText: 'company@example.com',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14.5),
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF6B7280), size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5)),
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return 'Official email address is required';
              final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
              if (!regex.hasMatch(s)) return 'Enter a valid email address';
              return null;
            },
          ),
          SizedBox(height: context.h(14)),

          // Helper info badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.companySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.companyBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.companyPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'We will send a 6-digit verification code to this email (valid for 10 minutes).',
                    style: TextStyle(
                      fontSize: context.sp(12.5),
                      color: const Color(0xFF1E40AF),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(22)),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: context.h(52),
            child: ElevatedButton(
              onPressed: _loading ? null : () => _sendOtp(isResend: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.companyPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Send Verification Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
          SizedBox(height: context.h(18)),

          // Already have account
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CompanyLoginScreen()),
                );
              },
              child: const Text.rich(
                TextSpan(
                  text: 'Already registered? ',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 15.5),
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(color: AppColors.companyPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(20)),
        ],
      ),
    );
  }

  // ===================== STEP 2 VIEW: 6-DIGIT OTP =====================
  Widget _buildStep2Otp() {
    final email = _emailCtrl.text.trim();
    final otpText = _otpCtrl.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Destination Card with Edit Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.companyPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.email_rounded, color: AppColors.companyPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification code sent to',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 15.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _step = 0;
                    _error = null;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(color: AppColors.companyPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(24)),

        Center(
          child: Text(
            'Enter 6-Digit Code',
            style: TextStyle(fontSize: context.sp(15), fontWeight: FontWeight.w700, color: const Color(0xFF1E2A38)),
          ),
        ),
        SizedBox(height: context.h(14)),

        // 6 Custom Box Cells backed by hidden keyboard input
        Stack(
          children: [
            // Visual digit cells
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_otpLength, (index) {
                final isFilled = index < otpText.length;
                final isCurrent = index == otpText.length;
                final char = isFilled ? otpText[index] : '';

                return Container(
                  width: context.w(46),
                  height: context.h(54),
                  decoration: BoxDecoration(
                    color: isFilled ? const Color(0xFFF8FAFC) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.companyPrimary
                          : (isFilled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                      width: isCurrent ? 2 : 1.2,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.companyPrimary.withOpacity(0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      char,
                      style: TextStyle(
                        fontSize: context.sp(22),
                        fontWeight: FontWeight.w800,
                        color: AppColors.companyPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Actual invisible textfield capturing keyboard and paste events
            Positioned.fill(
              child: Opacity(
                opacity: 0.0,
                child: TextField(
                  controller: _otpCtrl,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_otpLength),
                  ],
                  autofocus: true,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(20)),

        // Resend Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  _secondsLeft > 0
                      ? 'Resend code in 00:${_secondsLeft.toString().padLeft(2, '0')}'
                      : 'Code expired?',
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
            TextButton(
              onPressed: (_secondsLeft == 0 && !_loading) ? () => _sendOtp(isResend: true) : null,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Resend OTP',
                style: TextStyle(
                  color: _secondsLeft == 0 ? AppColors.companyPrimary : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(24)),

        // Verify Button
        SizedBox(
          width: double.infinity,
          height: context.h(52),
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.companyPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : const Text('Verify Email & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ),
        ),
        SizedBox(height: context.h(14)),

        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _step = 0),
            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF64748B)),
            label: const Text('Back to Company Info', style: TextStyle(color: Color(0xFF64748B), fontSize: 14.5)),
          ),
        ),
        SizedBox(height: context.h(20)),
      ],
    );
  }

  // ===================== STEP 3 VIEW: STRONG PASSWORD =====================
  Widget _buildStep3Password() {
    final email = _emailCtrl.text.trim();

    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Verified Green Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verified: $email',
                    style: const TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(18)),

          Text(
            'New Password *',
            style: TextStyle(
              fontSize: context.sp(14),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E2A38),
            ),
          ),
          SizedBox(height: context.h(6)),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            style: const TextStyle(fontSize: 16, color: Color(0xFF1E2A38)),
            decoration: InputDecoration(
              hintText: 'Create a strong password',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14.5),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6B7280), size: 20),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          SizedBox(height: context.h(12)),

          // Dynamic Password Requirements Checklist
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password Requirements:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
                SizedBox(height: context.h(6)),
                _buildRuleItem('At least 8 characters long', _hasMinLength),
                _buildRuleItem('At least one uppercase letter (A-Z)', _hasUppercase),
                _buildRuleItem('At least one lowercase letter (a-z)', _hasLowercase),
                _buildRuleItem('At least one number (0-9)', _hasDigit),
                _buildRuleItem('At least one special character (!@#\$%^&*)', _hasSpecialChar),
              ],
            ),
          ),
          SizedBox(height: context.h(16)),

          Text(
            'Confirm Password *',
            style: TextStyle(
              fontSize: context.sp(14),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E2A38),
            ),
          ),
          SizedBox(height: context.h(6)),
          TextFormField(
            controller: _confirmPassCtrl,
            obscureText: _obscureConfirm,
            style: const TextStyle(fontSize: 16, color: Color(0xFF1E2A38)),
            decoration: InputDecoration(
              hintText: 'Re-enter your password',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14.5),
              prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF6B7280), size: 20),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          SizedBox(height: context.h(24)),

          // Complete Registration Button
          SizedBox(
            width: double.infinity,
            height: context.h(52),
            child: ElevatedButton(
              onPressed: _loading ? null : _setPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.companyPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Text('Complete Registration & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
          ),
          SizedBox(height: context.h(14)),

          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _step = 1),
              icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF64748B)),
              label: const Text('Back to OTP Verification', style: TextStyle(color: Color(0xFF64748B), fontSize: 14.5)),
            ),
          ),
          SizedBox(height: context.h(20)),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: isMet ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: isMet ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.companyTheme(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Top architectural background layered behind header
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
                  // App Bar with back navigation
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(16),
                      vertical: context.h(8),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (_step > 0) {
                              setState(() {
                                _step--;
                                _error = null;
                              });
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(Icons.arrow_back, color: Color(0xFF1E2A38), size: 24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          switch (_step) {
                            0 => 'Company Registration',
                            1 => 'Verify Email Address',
                            2 => 'Set Account Password',
                            _ => 'Company Registration',
                          },
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A38),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main scrollable form area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: context.w(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: context.h(14)),

                          // Company Hexagonal Logo Badge
                          Image.asset(
                            'assets/logo_company.png',
                            width: context.w(62),
                            height: context.w(62),
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: context.h(18)),

                          // Titles
                          Text(
                            switch (_step) {
                              0 => 'Create Employer Account',
                              1 => 'Verify Your Email',
                              2 => 'Secure Your Account',
                              _ => 'Company Sign Up',
                            },
                            style: TextStyle(
                              fontSize: context.sp(26),
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: context.h(6)),

                          Text(
                            switch (_step) {
                              0 => 'Register your company to post site requirements and hire verified skilled workers.',
                              1 => 'Enter the 6-digit confirmation code sent to your official company inbox.',
                              2 => 'Create a strong password with letters, digits, and symbols to finish registration.',
                              _ => '',
                            },
                            style: TextStyle(
                              fontSize: context.sp(15),
                              color: const Color(0xFF6B7280),
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: context.h(22)),

                          // Step Progress Bar
                          _buildStepProgressBar(),

                          // Error Display
                          _buildErrorBanner(),

                          // Step Form Render
                          if (_step == 0) _buildStep1Info(),
                          if (_step == 1) _buildStep2Otp(),
                          if (_step == 2) _buildStep3Password(),
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