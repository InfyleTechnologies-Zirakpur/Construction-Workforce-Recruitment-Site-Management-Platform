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


class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  const OtpScreen({super.key, required this.phoneNumber, this.countryCode = '+91'});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _isVerifying = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _otpController.selection = TextSelection.collapsed(
          offset: _otpController.text.length,
        );
      }
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
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
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _enteredOtp => _otpController.text.trim();

  Future<void> _handleVerify() async {
    final otp = _enteredOtp;
    if (otp.isEmpty) {
      setState(() => _errorText = 'Please enter the 6-digit verification code');
      return;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(otp)) {
      setState(() => _errorText = 'Verification code must contain digits only');
      return;
    }
    if (otp.length != _otpLength) {
      setState(() => _errorText = 'Enter all 6 digits of the verification code');
      return;
    }

    setState(() {
      _errorText = null;
      _isVerifying = true;
    });

    context.read<AuthCubit>().verifyOtp(widget.phoneNumber, otp);
  }

  void _handleResend() {
    if (_secondsLeft > 0) return;
    _otpController.clear();
    setState(() => _errorText = null);
    _focusNode.requestFocus();
    context.read<AuthCubit>().requestOtp(widget.phoneNumber);
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A new 6-digit OTP has been sent to your number.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  static const _placeholderNames = {
    '',
    'null',
    'undefined',
    'job seeker',
    'jobseeker',
    'new user',
    'user',
  };

  bool _isProfileComplete(Map<String, dynamic> data) {
    // 1. Explicit server flags win.
    for (final key in [
      'isProfileComplete',
      'profileComplete',
      'profileCompleted',
      'hasProfile',
      'isProfileCreated',
    ]) {
      if (data[key] is bool) return data[key] as bool;
    }
    if (data['isNewUser'] is bool) return !(data['isNewUser'] as bool);
    if (data['isNew'] is bool) return !(data['isNew'] as bool);

    // 2. Inspect worker / user / profile payloads.
    Map<String, dynamic>? candidate;
    for (final key in ['worker', 'user', 'profile', 'seeker']) {
      if (data[key] is Map) {
        candidate = Map<String, dynamic>.from(data[key] as Map);
        // Nested flags inside the object.
        for (final nk in [
          'isProfileComplete',
          'profileComplete',
          'hasProfile',
        ]) {
          if (candidate[nk] is bool) return candidate[nk] as bool;
        }
        if (candidate['isNewUser'] is bool) {
          return !(candidate['isNewUser'] as bool);
        }
        break;
      }
    }
    candidate ??= data;

    bool validName(String? v) {
      if (v == null) return false;
      final t = v.trim().toLowerCase();
      if (t.isEmpty || t == 'null' || t == 'undefined') return false;
      // Backend auto-register placeholder — NOT a real profile.
      if (_placeholderNames.contains(t)) return false;
      return true;
    }

    bool valid(String? v) {
      if (v == null) return false;
      final t = v.trim().toLowerCase();
      return t.isNotEmpty && t != 'null' && t != 'undefined';
    }

    // Name alone is NOT enough (new users have 'Job Seeker').
    // Mirror backend: synthetic OTP accounts (phone@buildhire.app) need a
    // real profile field; real registrations with a real name are complete.
    final hasRealName = validName(candidate['name']?.toString()) ||
        validName(candidate['fullName']?.toString());
    if (!hasRealName) return false;
    final email = (candidate['email']?.toString() ?? '').toLowerCase().trim();
    final phone = (candidate['phone']?.toString() ?? '').trim();
    final isSynthetic =
        email.endsWith('@buildhire.app') && phone.isNotEmpty && email.startsWith(phone);
    if (!isSynthetic && email.isNotEmpty) return true;
    final cityOk = valid(candidate['city']?.toString());
    final skills = candidate['skills'];
    final skillsOk = skills is List && skills.isNotEmpty;
    final salaryOk = valid(candidate['salaryExpectation']?.toString());
    if (cityOk || skillsOk || salaryOk) return true;

    // Name set but nothing else (edge case) → treat as incomplete so the
    // user can finish Create Profile rather than hitting an empty Home.
    return false;
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
            // Ignore the intermediate {'otpSent': true} emission from
            // requestOtp — that belongs to LoginScreen, not verification.
            if (data['otpSent'] == true && data['accessToken'] == null) return;
            NotificationService.instance.syncDeviceToken();
            final bool isProfileComplete = _isProfileComplete(data);

            // Clear stale feature state from any previous number BEFORE
            // navigating — otherwise the new login briefly sees the old
            // user's profile/jobs. Then reset auth state so going back /
            // re-login doesn't replay this stale Loaded event.
            try {
              context.read<ProfileCubit>().reset();
            } catch (_) {}
            try {
              context.read<JobsCubit>().reset();
            } catch (_) {}
            try {
              context.read<DashboardCubit>().reset();
            } catch (_) {}
            try {
              context.read<MessagesCubit>().reset();
            } catch (_) {}
            try {
              context.read<NotificationsCubit>().reset();
            } catch (_) {}
            context.read<AuthCubit>().reset();

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
              _errorText = state.message.isNotEmpty
                  ? state.message
                  : 'Invalid OTP code. Please enter the correct code.';
            });
            _focusNode.requestFocus();
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
                widget.phoneNumber.startsWith('+')
                    ? widget.phoneNumber
                    : '${widget.countryCode} ${widget.phoneNumber}',
                style: textTheme.titleSmall?.copyWith(color: AppColors.dark),
              ),
              SizedBox(height: context.h(28)),
              _buildOtpBoxes(context),
              if (_errorText != null) ...[
                SizedBox(height: context.h(12)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _errorText!.toLowerCase().contains('internet') ||
                                _errorText!.toLowerCase().contains('connection') ||
                                _errorText!.toLowerCase().contains('network') ||
                                _errorText!.toLowerCase().contains('timed out')
                            ? Icons.wifi_off_rounded
                            : Icons.error_outline_rounded,
                        color: const Color(0xFFDC2626),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF991B1B),
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          width: context.sp(22),
                          height: context.sp(22),
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

  Widget _buildOtpBoxes(BuildContext context) {
    final currentOtp = _otpController.text;
    final currentLength = currentOtp.length;
    final hasFocus = _focusNode.hasFocus;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        _otpController.selection = TextSelection.collapsed(
          offset: _otpController.text.length,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, (index) {
              final isFilled = index < currentLength;
              final isCurrent = index == currentLength;
              final isLastAndFull =
                  index == _otpLength - 1 && currentLength == _otpLength;
              final isFocused = hasFocus && (isCurrent || isLastAndFull);
              final digit = isFilled ? currentOtp[index] : '';

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: context.w(46),
                height: context.w(54),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _errorText != null
                        ? AppColors.error
                        : (isFocused ? AppColors.primary : AppColors.border),
                    width: isFocused ? 1.8 : 1.0,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  digit,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w700,
                      ) ??
                      const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.0,
              child: TextField(
                controller: _otpController,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_otpLength),
                ],
                showCursor: false,
                enableInteractiveSelection: false,
                onChanged: (val) {
                  if (_errorText != null) setState(() => _errorText = null);
                  setState(() {});
                  if (val.length == _otpLength) {
                    _focusNode.unfocus();
                    _handleVerify();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
