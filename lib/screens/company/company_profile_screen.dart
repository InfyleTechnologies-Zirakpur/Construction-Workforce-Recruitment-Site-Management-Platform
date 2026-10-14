import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../features/repositories/company_repository.dart';
import '../../features/repositories/worker_repository.dart';
import '../auth/login_screen.dart';
import 'company_profile_form_screen.dart';
import 'widgets/company_app_bar.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _repo = CompanyRepository();
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
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

  Future<void> _uploadLogo() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await image.readAsBytes();
      final url = await WorkerRepository().uploadProfilePhoto(
        bytes: bytes,
        filename: image.name,
      );

      if (url.isNotEmpty && _profile != null) {
        final profileId = (_profile!['id'] ?? _profile!['_id'])?.toString();
        if (profileId != null) {
          await _repo.updateCompanyProfile(profileId, {'logoUrl': url});
        }
        if (mounted) {
          _showMessage('Company logo updated successfully.');
          _loadProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Logo upload failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _editProfile(Map<String, dynamic> p) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyProfileFormScreen(profile: p),
      ),
    );
    if (updated == true) _loadProfile();
  }

  Future<void> _logout() async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Log Out Company?',
      message: 'Are you sure you want to log out of your employer portal?',
      confirmLabel: 'Log Out',
      cancelLabel: 'Cancel',
      icon: Icons.logout_rounded,
      isDestructive: false,
    );

    if (confirm && mounted) {
      try {
        await NotificationService.instance.handleLogout();
      } catch (_) {}
      try {
        const storage = FlutterSecureStorage();
        String? fcmToken;
        try {
          fcmToken = await storage.read(key: 'fcmDeviceToken');
        } catch (_) {}
        try {
          await _repo.logout(fcmToken: fcmToken);
        } catch (_) {}
        await storage.deleteAll();
      } catch (_) {}

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return const Color(0xFF4ADE80);
      case 'rejected':
        return AppColors.error;
      case 'pending':
      default:
        return const Color(0xFFFBBF24);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CompanyAppBar(
        showBackButton: true,
        showNotifications: false,
        showProfileAvatar: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadProfile,
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3.5,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading company profile...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: AppColors.peachBackground,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Unable to load company profile',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Try Again'),
                            ),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: EdgeInsets.all(context.w(24)),
          children: [
            Container(
              padding: EdgeInsets.all(context.w(24)),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
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
                  Text(
                    'No Company Profile Registered',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: context.h(8)),
                  Text(
                    'Register your company profile to get verified, build trust with workers, and start posting job requirements.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: context.h(24)),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_business, size: 18),
                      label: const Text(
                        'Register Company Profile',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.peachBackground,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.peachBorder,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, color: AppColors.primary, size: 18),
                      label: const Text(
                        'Log Out Company',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileDetailView(BuildContext context, TextTheme textTheme, Map<String, dynamic> p) {
    final status = (p['verificationStatus'] ?? 'pending').toString().toLowerCase();
    final statusColor = _getStatusColor(status);
    final isVerified = status == 'verified';
    final companyName = (p['name'] ?? 'Company').toString().trim();
    final logoUrl = (p['logoUrl'] ?? p['avatarUrl'])?.toString().trim();
    final businessType = p['businessType']?.toString().trim() ?? 'Company';
    final city = p['city']?.toString().trim() ?? '';
    final state = p['state']?.toString().trim() ?? '';
    final location = [city, state].where((s) => s.isNotEmpty).join(', ');

    final specializations = (p['specializations'] is List)
        ? List<String>.from(p['specializations'])
        : <String>[];
    final operationalAreas = (p['operationalAreas'] is List)
        ? List<String>.from(p['operationalAreas'])
        : <String>[];
    final teamSize = p['teamSizeRange']?.toString().trim() ?? 'N/A';
    final yearEstablished = p['yearEstablished']?.toString().trim() ?? 'N/A';
    final fullAddress = [
      p['address']?.toString().trim(),
      city,
      state,
      p['pincode']?.toString().trim(),
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // 1. Profile Header Card (Inspired by Job Seeker ProfileHeaderCard)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.dark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar with Camera Edit Icon overlay
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 2.5,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 34,
                              backgroundColor: const Color(0xFF1F2937),
                              backgroundImage: logoUrl != null && logoUrl.startsWith('http')
                                  ? NetworkImage(logoUrl)
                                  : null,
                              child: (logoUrl == null || !logoUrl.startsWith('http'))
                                  ? Center(
                                      child: Text(
                                        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isUploadingPhoto ? null : _uploadLogo,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.dark, width: 2),
                                  ),
                                  child: _isUploadingPhoto
                                      ? const SizedBox(
                                          height: 14,
                                          width: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      businessType,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isVerified
                                            ? Icons.verified_rounded
                                            : Icons.schedule_rounded,
                                        size: 12,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (location.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (p['verificationRemarks'] != null &&
                      p['verificationRemarks'].toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
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
            const SizedBox(height: 16),

            // 2. Summary Stats Bar (Inspired by ProfileStatsBar)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildStatColumn('Team Size', teamSize, Icons.groups_outlined),
                  _buildDivider(),
                  _buildStatColumn(
                    'Specializations',
                    '${specializations.length} Trades',
                    Icons.construction_outlined,
                  ),
                  _buildDivider(),
                  _buildStatColumn(
                    'Established',
                    yearEstablished,
                    Icons.calendar_today_outlined,
                  ),
                ],
              ),
            ),

            // 3. Overview / About Company Card
            if (p['description'] != null && p['description'].toString().trim().isNotEmpty) ...[
              _buildSectionCard(
                icon: Icons.info_outline_rounded,
                title: 'About Company',
                child: Text(
                  p['description'].toString().trim(),
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4. Contact Details Card (Inspired by ProfileDetailsCard)
            _buildSectionCard(
              icon: Icons.contact_phone_outlined,
              title: 'Contact Details',
              onEdit: () => _editProfile(p),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.email_outlined,
                    label: 'Contact Email',
                    value: p['contactEmail']?.toString() ?? 'Not provided',
                  ),
                  const Divider(height: 16, color: AppColors.border),
                  _buildDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Primary Phone',
                    value: p['contactPhone']?.toString() ?? 'Not provided',
                  ),
                  if (p['alternatePhone'] != null &&
                      p['alternatePhone'].toString().trim().isNotEmpty) ...[
                    const Divider(height: 16, color: AppColors.border),
                    _buildDetailRow(
                      icon: Icons.phone_callback_outlined,
                      label: 'Alternate Phone',
                      value: p['alternatePhone'].toString(),
                    ),
                  ],
                  if (p['website'] != null && p['website'].toString().trim().isNotEmpty) ...[
                    const Divider(height: 16, color: AppColors.border),
                    _buildDetailRow(
                      icon: Icons.language_outlined,
                      label: 'Official Website',
                      value: p['website'].toString(),
                    ),
                  ],
                  if (fullAddress.isNotEmpty) ...[
                    const Divider(height: 16, color: AppColors.border),
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Registered Office',
                      value: fullAddress,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Legal & Compliance Card
            _buildSectionCard(
              icon: Icons.verified_user_outlined,
              title: 'Legal & Verification',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isVerified ? const Color(0xFFDCFCE7) : AppColors.peachBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isVerified ? const Color(0xFF86EFAC) : AppColors.peachBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isVerified ? const Color(0xFF15803D) : AppColors.peachText,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.badge_outlined,
                    label: 'CIN / Registration No.',
                    value: p['registrationNumber']?.toString() ?? 'Not provided',
                  ),
                  const Divider(height: 16, color: AppColors.border),
                  _buildDetailRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'GST Number (GSTIN)',
                    value: p['gstNumber']?.toString() ?? 'Not provided',
                  ),
                  const Divider(height: 16, color: AppColors.border),
                  _buildDetailRow(
                    icon: Icons.credit_card_outlined,
                    label: 'PAN Number',
                    value: p['panNumber']?.toString() ?? 'Not provided',
                  ),
                  const Divider(height: 16, color: AppColors.border),
                  _buildDetailRow(
                    icon: Icons.business_outlined,
                    label: 'Business Entity Type',
                    value: businessType,
                  ),
                ],
              ),
            ),

            // 6. Specializations & Coverage Card
            if (specializations.isNotEmpty || operationalAreas.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionCard(
                icon: Icons.handyman_outlined,
                title: 'Trades & Operations',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (specializations.isNotEmpty) ...[
                      const Text(
                        'Project Specializations',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: specializations.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.peachBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.peachBorder, width: 0.8),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.peachText,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (specializations.isNotEmpty && operationalAreas.isNotEmpty)
                      const SizedBox(height: 14),
                    if (operationalAreas.isNotEmpty) ...[
                      const Text(
                        'Operational Areas',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: operationalAreas.map((a) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                            ),
                            child: Text(
                              a,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 7. Edit Profile Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _editProfile(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  'Edit Company Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 8. Log Out Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.peachBackground,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.peachBorder,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                label: const Text(
                  'Log Out Company',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    VoidCallback? onEdit,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.peachBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (trailing != null)
                trailing,
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.peachBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
