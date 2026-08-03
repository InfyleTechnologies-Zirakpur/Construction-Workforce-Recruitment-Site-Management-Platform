import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to continue. Please try again.')),
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
        validator: (value) => (value ?? '').trim().length == 10
            ? null
            : 'Enter a valid 10-digit number',
      );
    }
    if (_step == 1) {
      return TextFormField(
        controller: _otpController,
        maxLength: 6,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: '6-digit OTP'),
        validator: (value) => (value ?? '').trim().length == 6
            ? null
            : 'Enter the complete OTP',
      );
    }
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(labelText: 'New password'),
      validator: (value) => (value ?? '').length >= 6
          ? null
          : 'Use at least 6 characters',
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
