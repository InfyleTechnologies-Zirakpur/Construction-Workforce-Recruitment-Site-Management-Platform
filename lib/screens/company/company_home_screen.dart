import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/repositories/company_repository.dart';
import '../auth/login_screen.dart';
import '../feed/feed_screen.dart';
import '../notifications/notifications_screen.dart';
import 'company_profile_screen.dart';
import 'widgets/company_analytics_view.dart';
import 'widgets/company_applications_view.dart';
import 'widgets/company_chats_view.dart';
import 'widgets/company_post_job_sheet.dart';
import 'widgets/company_site_jobs_view.dart';

class CompanyHomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const CompanyHomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  late int _tabIndex;
  bool _isLoading = true;

  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _companyJobs = [];
  List<Map<String, dynamic>> _companyConversations = [];
  Map<String, dynamic>? _myProfile;
  Map<String, dynamic>? _reportsData;

  String _appStatusFilter = 'all';
  final Set<String> _selectedAppIds = {};
  bool _isBulkAction = false;

  final _repo = CompanyRepository();

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex;
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getCompanyApplications(status: _appStatusFilter == 'all' ? null : _appStatusFilter)
            .catchError((_) => <Map<String, dynamic>>[]),
        _repo.getMyProfiles()
            .catchError((_) => <Map<String, dynamic>>[]),
        _repo.getCompanyJobs()
            .catchError((_) => <Map<String, dynamic>>[]),
        _repo.getReports()
            .catchError((_) => <String, dynamic>{}),
        _repo.getConversations()
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _applications = results[0] as List<Map<String, dynamic>>;
          final profiles = results[1] as List<Map<String, dynamic>>;
          _myProfile = profiles.isNotEmpty ? profiles.first : null;
          _companyJobs = results[2] as List<Map<String, dynamic>>;
          _reportsData = results[3] as Map<String, dynamic>;
          _companyConversations = results[4] as List<Map<String, dynamic>>;
          _selectedAppIds.clear();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Logout Company?',
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
        const storage = FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );
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

  Future<void> _publishJob(String jobId) async {
    try {
      await _repo.updateJob(jobId, {'status': 'published'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job published successfully!'), backgroundColor: Colors.green),
        );
        _loadCompanyData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish job: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _closeJob(String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Close Job Requirement', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark)),
        content: const Text('Are you sure you want to close this job posting? Workers will no longer be able to apply.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Close Job', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _repo.closeJob(jobId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job closed successfully.')),
          );
          _loadCompanyData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error closing job: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _updateAppStatus(String appId, String status, {String? remarks}) async {
    try {
      await _repo.updateApplicationStatus(appId, status: status, remark: remarks);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application $status!'), backgroundColor: Colors.green),
        );
        _loadCompanyData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _bulkShortlist() async {
    if (_selectedAppIds.isEmpty) return;
    setState(() => _isBulkAction = true);
    try {
      final res = await _repo.bulkShortlistApplications(_selectedAppIds.toList());
      if (mounted) {
        final count = res['updated'] ?? _selectedAppIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count applications shortlisted successfully!'), backgroundColor: Colors.green),
        );
        _loadCompanyData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk shortlist failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isBulkAction = false);
    }
  }

  Widget _companyHeader(TextTheme textTheme) {
    final rawName = _myProfile?['name']?.toString() ??
        _myProfile?['companyName']?.toString() ??
        _myProfile?['fullName']?.toString() ??
        'Employer Portal';
    final companyName = rawName.replaceAll(RegExp(r'\s+Admin$', caseSensitive: false), '');
    final logoUrl = _myProfile?['logoUrl']?.toString();
    final status = (_myProfile?['verificationStatus'] ?? 'pending').toString().toUpperCase();
    final statusColor = status == 'VERIFIED'
        ? Colors.green
        : (status == 'REJECTED' ? AppColors.error : Colors.orange);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
      ).then((_) => _loadCompanyData()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 22,
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.domain, color: Colors.white),
                      ),
                    )
                  : Text(
                      companyName.isNotEmpty ? companyName[0].toUpperCase() : 'C',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(companyName, style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    _myProfile == null ? 'Tap to setup company profile' : 'Manage site hiring & company details',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.business, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'BuildHire',
                style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
            tooltip: 'Company Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
            ).then((_) => _loadCompanyData()),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout Company',
            onPressed: _logout,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (idx) => setState(() => _tabIndex = idx),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.card,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed_outlined), activeIcon: Icon(Icons.dynamic_feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_ind_outlined), activeIcon: Icon(Icons.assignment_ind), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Site Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'Chats'),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? null
          : FloatingActionButton(
              onPressed: () => CompanyPostJobSheet.show(
                context,
                myProfile: _myProfile,
                onJobPosted: _loadCompanyData,
              ),
              backgroundColor: AppColors.primary,
              tooltip: 'Post Job',
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
      body: _tabIndex == 0
          ? const FeedScreen()
          : SafeArea(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadCompanyData,
                child: _isLoading
                    ? const Padding(padding: EdgeInsets.all(20), child: SmartSkeleton.list(itemCount: 4))
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _companyHeader(textTheme),
                          const SizedBox(height: 16),
                          if (_tabIndex == 1)
                            CompanyApplicationsView(
                              applications: _applications,
                              statusFilter: _appStatusFilter,
                              onStatusFilterChanged: (st) {
                                setState(() => _appStatusFilter = st);
                                _loadCompanyData();
                              },
                              selectedAppIds: _selectedAppIds,
                              isBulkAction: _isBulkAction,
                              onBulkShortlist: _bulkShortlist,
                              onUpdateStatus: _updateAppStatus,
                            )
                          else if (_tabIndex == 2)
                            CompanySiteJobsView(
                              companyJobs: _companyJobs,
                              onNewJob: () => CompanyPostJobSheet.show(
                                context,
                                myProfile: _myProfile,
                                onJobPosted: _loadCompanyData,
                              ),
                              onPublishJob: _publishJob,
                              onCloseJob: _closeJob,
                            )
                          else if (_tabIndex == 3)
                            CompanyAnalyticsView(
                              reportsData: _reportsData,
                              jobsCount: _companyJobs.length,
                              applicationsCount: _applications.length,
                            )
                          else
                            CompanyChatsView(
                              companyConversations: _companyConversations,
                              companyUserId: _myProfile?['id']?.toString(),
                              onRefresh: _loadCompanyData,
                            ),
                        ],
                      ),
              ),
            ),
    );
  }
}
