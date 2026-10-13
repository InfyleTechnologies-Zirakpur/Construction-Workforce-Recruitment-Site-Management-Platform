import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/responsive.dart';
import '../../features/bloc/worker_blocs.dart';
import 'company_login_screen.dart';
import 'otp_screen.dart';

/// Worker / Job Seeker login screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  bool _awaitingOtp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _awaitingOtp = true);
    context.read<AuthCubit>().requestOtp(_phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141B),
      body: BlocListener<AuthCubit, LoadState<Map<String, dynamic>>>(
        listener: (context, state) {
          if (state is Loaded<Map<String, dynamic>> && _awaitingOtp) {
            _awaitingOtp = false;
            context.read<AuthCubit>().reset();
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OtpScreen(phoneNumber: _phoneController.text.trim()),
            ));
          }
          if (state is Failed<Map<String, dynamic>>) {
            _awaitingOtp = false;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final headerHeight = screenHeight * 0.44;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                     
                      SizedBox(
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
                                    Colors.black.withValues(alpha: 0.65),
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),

                            // Header Content: Logo + Title + Subtitle
                            SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.w(24),
                                  vertical: context.h(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Logo
                                    Image.asset(
                                      'assets/logo_worker.png',
                                      width: context.w(52),
                                      height: context.w(52),
                                      fit: BoxFit.contain,
                                    ),
                                    const Spacer(),

                                    // Heading: "Find your\nnext site job."
                                    RichText(
                                      text: TextSpan(
                                        text: 'Find your\n',
                                        style: TextStyle(
                                          fontSize: context.sp(28),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.15,
                                          letterSpacing: -0.5,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'next site job.',
                                            style: TextStyle(
                                              fontSize: context.sp(28),
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFF7A600), // golden yellow accent
                                              height: 1.15,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: context.h(8)),

                                    // Subtitle
                                    Text(
                                      'Sign in with your phone number to browse jobs, apply, and get hired faster.',
                                      style: TextStyle(
                                        fontSize: context.sp(13.5),
                                        color: Colors.white.withValues(alpha: 0.85),
                                        height: 1.35,
                                      ),
                                    ),
                                    SizedBox(height: context.h(14)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Card Sheet
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
                            context.h(28),
                            context.w(24),
                            context.h(20),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Phone number',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E2A38),
                                  ),
                                ),
                                SizedBox(height: context.h(8)),

                                // Phone input box with +91 selector and divider
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              '+91',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E2A38),
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: Color(0xFF6B7280),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 24,
                                        width: 1.2,
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          maxLength: 10,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1E2A38),
                                          ),
                                          decoration: const InputDecoration(
                                            counterText: '',
                                            hintText: '98765 43210',
                                            hintStyle: TextStyle(
                                              color: Color(0xFF9CA3AF),
                                              fontSize: 15,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                          ),
                                          validator: (value) {
                                            final v = value?.trim() ?? '';
                                            if (v.isEmpty) return 'Enter your phone number';
                                            if (v.length != 10) return 'Enter a valid 10-digit number';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: context.h(20)),

                                // Send OTP Button
                                SizedBox(
                                  width: double.infinity,
                                  height: context.h(52),
                                  child: BlocBuilder<AuthCubit, LoadState<Map<String, dynamic>>>(
                                    builder: (context, state) => ElevatedButton(
                                      onPressed: state is Loading<Map<String, dynamic>> ? null : _handleSendOtp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFA6400),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: state is Loading<Map<String, dynamic>>
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.2,
                                              ),
                                            )
                                          : const Text(
                                              'Send OTP',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: context.h(18)),

                                // Divider with "OR"
                                Row(
                                  children: const [
                                    Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 14),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                                  ],
                                ),
                                SizedBox(height: context.h(18)),

                                // Company login with email
                                SizedBox(
                                  width: double.infinity,
                                  height: context.h(52),
                                  child: Material(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const CompanyLoginScreen()),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.mail_outline_rounded,
                                            color: Color(0xFF1E2A38),
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Company login with email',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E2A38),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const Spacer(),
                                SizedBox(height: context.h(16)),

                                // Footer
                                Center(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'By continuing, you agree to our ',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Terms',
                                          style: const TextStyle(
                                            color: Color(0xFFFA6400),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: const TextStyle(
                                            color: Color(0xFFFA6400),
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
}
