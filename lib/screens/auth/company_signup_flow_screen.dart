import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/utils/responsive.dart';
import '../../features/repositories/company_repository.dart';
import '../company/company_profile_form_screen.dart';

class CompanySignupFlowScreen extends StatefulWidget {
  const CompanySignupFlowScreen({super.key});

  @override
  State<CompanySignupFlowScreen> createState() => _CompanySignupFlowScreenState();
}

class _CompanySignupFlowScreenState extends State<CompanySignupFlowScreen> {
  final _repo = CompanyRepository();
  int _step = 0;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nameFormKey = GlobalKey<FormState>();

  final _otpCtrl = TextEditingController();
  final _otpFormKey = GlobalKey<FormState>();
  String? _signupToken;
  bool _emailVerified = false;

  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _passFormKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _extract(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      if (data[k] != null && data[k].toString().isNotEmpty) {
        return data[k].toString();
      }
    }
    final user = data['user'] ?? data['company'];
    if (user is Map) {
      for (final k in keys) {
        if (user[k] != null && user[k].toString().isNotEmpty) {
          return user[k].toString();
        }
      }
    }
    return '';
  }

  Future<void> _sendOtp() async {
    if (!_nameFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _repo.sendCompanySignupOtp(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (res['otpSent'] == true) {
        setState(() {
          _step = 1;
          _otpCtrl.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your email'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() => _error = res['message']?.toString() ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() => _error = ApiErrorParser.extractMessage(e, fallback: 'Failed to send OTP'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _repo.verifyCompanySignupOtp(
        email: _emailCtrl.text.trim(),
        otp: _otpCtrl.text.trim(),
      );
      final verified = res['verified'] == true || res['emailVerified'] == true;
      if (verified) {
        _signupToken = _extract(res, ['signupToken']);
        _emailVerified = res['emailVerified'] == true || verified;
        setState(() {
          _step = 2;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified. Please set your password.'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() => _error = res['message']?.toString() ?? 'Invalid or expired OTP');
      }
    } catch (e) {
      setState(() => _error = ApiErrorParser.extractMessage(e, fallback: 'Invalid or expired OTP'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    if (_signupToken == null || _signupToken!.isEmpty) {
      setState(() => _error = 'Missing signup token. Please verify OTP again.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.setCompanySignupPassword(
        signupToken: _signupToken!,
        password: _passCtrl.text,
        confirmPassword: _confirmCtrl.text,
      );
      final accessToken = _extract(data, ['accessToken']);
      final refreshToken = _extract(data, ['refreshToken']);
      const storage = FlutterSecureStorage();
      if (accessToken.isNotEmpty) {
        await storage.write(key: 'accessToken', value: accessToken);
        ApiClient.accessToken = accessToken;
        ApiClient.instance.dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      if (refreshToken.isNotEmpty) {
        await storage.write(key: 'refreshToken', value: refreshToken);
      }
      await storage.write(key: 'role', value: 'company');
      final user = data['user'];
      if (user is Map && user['id'] != null) {
        await storage.write(key: 'userId', value: user['id'].toString());
      }
      final compName = _nameCtrl.text.trim();
      if (compName.isNotEmpty) {
        await storage.write(key: 'companyName', value: compName);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CompanyProfileFormScreen(
            isInitialSetup: true,
            initialEmail: _emailCtrl.text.trim(),
            initialName: _nameCtrl.text.trim(),
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = ApiErrorParser.extractMessage(e, fallback: 'Failed to set password'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5)),
    );
  }

  Widget _button(String text, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.companyPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
            : Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
    );
  }

  Widget _buildStepOne() {
    return Form(
      key: _nameFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: _input('Company / Contact Name *', Icons.business_outlined),
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'Name is required';
              if ((v ?? '').trim().length < 2) return 'Enter a valid name';
              return null;
            },
          ),
          SizedBox(height: context.h(12)),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _input('Official Company Email *', Icons.mail_outline_rounded),
            validator: (v) {
              final email = (v ?? '').trim();
              if (email.isEmpty) return 'Email is required';
              final re = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
              if (!re.hasMatch(email)) return 'Enter a valid email address';
              return null;
            },
          ),
          SizedBox(height: context.h(18)),
          _button('Send OTP', _loading ? null : _sendOtp),
        ],
      ),
    );
  }

  Widget _buildStepTwo() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email: ${_emailCtrl.text.trim()}', style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w600)),
          SizedBox(height: context.h(12)),
          TextFormField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: _input('Enter 6-digit OTP', Icons.password_outlined),
            validator: (v) {
              if ((v ?? '').trim().length != 6) return 'Enter a valid 6-digit OTP';
              return null;
            },
          ),
          SizedBox(height: context.h(10)),
          TextButton(onPressed: _loading ? null : _sendOtp, child: const Text('Resend OTP')),
          SizedBox(height: context.h(10)),
          _button('Verify OTP', _loading ? null : _verifyOtp),
        ],
      ),
    );
  }

  Widget _buildStepThree() {
    return Form(
      key: _passFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Email verified: Yes', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
          SizedBox(height: context.h(12)),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: _input('New Password *', Icons.lock_outline_rounded).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            validator: (v) {
              final s = v ?? '';
              if (s.length < 8) return 'Password must be at least 8 characters';
              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$').hasMatch(s)) {
                return 'Must include uppercase, lowercase, number & special character';
              }
              return null;
            },
          ),
          SizedBox(height: context.h(12)),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            decoration: _input('Confirm Password *', Icons.lock_outline_rounded).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if ((v ?? '') != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          SizedBox(height: context.h(18)),
          _button('Set Password & Continue', _loading ? null : _setPassword),
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF1E2A38),
          title: Text(
            switch (_step) {
              0 => 'Company Sign Up',
              1 => 'Verify Email',
              2 => 'Set Password',
              _ => 'Company Sign Up'
            },
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: context.w(24), vertical: context.h(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (_step) {
                    0 => 'Create your company account',
                    1 => 'Enter the OTP sent to your email',
                    2 => 'Set a strong password to secure your account',
                    _ => ''
                  },
                  style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.4),
                ),
                SizedBox(height: context.h(18)),
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 14)),
                  ),
                ],
                if (_step == 0) _buildStepOne(),
                if (_step == 1) _buildStepTwo(),
                if (_step == 2) _buildStepThree(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
