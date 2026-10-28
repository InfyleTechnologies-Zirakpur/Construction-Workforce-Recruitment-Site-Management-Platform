import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../features/repositories/company_repository.dart';
import '../auth/login_screen.dart';
import '../company/company_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isTab;

  const SettingsScreen({
    super.key,
    this.isTab = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = CompanyRepository();
  static const _storageEncrypted = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _storagePlain = FlutterSecureStorage();

  bool _isLoading = true;
  String _email = '';
  String _phone = '';
  String _companyName = '';
  Map<String, dynamic>? _profile;

  // Notification switches
  bool _emailNotifications = true;
  bool _smsNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final emailEncrypted = await _storageEncrypted.read(key: 'email');
      final emailPlain = await _storagePlain.read(key: 'email');
      final phoneEncrypted = await _storageEncrypted.read(key: 'phone');
      final phonePlain = await _storagePlain.read(key: 'phone');
      final nameEncrypted = await _storageEncrypted.read(key: 'companyName');
      final namePlain = await _storagePlain.read(key: 'companyName');

      final savedEmailNotif = await _storagePlain.read(key: 'email_notif');
      final savedSmsNotif = await _storagePlain.read(key: 'sms_notif');

      Map<String, dynamic>? prof;
      try {
        prof = await _repo.getMyCompanyProfile();
        if (prof == null) {
          final profiles = await _repo.getMyProfiles();
          if (profiles.isNotEmpty) prof = profiles.first;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _profile = prof;
          _email = (prof?['contactEmail'] ??
                  prof?['email'] ??
                  prof?['owner']?['email'] ??
                  prof?['user']?['email'] ??
                  emailEncrypted ??
                  emailPlain ??
                  'hr@ltconstruction.com')
              .toString()
              .trim();
          _phone = (prof?['contactPhone'] ??
                  prof?['phone'] ??
                  prof?['phoneNumber'] ??
                  prof?['owner']?['phone'] ??
                  phoneEncrypted ??
                  phonePlain ??
                  '+91 22 6752 5656')
              .toString()
              .trim();
          _companyName = (prof?['name'] ??
                  prof?['companyName'] ??
                  nameEncrypted ??
                  namePlain ??
                  '')
              .toString()
              .trim();

          if (savedEmailNotif != null) {
            _emailNotifications = savedEmailNotif == 'true';
          }
          if (savedSmsNotif != null) {
            _smsNotifications = savedSmsNotif == 'true';
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    await _storageEncrypted.write(key: key, value: value.toString());
    await _storagePlain.write(key: key, value: value.toString());
  }

  Future<void> _logout() async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out from this account?',
      confirmLabel: 'Log Out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (confirm != true || !mounted) return;

    try {
      await NotificationService.instance.handleLogout();

      await _storageEncrypted.deleteAll();
      await _storagePlain.deleteAll();
      ApiClient.accessToken = null;

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: $e')),
        );
      }
    }
  }

  void _showChangeEmailDialog() {
    final emailController = TextEditingController(text: _email);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: formKey,
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Email',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your new company email address below.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email is required';
                    if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final newEmail = emailController.text.trim();
                      await _storageEncrypted.write(key: 'email', value: newEmail);
                      await _storagePlain.write(key: 'email', value: newEmail);
                      setState(() => _email = newEmail);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email updated successfully'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.dark,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.companyPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

  void _showChangePhoneDialog() {
    final phoneController = TextEditingController(text: _phone);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: formKey,
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Phone Number',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your verified company contact phone number.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dark,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Phone number is required';
                    if (val.trim().length < 8) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final newPhone = phoneController.text.trim();
                      await _storageEncrypted.write(key: 'phone', value: newPhone);
                      await _storagePlain.write(key: 'phone', value: newPhone);
                      setState(() => _phone = newPhone);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phone number updated successfully'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.dark,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.companyPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
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
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter your current and new password.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF64748B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Current password is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20, color: Color(0xFF64748B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () => setModalState(() => obscureNew = !obscureNew),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF64748B)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val != newPasswordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.dark,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.companyPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update Password',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
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

  void _showHelpCenter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Help Centre',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Need assistance with your recruitment or site workforce management? Our support team is here to assist 24/7.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.companyTagBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.companyTagBorder),
                ),
                child: const Icon(Icons.mail_outline_rounded, color: AppColors.companyPrimaryDark, size: 22),
              ),
              title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text('support@flowhire.com', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.companyTagBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.companyTagBorder),
                ),
                child: const Icon(Icons.headset_mic_outlined, color: AppColors.companyPrimaryDark, size: 22),
              ),
              title: const Text('Helpline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: const Text('+91 1800 233 4567 (Toll Free)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.companyTagBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.companyTagBorder),
              ),
              child: const Icon(Icons.info_outline_rounded, color: AppColors.companyPrimaryDark, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'About App',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FlowHire Construction Workforce Platform',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.dark),
            ),
            SizedBox(height: 6),
            Text(
              'Version 1.0.0 (Build 100)',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            SizedBox(height: 12),
            Text(
              'Empowering construction enterprises, contractors, and specialized workforces with seamless site recruitment, verification, and automated workforce management.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.companyPrimaryDark)),
          ),
        ],
      ),
    );
  }

  void _showPolicySheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.companyTheme(context),
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 1,
          ),
        ),
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.dark, size: 19),
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
              ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.dark,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.companyPrimary,
                  strokeWidth: 3,
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      // SECTION 1: COMPANY
                      _buildSectionHeader('COMPANY'),
                      _buildCard(
                        children: [
                          _buildTile(
                            icon: Icons.domain_outlined,
                            title: 'Company Profile',
                            subtitle: 'Manage your company information',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CompanyProfileScreen(isReadOnly: false),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // SECTION 2: ACCOUNT SETTINGS
                      _buildSectionHeader('ACCOUNT SETTINGS'),
                      _buildCard(
                        children: [
                          _buildTile(
                            icon: Icons.mail_outline_rounded,
                            title: 'Change Email',
                            subtitle: _email.isNotEmpty ? _email : 'hr@ltconstruction.com',
                            onTap: _showChangeEmailDialog,
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.phone_outlined,
                            title: 'Change Phone Number',
                            subtitle: _phone.isNotEmpty ? _phone : '+91 22 6752 5656',
                            onTap: _showChangePhoneDialog,
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Change Password',
                            subtitle: 'Update your password',
                            onTap: _showChangePasswordDialog,
                          ),
                        ],
                      ),

                      // SECTION 3: NOTIFICATIONS
                      _buildSectionHeader('NOTIFICATIONS'),
                      _buildCard(
                        children: [
                          _buildSwitchTile(
                            icon: Icons.notifications_none_rounded,
                            title: 'Push Notification Email',
                            subtitle: 'Receive updates via email',
                            value: _emailNotifications,
                            onChanged: (val) {
                              setState(() => _emailNotifications = val);
                              _updateNotificationSetting('email_notif', val);
                            },
                          ),
                          _buildDivider(),
                          _buildSwitchTile(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'SMS Notification',
                            subtitle: 'Receive updates via SMS',
                            value: _smsNotifications,
                            onChanged: (val) {
                              setState(() => _smsNotifications = val);
                              _updateNotificationSetting('sms_notif', val);
                            },
                          ),
                        ],
                      ),

                      // SECTION 4: SUPPORT & LEGAL
                      _buildSectionHeader('SUPPORT & LEGAL'),
                      _buildCard(
                        children: [
                          _buildTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help Centre',
                            subtitle: 'Get help and support',
                            onTap: _showHelpCenter,
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.info_outline_rounded,
                            title: 'About',
                            subtitle: 'App version 1.0.0',
                            onTap: _showAboutDialog,
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.shield_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'How we handle your data',
                            onTap: () => _showPolicySheet(
                              'Privacy Policy',
                              'We value the trust you place in us. FlowHire is committed to protecting your privacy and personal information.\n\n'
                              '1. Information Collection\nWe collect information that you provide when registering as a company, submitting job posts, or updating verification details.\n\n'
                              '2. How We Use Data\nYour information is used strictly to authenticate your account, connect you with qualified site workers, ensure safety compliance, and facilitate direct hiring.\n\n'
                              '3. Data Protection\nAll sensitive company information and financial records are stored using encrypted industry-standard security protocols.\n\n'
                              '4. Contact Us\nFor any privacy inquiries, reach out to privacy@flowhire.com.',
                            ),
                          ),
                          _buildDivider(),
                          _buildTile(
                            icon: Icons.copyright_rounded,
                            title: 'Copyright Policy',
                            subtitle: 'Terms and conditions',
                            onTap: () => _showPolicySheet(
                              'Copyright & Terms of Service',
                              'Terms and Conditions for FlowHire Platform:\n\n'
                              '1. Intellectual Property\nAll trademarks, logos, content, software, and designs on this application are the property of FlowHire and its licensors.\n\n'
                              '2. Fair Usage\nCompanies and contractors agree to post accurate job requirements, comply with local labor regulations, and maintain respectful communication with all candidates.\n\n'
                              '3. Account Responsibility\nYou are responsible for safeguarding your login credentials and for all activities that occur under your account.\n\n'
                              '4. Updates to Terms\nWe may update these terms periodically to reflect product and regulatory changes. Continued use indicates acceptance.',
                            ),
                          ),
                        ],
                      ),

                      // SECTION 5: DANGER ZONE
                      _buildSectionHeader('DANGER ZONE', isDanger: true),
                      _buildCard(
                        children: [
                          InkWell(
                            onTap: _logout,
                            borderRadius: BorderRadius.circular(14),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 21,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: isDanger ? const Color(0xFFEF4444) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: const Color(0xFF475569),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color(0xFF475569),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.companyPrimary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
