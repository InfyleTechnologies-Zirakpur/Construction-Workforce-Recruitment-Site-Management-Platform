import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/responsive.dart';
import '../../features/bloc/worker_blocs.dart';
import '../home/home_page.dart';
import '../profile/complete_profile_screen.dart';

/// 6-digit OTP entry screen. Each box auto-advances focus; verifying
/// on a complete code continues to the worker profile setup.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _isVerifying = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = _resendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (_errorText != null) setState(() => _errorText = null);

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_enteredOtp.length == _otpLength) {
      FocusScope.of(context).unfocus();
      _handleVerify();
    }
  }

  Future<void> _handleVerify() async {
    if (_enteredOtp.length != _otpLength) {
      setState(() => _errorText = 'Enter the complete 6-digit code');
      return;
    }

    setState(() => _isVerifying = true);

    context.read<AuthCubit>().verifyOtp(widget.phoneNumber, _enteredOtp);
  }

  void _handleResend() {
    if (_secondsLeft > 0) return;
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    // TODO: trigger a real "resend OTP" API call.
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.dark,
        elevation: 0,
        title: Text(
          'Verify your number',
          style: textTheme.titleMedium?.copyWith(color: AppColors.dark),
        ),
      ),
      body: BlocListener<AuthCubit, LoadState<Map<String, dynamic>>>(
        listener: (context, state) {
          if (state is Loaded<Map<String, dynamic>>) {
            final data = state.data;
            NotificationService.instance.syncDeviceToken();
            final worker = data['worker'] is Map ? Map<String, dynamic>.from(data['worker']) : null;
            final name = worker?['name']?.toString().trim() ?? '';
            final bool isProfileComplete = name.isNotEmpty && name.toLowerCase() != 'null';

            if (isProfileComplete) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => CompleteProfileScreen(phoneNumber: widget.phoneNumber),
                ),
                (route) => false,
              );
            }
          }
          if (state is Failed<Map<String, dynamic>>) {
            setState(() {
              _isVerifying = false;
              _errorText = 'Verification failed. Please try again.';
            });
          }
        },
        child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(24),
            vertical: context.h(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the 6-digit code we sent to',
                style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              SizedBox(height: context.h(4)),
              Text(
                '+91 ${widget.phoneNumber}',
                style: textTheme.titleSmall?.copyWith(color: AppColors.dark),
              ),
              SizedBox(height: context.h(28)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_otpLength, (i) => _otpBox(context, i)),
              ),
              if (_errorText != null) ...[
                SizedBox(height: context.h(10)),
                Text(
                  _errorText!,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],
              SizedBox(height: context.h(28)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.h(16)),
                  ),
                  child: _isVerifying
                      ? SizedBox(
                          width: context.sp(20),
                          height: context.sp(20),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Text(
                          'Verify & Continue',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: context.h(20)),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                        style: textTheme.bodySmall,
                      )
                    : GestureDetector(
                        onTap: _handleResend,
                        child: Text(
                          'Resend code',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _otpBox(BuildContext context, int index) {
    return SizedBox(
      width: context.w(46),
      height: context.w(54),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: AppColors.dark),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _errorText != null ? AppColors.error : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        onChanged: (value) => _onChanged(index, value),
      ),
    );
  }
}
