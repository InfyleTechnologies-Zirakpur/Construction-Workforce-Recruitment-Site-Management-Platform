import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../features/repositories/company_repository.dart';
import 'company_profile_form_screen.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _repo = CompanyRepository();
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profiles = await _repo.getMyProfiles();
      if (mounted) {
        setState(() {
          _profile = profiles.isNotEmpty ? profiles.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return AppColors.error;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Company Profile'),
        actions: [
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Company Details',
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyProfileFormScreen(profile: _profile),
                  ),
                );
                if (updated == true) _loadProfile();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                            const SizedBox(height: 12),
                            Text('Failed to load company profile', style: textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text(_error!, textAlign: TextAlign.center, style: textTheme.bodySmall),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    )
                  : _profile == null
                      ? _emptyProfileView(context, textTheme)
                      : _profileDetailView(context, textTheme, _profile!),
        ),
      ),
    );
  }

  Widget _emptyProfileView(BuildContext context, TextTheme textTheme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(context.w(24)),
      child: Container(
        padding: EdgeInsets.all(context.w(24)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.domain_add, color: AppColors.primary, size: 48),
            ),
            SizedBox(height: context.h(16)),
            Text('No Company Profile Registered', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: context.h(8)),
            Text(
              'Register your company profile to get verified, build trust with workers, and start posting job requirements.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: context.h(24)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CompanyProfileFormScreen(),
                    ),
                  );
                  if (created == true) _loadProfile();
                },
                icon: const Icon(Icons.add_business),
                label: const Text('Register Company Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileDetailView(BuildContext context, TextTheme textTheme, Map<String, dynamic> p) {
    final status = (p['verificationStatus'] ?? 'pending').toString();
    final statusColor = _getStatusColor(status);
    final specializations = (p['specializations'] is List) ? List<String>.from(p['specializations']) : <String>[];
    final operationalAreas = (p['operationalAreas'] is List) ? List<String>.from(p['operationalAreas']) : <String>[];

    return ListView(
      padding: EdgeInsets.all(context.w(20)),
      children: [
        // Header Card
        Container(
          padding: EdgeInsets.all(context.w(20)),
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: context.w(28),
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (p['name'] ?? 'C').toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: context.w(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name'] ?? 'Company Name',
                          style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        if (p['businessType'] != null)
                          Text(
                            p['businessType'].toString(),
                            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (p['verificationRemarks'] != null && p['verificationRemarks'].toString().isNotEmpty) ...[
                SizedBox(height: context.h(12)),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: statusColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p['verificationRemarks'].toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: context.h(16)),

        // Overview / Description Card
        if (p['description'] != null && p['description'].toString().isNotEmpty) ...[
          _sectionCard(
            title: 'About Company',
            icon: Icons.description_outlined,
            textTheme: textTheme,
            child: Text(p['description'].toString(), style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ),
          SizedBox(height: context.h(16)),
        ],

        // Contact Information Card
        _sectionCard(
          title: 'Contact Details',
          icon: Icons.contact_phone_outlined,
          textTheme: textTheme,
          child: Column(
            children: [
              _infoRow('Email', p['contactEmail'] ?? 'N/A', Icons.email_outlined),
              _infoRow('Phone', p['contactPhone'] ?? 'N/A', Icons.phone_outlined),
              if (p['alternatePhone'] != null) _infoRow('Alt Phone', p['alternatePhone'].toString(), Icons.phone_callback_outlined),
              if (p['website'] != null) _infoRow('Website', p['website'].toString(), Icons.language_outlined),
              _infoRow('Address', '${p['address'] ?? ''}, ${p['city'] ?? ''}, ${p['state'] ?? ''} ${p['pincode'] ?? ''}'.trim(), Icons.location_on_outlined),
            ],
          ),
        ),

        SizedBox(height: context.h(16)),

        // Legal & Tax Info Card
        _sectionCard(
          title: 'Legal & Verification Info',
          icon: Icons.verified_user_outlined,
          textTheme: textTheme,
          child: Column(
            children: [
              _infoRow('Registration No. (CIN)', p['registrationNumber'] ?? 'Not provided', Icons.badge_outlined),
              _infoRow('GST Number', p['gstNumber'] ?? 'Not provided', Icons.receipt_long_outlined),
              _infoRow('PAN Number', p['panNumber'] ?? 'Not provided', Icons.credit_card_outlined),
              if (p['yearEstablished'] != null) _infoRow('Established Year', p['yearEstablished'].toString(), Icons.calendar_today_outlined),
              if (p['teamSizeRange'] != null) _infoRow('Team Size', p['teamSizeRange'].toString(), Icons.groups_outlined),
            ],
          ),
        ),

        if (specializations.isNotEmpty || operationalAreas.isNotEmpty) ...[
          SizedBox(height: context.h(16)),
          _sectionCard(
            title: 'Specializations & Operational Areas',
            icon: Icons.handyman_outlined,
            textTheme: textTheme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (specializations.isNotEmpty) ...[
                  Text('Specializations', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: specializations.map((s) => _chip(s, AppColors.primary)).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (operationalAreas.isNotEmpty) ...[
                  Text('Operational Areas', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: operationalAreas.map((a) => _chip(a, AppColors.dark)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],

        SizedBox(height: context.h(24)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanyProfileFormScreen(profile: p),
                ),
              );
              if (updated == true) _loadProfile();
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Company Profile'),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required TextTheme textTheme, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark)),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
