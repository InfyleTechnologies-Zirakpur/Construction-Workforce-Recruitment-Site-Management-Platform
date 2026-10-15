import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/utils/responsive.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

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

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_step == 0) {
        await ApiClient.instance.dio.post(
          '/auth/request-otp',
          data: {'phone': _phoneController.text.trim()},
        );
        if (mounted) setState(() => _step = 1);
      } else if (_step == 1) {
        setState(() => _step = 2);
      } else {
        await ApiClient.instance.dio.post(
          '/auth/reset-password',
          data: {
            'phone': _phoneController.text.trim(),
            'otp': _otpController.text.trim(),
            'newPassword': _passwordController.text,
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
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
                      fontSize: 13.5,
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

  String get _title => ['Your mobile number', 'Verify OTP', 'Create password'][_step];

  String get _description {
    if (_step == 0) return 'We will send a secure verification code to your mobile.';
    if (_step == 1) return 'Enter the 6-digit code sent to +91 ${_phoneController.text.trim()}.';
    return 'Use at least 6 characters for your new password.';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.dark,
        title: Text('Reset password', style: textTheme.titleLarge),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.w(24)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _progress(context),
                    SizedBox(height: context.h(28)),
                    Text(
                      _title,
                      style: textTheme.headlineSmall?.copyWith(color: AppColors.dark),
                    ),
                    SizedBox(height: context.h(8)),
                    Text(_description, style: textTheme.bodyMedium),
                    SizedBox(height: context.h(28)),
                    _input(),
                    SizedBox(height: context.h(24)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _continue,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: context.h(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(_step == 2 ? 'Update password' : 'Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input() {
    if (_step == 0) {
      return TextFormField(
        controller: _phoneController,
        maxLength: 10,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Mobile number',
          prefixText: '+91 ',
        ),
        validator: (value) {
          final phone = (value ?? '').trim();
          if (phone.isEmpty) {
            return 'Mobile number is required';
          }
          if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
            return 'Mobile number must contain digits only';
          }
          if (phone.length != 10) {
            return 'Please enter a valid 10-digit mobile number';
          }
          if (!RegExp(r'^[6-9]').hasMatch(phone)) {
            return 'Mobile number must start with 6, 7, 8, or 9';
          }
          if (RegExp(r'^([0-9])\1{9}$').hasMatch(phone)) {
            return 'Please enter a valid mobile number';
          }
          return null;
        },
      );
    }
    if (_step == 1) {
      return TextFormField(
        controller: _otpController,
        maxLength: 6,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: '6-digit OTP'),
        validator: (value) {
          final otp = (value ?? '').trim();
          if (otp.isEmpty) {
            return 'Verification code is required';
          }
          if (!RegExp(r'^[0-9]+$').hasMatch(otp)) {
            return 'OTP must contain numbers only';
          }
          if (otp.length != 6) {
            return 'Please enter the complete 6-digit OTP';
          }
          return null;
        },
      );
    }
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(labelText: 'New password'),
      validator: (value) {
        final pass = value ?? '';
        if (pass.isEmpty) {
          return 'New password is required';
        }
        if (pass.length < 6) {
          return 'Password must be at least 6 characters long';
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
