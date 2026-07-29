import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'otp_screen.dart';

/// Phone-number entry screen — first step of the OTP login flow.
/// On success it pushes [OtpScreen] with the entered number.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    // TODO: replace with a real "send OTP" API call.
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(phoneNumber: _phoneController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(24),
            vertical: context.h(32),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.w(64),
                  height: context.w(64),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.foundation,
                    color: AppColors.primary,
                    size: context.sp(32),
                  ),
                ),
                SizedBox(height: context.h(24)),
                Text(
                  'Find your next site job.',
                  style: textTheme.headlineSmall?.copyWith(color: AppColors.dark),
                ),
                SizedBox(height: context.h(8)),
                Text(
                  'Sign in with your phone number to browse jobs, apply, '
                  'and get hired faster.',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                SizedBox(height: context.h(32)),
                Text('Phone number', style: textTheme.titleSmall),
                SizedBox(height: context.h(8)),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: textTheme.bodyMedium,
                  maxLength: 10,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '98765 43210',
                    hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black38),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          '+91',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Enter your phone number';
                    if (v.length != 10) return 'Enter a valid 10-digit number';
                    return null;
                  },
                ),
                SizedBox(height: context.h(24)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendOtp,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: context.h(16)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: context.sp(20),
                            height: context.sp(20),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            'Send OTP',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: context.h(16)),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'By continuing, you agree to our ',
                      style: textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: 'Terms',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
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
