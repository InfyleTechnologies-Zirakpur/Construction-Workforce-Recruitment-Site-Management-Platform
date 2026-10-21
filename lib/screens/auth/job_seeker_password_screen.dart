import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/utils/responsive.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/worker_repository.dart';
import '../profile/complete_profile_screen.dart';


class JobSeekerPasswordScreen extends StatefulWidget {
  final String? firstName;
  final String? lastName;
  final String name;
  final String phoneNumber;
  final String skill;
  final List<String> skills;
  final String otp;
  final String? signupToken;
  final String countryCode;
  final Map<String, dynamic>? authData;

  const JobSeekerPasswordScreen({
    super.key,
    this.firstName,
    this.lastName,
    required this.name,
    required this.phoneNumber,
    this.skill = '',
    this.skills = const [],
    required this.otp,
    this.signupToken,
    this.countryCode = '+91',
    this.authData,
  });

  @override
  State<JobSeekerPasswordScreen> createState() => _JobSeekerPasswordScreenState();
}

class _JobSeekerPasswordScreenState extends State<JobSeekerPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUpperLower =>
      RegExp(r'[A-Z]').hasMatch(_passwordController.text) &&
      RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasDigit => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSpecialChar =>
      RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_=+]').hasMatch(_passwordController.text);
  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text;

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final repo = WorkerRepository();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      final signupToken = widget.signupToken ??
          widget.authData?['signupToken']?.toString() ??
          '';

      Map<String, dynamic> authResult = {};
      if (signupToken.isNotEmpty) {
        // Step 3: POST /auth/signup/set-password (no email field)
        authResult = await repo.signupSetPassword(
          signupToken: signupToken,
          password: password,
          confirmPassword: confirmPassword,
        );
      } else {
        authResult = await repo.setPassword(
          phone: widget.phoneNumber,
          otp: widget.otp,
          newPassword: password,
        );
      }

      final accessToken = authResult['accessToken']?.toString() ??
          widget.authData?['accessToken']?.toString();
      final refreshToken = authResult['refreshToken']?.toString() ??
          widget.authData?['refreshToken']?.toString();

      // Immediately configure ApiClient Authorization header
      if (accessToken != null && accessToken.isNotEmpty) {
        ApiClient.accessToken = accessToken;
        ApiClient.instance.dio.options.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Persist session data to secure storage (both with encryptedSharedPreferences and plain fallback)
      const storageEncrypted = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      const storagePlain = FlutterSecureStorage();

      if (accessToken != null && accessToken.isNotEmpty) {
        await storageEncrypted.write(key: 'accessToken', value: accessToken);
        await storagePlain.write(key: 'accessToken', value: accessToken);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await storageEncrypted.write(key: 'refreshToken', value: refreshToken);
        await storagePlain.write(key: 'refreshToken', value: refreshToken);
      }
      final effectiveSkills = widget.skills.isNotEmpty
          ? widget.skills
          : (widget.skill.isNotEmpty ? widget.skill.split(',').map((e) => e.trim()).toList() : ['Electrician']);
      final primarySkill = effectiveSkills.firstOrNull ?? widget.skill;

      await storageEncrypted.write(key: 'role', value: 'job_seeker');
      await storagePlain.write(key: 'role', value: 'job_seeker');
      await storageEncrypted.write(key: 'phone', value: widget.phoneNumber);
      await storagePlain.write(key: 'phone', value: widget.phoneNumber);
      await storageEncrypted.write(key: 'workerName', value: widget.name);
      await storagePlain.write(key: 'workerName', value: widget.name);
      await storageEncrypted.write(key: 'workerSkill', value: primarySkill);
      await storagePlain.write(key: 'workerSkill', value: primarySkill);
      await storageEncrypted.write(key: 'workerSkills', value: jsonEncode(effectiveSkills));
      await storagePlain.write(key: 'workerSkills', value: jsonEncode(effectiveSkills));

     
      if (mounted) {
        try {
          await context.read<ProfileCubit>().update({
            'city': 'Delhi',
            'salaryExpectation': '800',
            'skills': effectiveSkills,
            if (widget.phoneNumber.contains('@')) 'email': widget.phoneNumber.trim(),
            'experience': effectiveSkills.map((s) => {
              'title': s,
              'company': 'XYZ Constructions',
              'years': '1',
            }).toList(),
            'education': [],
          });
        } catch (_) {}
      }

      // 4. Sync device notification token
      NotificationService.instance.syncDeviceToken();

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Welcome, ${widget.name}! Your account is ready.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await storageEncrypted.write(key: 'profileCompleted', value: 'false');
      await storagePlain.write(key: 'profileCompleted', value: 'false');

      // 5. First-time signup: navigate to CompleteProfileScreen to complete profile first
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(phoneNumber: widget.phoneNumber),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = ApiErrorParser.extractMessage(
            e,
            fallback: 'Failed to complete registration. Please try again.',
          );
        });
      }
    }
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
                                        text: 'Secure your \n',
                                        style: TextStyle(
                                          fontSize: context.sp(26),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.15,
                                          letterSpacing: -0.5,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: 'worker account.',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: context.h(6)),
                                    Text(
                                      'Create a password to easily log into BuildHire anytime.',
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
                              // STEP PROGRESS INDICATOR (Step 3 of 3)
                              _buildStepProgress(),
                              SizedBox(height: context.h(20)),

                              // ERROR BANNER
                              if (_error != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFCA5A5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Color(0xFF991B1B),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: context.h(14)),
                              ],

                            
                              // FIELD 1: PASSWORD
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E2A38),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Password (min 8 characters, e.g. Rahul@1234) *',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
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
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  if (v.length < 8) return 'Password must be at least 8 characters';
                                  if (!_hasUpperLower) return 'Include uppercase and lowercase letters';
                                  if (!_hasDigit) return 'Include at least one number';
                                  if (!_hasSpecialChar) return 'Include a special character (e.g. @, #, \$, !)';
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                              SizedBox(height: context.h(14)),

                              // FIELD 2: CONFIRM PASSWORD
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E2A38),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Confirm Password *',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_reset_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF6B7280),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please confirm your password';
                                  if (v != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                              SizedBox(height: context.h(16)),

                              // PASSWORD STRENGTH REQUIREMENTS
                              _buildRequirementRow(
                                isMet: _hasMinLength,
                                label: 'At least 8 characters',
                              ),
                              const SizedBox(height: 5),
                              _buildRequirementRow(
                                isMet: _hasUpperLower,
                                label: 'Upper and lowercase letters',
                              ),
                              const SizedBox(height: 5),
                              _buildRequirementRow(
                                isMet: _hasDigit && _hasSpecialChar,
                                label: 'Number & special character (e.g. Rahul@1234)',
                              ),
                              const SizedBox(height: 5),
                              _buildRequirementRow(
                                isMet: _passwordsMatch,
                                label: 'Passwords match',
                              ),
                              SizedBox(height: context.h(24)),

                              // FINISH REGISTRATION BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: context.h(52),
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _completeRegistration,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isSubmitting
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
                                              'Complete Sign Up',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.check_circle_outline_rounded, size: 20),
                                          ],
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

  Widget _buildStepProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'STEP 3 OF 3',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Set Password',
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementRow({required bool isMet, required String label}) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isMet ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: isMet ? const Color(0xFF1E2A38) : const Color(0xFF64748B),
            fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
