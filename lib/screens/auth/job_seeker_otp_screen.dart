import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/utils/responsive.dart';
import '../../features/bloc/worker_blocs.dart';
import 'job_seeker_password_screen.dart';


class JobSeekerOtpScreen extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String name;
  final String phoneNumber;
  final String skill;
  final List<String> skills;
  final String countryCode;
  final bool isEmail;

  const JobSeekerOtpScreen({
    super.key,
    this.firstName,
    this.lastName,
    required this.name,
    required this.phoneNumber,
    this.skill = '',
    this.skills = const [],
    this.countryCode = '',
    this.isEmail = false,
  });

  @override
  State<JobSeekerOtpScreen> createState() => _JobSeekerOtpScreenState();
}

class _JobSeekerOtpScreenState extends State<JobSeekerOtpScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _isVerifying = false;
  String? _errorText;

  bool get _isEmailAddress => widget.isEmail || widget.phoneNumber.contains('@');

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

    try {
      context.read<AuthCubit>().signupVerifyOtp(
        contact: widget.phoneNumber,
        otp: otp,
      );
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorText = ApiErrorParser.extractMessage(e, fallback: 'Invalid OTP code.');
      });
    }
  }

  void _handleResend() {
    if (_secondsLeft > 0) return;
    _otpController.clear();
    setState(() => _errorText = null);
    _focusNode.requestFocus();
    final fName = widget.firstName ?? widget.name.split(' ').first;
    final lName = widget.lastName ?? (widget.name.split(' ').length > 1 ? widget.name.split(' ').sublist(1).join(' ') : '');
    final effectiveSkills = widget.skills.isNotEmpty
        ? widget.skills
        : (widget.skill.isNotEmpty ? widget.skill.split(',').map((e) => e.trim()).toList() : ['Electrician']);

    context.read<AuthCubit>().signupSendOtp(
      firstName: fName,
      lastName: lName,
      contact: widget.phoneNumber,
      skills: effectiveSkills,
    );
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEmailAddress
              ? 'A new 6-digit verification code has been sent to your email.'
              : 'A new 6-digit OTP has been sent to your number.',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141B),
      body: BlocListener<AuthCubit, LoadState<Map<String, dynamic>>>(
        listener: (context, state) {
          if (state is Loaded<Map<String, dynamic>>) {
            final data = state.data;
            if (data['otpSent'] == true && data['signupToken'] == null && data['accessToken'] == null) return;

            setState(() => _isVerifying = false);

            final signupToken = data['signupToken']?.toString();
            final effectiveSkills = widget.skills.isNotEmpty
                ? widget.skills
                : (widget.skill.isNotEmpty ? widget.skill.split(',').map((e) => e.trim()).toList() : ['Electrician']);

            // Step 2 Successful: Proceed to Step 3 (Set Password)
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JobSeekerPasswordScreen(
                  firstName: widget.firstName,
                  lastName: widget.lastName,
                  name: widget.name,
                  phoneNumber: widget.phoneNumber,
                  skills: effectiveSkills,
                  skill: widget.skill.isNotEmpty ? widget.skill : effectiveSkills.join(', '),
                  otp: _enteredOtp,
                  signupToken: signupToken,
                  countryCode: widget.countryCode,
                  authData: data,
                ),
              ),
            );
          }
          if (state is Failed<Map<String, dynamic>>) {
            setState(() {
              _isVerifying = false;
              _errorText = state.message.isNotEmpty
                  ? state.message
                  : 'Invalid OTP code. Please enter the correct code.';
            });
          }
        },
        child: LayoutBuilder(
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
                      // TOP HERO HEADER
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
                                          onPressed: () => Navigator.maybePop(context),
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
                                          text: 'Verify your \n',
                                          style: TextStyle(
                                            fontSize: context.sp(26),
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.15,
                                            letterSpacing: -0.5,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: _isEmailAddress ? 'email address.' : 'mobile number.',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: context.h(6)),
                                      Text(
                                        _isEmailAddress
                                            ? 'A secure 6-digit code has been sent to ${widget.phoneNumber}'
                                            : (widget.countryCode.isNotEmpty && widget.countryCode != '+'
                                                ? 'A secure 6-digit code has been sent to ${widget.countryCode} ${widget.phoneNumber}'
                                                : 'A secure 6-digit code has been sent to ${widget.phoneNumber}'),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // STEP PROGRESS INDICATOR (Step 2 of 3)
                              _buildStepProgress(),
                              SizedBox(height: context.h(24)),

                              // CONTACT BADGE WITH EDIT ACTION
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isEmailAddress
                                          ? Icons.alternate_email_rounded
                                          : Icons.phone_android_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isEmailAddress
                                                ? 'Verification Code Sent To Email'
                                                : 'Verification Code Sent To Mobile',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _isEmailAddress || widget.countryCode.isEmpty || widget.countryCode == '+'
                                                ? widget.phoneNumber
                                                : '${widget.countryCode} ${widget.phoneNumber}',
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E2A38),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: const Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: context.h(24)),

                              // 6-DIGIT OTP DISPLAY BOXES
                              _buildOtpBoxes(),
                              SizedBox(height: context.h(12)),

                              // ERROR MESSAGE
                              if (_errorText != null) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _errorText!,
                                        style: const TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: context.h(12)),
                              ],

                              // RESEND CODE ROW
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _secondsLeft > 0
                                        ? 'Resend OTP in ${_secondsLeft}s'
                                        : "Didn't receive the code?",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _secondsLeft == 0 ? _handleResend : null,
                                    child: Text(
                                      'Resend OTP',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: _secondsLeft == 0
                                            ? AppColors.primary
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.h(20)),

                              // VERIFY & CONTINUE BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: context.h(52),
                                child: ElevatedButton(
                                  onPressed: _isVerifying ? null : _handleVerify,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isVerifying
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Verify & Set Password',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, size: 18),
                                          ],
                                        ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildStepProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'STEP 2 OF 3',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Verify Mobile',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtpBoxes() {
    final text = _otpController.text;
    final hasFocus = _focusNode.hasFocus;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // HIDDEN REAL TEXT FIELD
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _otpController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_otpLength),
              ],
              onChanged: (val) {
                setState(() {});
                if (val.length == _otpLength) {
                  _handleVerify();
                }
              },
            ),
          ),

          // 6 VISUAL PIN DIGIT BOXES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, (index) {
              final digit = index < text.length ? text[index] : '';
              final isCurrent = index == text.length && hasFocus;

              return Container(
                width: 46,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: digit.isNotEmpty
                      ? AppColors.peachBackground.withOpacity(0.4)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.primary
                        : (_errorText != null
                            ? const Color(0xFFE53935)
                            : (digit.isNotEmpty
                                ? AppColors.primary
                                : const Color(0xFFCBD5E1))),
                    width: isCurrent || digit.isNotEmpty ? 1.8 : 1.2,
                  ),
                ),
                child: Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2A38),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
