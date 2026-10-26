import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/utils/responsive.dart';

class ResetPasswordScreen extends StatefulWidget {
  /// 'phone' → job seeker flow, 'email' → company/contractor flow.
  /// null → auto-detect from what the user types (phone number vs email).
  final String? initialMethod;

  const ResetPasswordScreen({super.key, this.initialMethod});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  int _step = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Strong password — mirrors backend policy (8+, upper, lower, digit, special).
  static final _strongPassword = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$',
  );

  bool get _isEmailMode {
    if (widget.initialMethod != null) return widget.initialMethod == 'email';
    return _phoneController.text.contains('@');
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_step == 0) {
        // POST /auth/forgot-password — role chosen by `method`.
        final payload = _isEmailMode
            ? {
                'method': 'email',
                'email': _phoneController.text.trim().toLowerCase(),
              }
            : {'method': 'phone', 'phone': _phoneController.text.trim()};
        await ApiClient.instance.dio.post(
          '/auth/forgot-password',
          data: payload,
        );
        if (mounted) setState(() => _step = 1);
      } else if (_step == 1) {
        setState(() => _step = 2);
      } else {
        // POST /auth/reset-password — verify OTP + set new password.
        await ApiClient.instance.dio.post(
          '/auth/reset-password',
          data: _isEmailMode
              ? {
                  'method': 'email',
                  'email': _phoneController.text.trim().toLowerCase(),
                  'otp': _otpController.text.trim(),
                  'newPassword': _passwordController.text,
                }
              : {
                  'method': 'phone',
                  'phone': _phoneController.text.trim(),
                  'otp': _otpController.text.trim(),
                  'newPassword': _passwordController.text,
                },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully. Please login with your new password.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = ApiErrorParser.extractMessage(
          e,
          fallbackMessage: _step == 0
              ? 'Failed to send OTP to this mobile number.'
              : _step == 1
                  ? 'Invalid verification code. Please check and try again.'
                  : 'Failed to reset password. Please try again.',
        );
        final isNet = ApiErrorParser.isNetworkError(e) ||
            errorMsg.toLowerCase().contains('internet') ||
            errorMsg.toLowerCase().contains('connection') ||
            errorMsg.toLowerCase().contains('network') ||
            errorMsg.toLowerCase().contains('timed out');
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isNet ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 15.5,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _title => [_isEmailMode ? 'Your email address' : 'Your mobile number', 'Verify OTP', 'Create password'][_step];

  String get _description {
    if (_step == 0) return 'We will send a secure verification code to your ${_isEmailMode ? 'email' : 'phone'}.';
    if (_step == 1) return 'Enter the 6-digit code sent to ${_phoneController.text.trim()}.';
    return 'Min 8 characters with uppercase, lowercase, number & special character.';
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
              : (fullHeight * 0.38).clamp(280.0, 360.0);

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // TOP HERO HEADER WITH IMAGE
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
                                        onPressed: () {
                                          if (_step > 0) {
                                            setState(() => _step--);
                                          } else {
                                            Navigator.maybePop(context);
                                          }
                                        },
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
                                        text: 'Reset your \n',
                                        style: TextStyle(
                                          fontSize: context.sp(26),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.15,
                                          letterSpacing: -0.5,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: 'account password.',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: context.h(6)),
                                    Text(
                                      _description,
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
                              _progress(context),
                              SizedBox(height: context.h(20)),
                              Text(
                                _title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E2A38),
                                ),
                              ),
                              SizedBox(height: context.h(16)),
                              _input(),
                              SizedBox(height: context.h(24)),
                              SizedBox(
                                width: double.infinity,
                                height: context.h(52),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _continue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.dark,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: AppColors.dark,
                                            strokeWidth: 2.4,
                                          ),
                                        )
                                      : Text(
                                          _step == 2 ? 'Update password' : 'Continue',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
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

  Widget _input() {
    if (_step == 0) {
      return TextFormField(
        key: const ValueKey('step0_phone'),
        controller: _phoneController,
        keyboardType: _isEmailMode ? TextInputType.emailAddress : TextInputType.phone,
        enabled: widget.initialMethod == null, // role-locked flows can't switch
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1E2A38),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: _isEmailMode ? 'Email ID *' : 'Phone Number *',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14.5),
          prefixIcon: Icon(
            _isEmailMode
                ? Icons.alternate_email_rounded
                : Icons.phone_android_rounded,
            color: const Color(0xFF6B7280),
            size: 19,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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
          errorMaxLines: 2,
          errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 11.5),
        ),
        onChanged: (_) => setState(() {}),
        validator: (value) {
          final val = (value ?? '').trim();
          if (val.isEmpty) {
            return _isEmailMode ? 'Email is required' : 'Phone number is required';
          }
          if (_isEmailMode) {
            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
            if (!emailRegex.hasMatch(val)) {
              return 'Please enter a valid email address';
            }
            return null;
          }
          final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.length != 10 || !RegExp(r'^[6-9]').hasMatch(digits)) {
            return 'Please enter a valid 10-digit mobile number';
          }
          return null;
        },
      );
    }
    if (_step == 1) {
      return TextFormField(
        key: const ValueKey('step1_otp'),
        controller: _otpController,
        maxLength: 6,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 16.5,
          color: Color(0xFF1E2A38),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '6-digit OTP *',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
          prefixIcon: const Icon(
            Icons.pin_outlined,
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
          errorMaxLines: 2,
          errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
        ),
        validator: (value) {
          final otp = (value ?? '').trim();
          if (otp.isEmpty) return 'Verification code is required';
          if (!RegExp(r'^[0-9]+$').hasMatch(otp)) return 'OTP must contain numbers only';
          if (otp.length != 6) return 'Please enter the complete 6-digit OTP';
          return null;
        },
      );
    }
    return TextFormField(
       key: const ValueKey('step2_password'),
      controller: _passwordController,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.visiblePassword, // normal text keyboard
  textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontSize: 16.5,
        color: Color(0xFF1E2A38),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'New Password (8+ chars, A-Z, a-z, 0-9, special) *',
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF6B7280),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
        errorMaxLines: 2,
        errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
      ),
      validator: (value) {
        final pass = value ?? '';
        if (pass.isEmpty) return 'New password is required';
        if (!_strongPassword.hasMatch(pass)) {
          return 'Password needs 8+ chars with uppercase, lowercase, number & special character';
        }
        return null;
      },
    );
  }

  Widget _progress(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final active = index <= _step;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == 2 ? 0 : context.w(6)),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }
}
