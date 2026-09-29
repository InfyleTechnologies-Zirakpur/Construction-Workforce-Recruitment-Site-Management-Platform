import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/responsive.dart';
import '../company/company_home_screen.dart';
import '../../features/repositories/company_repository.dart';

import 'company_register_screen.dart';

class CompanyLoginScreen extends StatefulWidget {
  const CompanyLoginScreen({super.key});
  @override
  State<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<CompanyLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {_loading = true; _error = null;});
    try {
      final repo = CompanyRepository();
      final data = await repo.loginCompany(email: _email.text.trim(), password: _pass.text);
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      if (data['accessToken'] != null) await storage.write(key: 'accessToken', value: data['accessToken'].toString());
      if (data['refreshToken'] != null) await storage.write(key: 'refreshToken', value: data['refreshToken'].toString());
      await storage.write(key: 'role', value: 'company');
      NotificationService.instance.syncDeviceToken();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const CompanyHomeScreen()), (_) => false);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.w(24)),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hire workers faster', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.dark, fontWeight: FontWeight.bold)),
              SizedBox(height: context.h(8)),
              Text('Sign in with your company email', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              SizedBox(height: context.h(24)),
              TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => (v??'').contains('@') ? null : 'Enter email'),
              SizedBox(height: context.h(12)),
              TextFormField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password'), validator: (v) => (v??'').length >= 8 ? null : 'Min 8 chars'),
              if (_error != null) ...[SizedBox(height: context.h(12)), Text(_error!, style: const TextStyle(color: AppColors.error))],
              SizedBox(height: context.h(24)),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _login, child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign In'))),
              SizedBox(height: context.h(12)),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CompanyRegisterScreen()),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have a company account? ",
                      style: TextStyle(color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.h(4)),
              Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to seeker login'))),
            ]),
          ),
        ),
      ),
    );
  }
}
