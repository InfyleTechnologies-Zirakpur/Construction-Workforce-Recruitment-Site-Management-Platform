import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../features/bloc/worker_blocs.dart';
import 'company_login_screen.dart';
import 'job_seeker_otp_screen.dart';
import 'login_screen.dart';



class JobSeekerRegisterScreen extends StatefulWidget {
  const JobSeekerRegisterScreen({super.key});

  @override
  State<JobSeekerRegisterScreen> createState() => _JobSeekerRegisterScreenState();
}

class _JobSeekerRegisterScreenState extends State<JobSeekerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();

  List<String> _selectedSkills = ['Electrician'];
  bool _isLoading = false;
  String? _firstNameError;
  String? _lastNameError;
  String? _contactError;
  String? _skillsError;

  static const List<Map<String, dynamic>> _tradeOptions = [
    {
      'name': 'Electrician',
      'specialty': 'Wiring, Panels, Fitting',
      'icon': Icons.bolt_rounded,
    },
    {
      'name': 'Plumber',
      'specialty': 'Piping, Sanitary, Drainage',
      'icon': Icons.plumbing_rounded,
    },
    {
      'name': 'Mason (Mistri)',
      'specialty': 'Brickwork, Plaster, Concrete',
      'icon': Icons.foundation_rounded,
    },
    {
      'name': 'Carpenter',
      'specialty': 'Woodwork, Shuttering, Doors',
      'icon': Icons.carpenter_rounded,
    },
    {
      'name': 'Painter',
      'specialty': 'Wall Putty, Primer, Polish',
      'icon': Icons.format_paint_rounded,
    },
    {
      'name': 'Welder',
      'specialty': 'Arc Welding, Fabrication, Steel',
      'icon': Icons.hardware_rounded,
    },
    {
      'name': 'Bar Bender',
      'specialty': 'TMT Bending, Rebar, Mesh',
      'icon': Icons.architecture_rounded,
    },
    {
      'name': 'Site Helper',
      'specialty': 'Material Handling, Site Assistance',
      'icon': Icons.handyman_rounded,
    },
    {
      'name': 'Supervisor',
      'specialty': 'Site Execution, Quality, Crew Lead',
      'icon': Icons.engineering_rounded,
    },
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  String? _validateName(String? value, String fieldName) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return '$fieldName is required';
    }
    if (v.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (RegExp(r'[0-9]').hasMatch(v)) {
      return '$fieldName should not contain numbers';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Mobile number is required';
    }
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (!RegExp(r'^[0-9]+$').hasMatch(digits) || digits.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    if (!RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }
    return null;
  }

  Future<void> _handleContinue() async {
    final fErr = _validateName(_firstNameController.text, 'First name');
    final lErr = _validateName(_lastNameController.text, 'Last name');
    final pErr = _validatePhone(_contactController.text);
    String? sErr;
    if (_selectedSkills.isEmpty) {
      sErr = 'Please select at least 1 trade/skill';
    }

    setState(() {
      _firstNameError = fErr;
      _lastNameError = lErr;
      _contactError = pErr;
      _skillsError = sErr;
    });

    if (fErr != null || lErr != null || pErr != null || sErr != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final phone = _contactController.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
      final fullName = '$firstName $lastName';

      await context.read<AuthCubit>().signupSendOtp(
        firstName: firstName,
        lastName: lastName,
        contact: phone,
        skills: _selectedSkills,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JobSeekerOtpScreen(
            firstName: firstName,
            lastName: lastName,
            name: fullName,
            phoneNumber: phone,
            skills: _selectedSkills,
            skill: _selectedSkills.join(', '),
            isEmail: false,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Unable to send verification code. Please check your phone number.', isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSkillPicker() {
    List<String> tempSelected = List<String>.from(_selectedSkills);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.peachBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.handyman_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Skills / Trades',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E2A38),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Select up to 4 trades you specialize in',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: tempSelected.length == 4
                                ? const Color(0xFFFEF3C7)
                                : AppColors.peachBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tempSelected.length == 4
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${tempSelected.length}/4 Selected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tempSelected.length == 4
                                  ? const Color(0xFFB45309)
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.48,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _tradeOptions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final item = _tradeOptions[index];
                          final name = item['name'] as String;
                          final specialty = item['specialty'] as String;
                          final icon = item['icon'] as IconData;
                          final isSelected = tempSelected.contains(name);

                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  tempSelected.remove(name);
                                } else {
                                  if (tempSelected.length >= 4) {
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Maximum 4 skills can be selected.'),
                                        backgroundColor: Color(0xFFDC2626),
                                        duration: Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  tempSelected.add(name);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.peachBackground : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.12)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: isSelected ? AppColors.primary : const Color(0xFF475569),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? AppColors.primary : const Color(0xFF1E2A38),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          specialty,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? AppColors.primary : Colors.white,
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (tempSelected.isEmpty) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select at least 1 trade/skill.'),
                                backgroundColor: Color(0xFFDC2626),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _selectedSkills = tempSelected;
                            _skillsError = null;
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          tempSelected.isEmpty
                              ? 'Select at least 1 trade'
                              : 'Done (${tempSelected.length} selected)',
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
            );
          },
        );
      },
    );
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
                                        text: 'Create your \n',
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
                                      'Join thousands of verified tradesmen finding site jobs.',
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
                              // STEP PROGRESS INDICATOR (Step 1 of 3)
                              _buildStepProgress(),
                              SizedBox(height: context.h(18)),

                              // FIRST NAME & LAST NAME (Side by side)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // FIRST NAME
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstNameController,
                                      textCapitalization: TextCapitalization.words,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E2A38),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'First Name *',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 14.5,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person_outline_rounded,
                                          color: Color(0xFF6B7280),
                                          size: 19,
                                        ),
                                        prefixIconConstraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
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
                                        errorText: _firstNameError,
                                        errorMaxLines: 2,
                                        errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 11.5),
                                      ),
                                      onChanged: (_) {
                                        if (_firstNameError != null) {
                                          setState(() => _firstNameError =
                                              _validateName(_firstNameController.text, 'First name'));
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // LAST NAME
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastNameController,
                                      textCapitalization: TextCapitalization.words,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E2A38),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Last Name *',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 14.5,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person_outline_rounded,
                                          color: Color(0xFF6B7280),
                                          size: 19,
                                        ),
                                        prefixIconConstraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
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
                                        errorText: _lastNameError,
                                        errorMaxLines: 2,
                                        errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 11.5),
                                      ),
                                      onChanged: (_) {
                                        if (_lastNameError != null) {
                                          setState(() => _lastNameError =
                                              _validateName(_lastNameController.text, 'Last name'));
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.h(14)),

                              // PHONE NUMBER BLANK (NO COUNTRY CODE)
                              TextFormField(
                                controller: _contactController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E2A38),
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'Phone Number *',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 14.5,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.phone_android_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 19,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
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
                                  errorText: _contactError,
                                  errorMaxLines: 2,
                                  errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 11.5),
                                ),
                                onChanged: (_) {
                                  if (_contactError != null) {
                                    setState(() => _contactError = _validatePhone(_contactController.text));
                                  }
                                },
                              ),
                              SizedBox(height: context.h(14)),

                              // SKILLS / TRADES SELECTOR (MAX 4)
                              InkWell(
                                onTap: _openSkillPicker,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _skillsError != null
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFFE5E7EB),
                                      width: _skillsError != null ? 1.2 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.construction_rounded,
                                            color: Color(0xFF6B7280),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Select Trades / Skills (Max 4) *',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: _skillsError != null
                                                    ? const Color(0xFFDC2626)
                                                    : const Color(0xFF6B7280),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.peachBackground,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${_selectedSkills.length}/4 Selected',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Color(0xFF6B7280),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      if (_selectedSkills.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: _selectedSkills.map((s) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                              ),
                                              child: Text(
                                                s,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1E2A38),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                      if (_skillsError != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          _skillsError!,
                                          style: const TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: context.h(22)),

                              // CONTINUE BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: context.h(52),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
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
                                              'Next: Verify OTP',
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
                              SizedBox(height: context.h(16)),

                              // ALREADY HAVE AN ACCOUNT? LOG IN
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    );
                                  },
                                  child: const Text.rich(
                                    TextSpan(
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 15.5,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Log In',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // COMPANY PORTAL LINK
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CompanyLoginScreen()),
                                  ),
                                  child: const Text(
                                    'Company portal with email',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
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

  Widget _buildStepProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'STEP 1 OF 3',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Basic Details',
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
                  color: const Color(0xFFE2E8F0),
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
}
