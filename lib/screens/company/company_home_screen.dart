import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/repositories/company_repository.dart';
import '../auth/login_screen.dart';
import '../messages/messages_screen.dart';
import '../notifications/notifications_screen.dart';
import '../feed/feed_screen.dart';
import 'company_profile_screen.dart';
import 'company_profile_form_screen.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  int _tabIndex = 0;
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
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Logout Company', style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your company portal?', style: TextStyle(color: AppColors.dark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Full server logout for company role:
      // 1. unregister FCM device + POST /auth/logout (updates company
      //    presence state on backend) while token still stored.
      // 2. wipe secure storage + reset AuthCubit state.
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

  // --- JOB ACTIONS ---

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
        title: const Text('Close Job Requirement'),
        content: const Text('Are you sure you want to close this job posting? Workers will no longer be able to apply.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Close Job'),
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

  // --- APPLICATION ACTIONS ---

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

  void _showApplicationDetailsModal(Map<String, dynamic> app) {
    final user = app['user'] is Map ? app['user'] : <String, dynamic>{};
    final job = app['job'] is Map ? app['job'] : <String, dynamic>{};
    final remarksController = TextEditingController(text: app['reviewRemarks']?.toString() ?? '');
    final appId = app['id']?.toString() ?? '';
    final status = (app['status'] ?? 'pending').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Candidate Review', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                    ],
                  ),
                  const Divider(height: 20),

                  // Worker Profile
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['fullName'] ?? user['name'] ?? 'Worker Candidate', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Applied for: ${job['title'] ?? 'Site Job'}', style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _modalDetailRow(Icons.phone, 'Contact Phone', user['phone'] ?? app['contactPhone'] ?? 'N/A'),
                  _modalDetailRow(Icons.currency_rupee, 'Expected Daily Wage', '₹ ${app['expectedDailyWage'] ?? 'As per posting'}'),
                  _modalDetailRow(Icons.history, 'Experience', '${app['experienceYears'] ?? 0} Years'),
                  _modalDetailRow(Icons.calendar_month, 'Available From', app['availableFrom']?.toString() ?? 'Immediate'),

                  if (app['coverNote'] != null && app['coverNote'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Cover Note:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(app['coverNote'].toString(), style: const TextStyle(fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextField(
                    controller: remarksController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      labelText: 'Remark (sent as chat message)',
                      hintText: 'e.g. We\'d like to invite you for an interview on Monday at 10 AM.',
                      helperText: 'This will be sent as the first message in your conversation with the candidate.',
                      helperMaxLines: 2,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Change Status:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.dark),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusFgColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Reject Button
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              _updateAppStatus(appId, 'rejected', remarks: remarksController.text.trim());
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              backgroundColor: status == 'rejected' ? const Color(0xFFFEE2E2) : Colors.white,
                              side: BorderSide(
                                color: status == 'rejected' ? const Color(0xFFDC2626) : const Color(0xFFEF4444),
                                width: status == 'rejected' ? 1.8 : 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Reject',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFDC2626)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Shortlist Button
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              _updateAppStatus(appId, 'shortlisted', remarks: remarksController.text.trim());
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD97706),
                              backgroundColor: status == 'shortlisted' ? const Color(0xFFFEF3C7) : Colors.white,
                              side: BorderSide(
                                color: status == 'shortlisted' ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                                width: status == 'shortlisted' ? 1.8 : 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.star_outline_rounded, size: 16, color: Color(0xFFD97706)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Shortlist',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFD97706)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Accept Button
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              _updateAppStatus(appId, 'accepted', remarks: remarksController.text.trim());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Accept',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalDetailRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showPostJobModal() {
    if (_myProfile == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Company Profile Required'),
          content: const Text('You must register your company profile credentials before posting job requirements on the platform.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompanyProfileFormScreen()),
                ).then((_) => _loadCompanyData());
              },
              child: const Text('Setup Profile'),
            ),
          ],
        ),
      );
      return;
    }

    final title = TextEditingController();
    final location = TextEditingController();
    final compensation = TextEditingController();
    final workforce = TextEditingController(text: '5');
    final skills = TextEditingController();
    final description = TextEditingController();
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Post New Job Requirement', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Job Title *', hintText: 'e.g. Senior Site Mason')),
                  const SizedBox(height: 10),
                  TextField(controller: location, decoration: const InputDecoration(labelText: 'Location / Site *', hintText: 'e.g. Mohali Sector 82')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: compensation,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Daily Pay (₹)', prefixText: '₹ '),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: workforce,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Workers Needed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: skills, decoration: const InputDecoration(labelText: 'Skills Required', hintText: 'Masonry, Formwork, Plastering')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Job Description & Site Requirements'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isPosting
                          ? null
                          : () async {
                              if (title.text.trim().isEmpty || location.text.trim().isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Title and location are required.')));
                                return;
                              }
                              setModalState(() => isPosting = true);
                              try {
                                await _repo.createJob({
                                  'title': title.text.trim(),
                                  'location': location.text.trim(),
                                  'compensation': num.tryParse(compensation.text.trim()) ?? 1000,
                                  'workforceRequired': int.tryParse(workforce.text.trim()) ?? 1,
                                  'skills': skills.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                                  'description': description.text.trim(),
                                });
                                if (mounted) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job requirements posted successfully!')));
                                  _loadCompanyData();
                                }
                              } catch (e) {
                                setModalState(() => isPosting = false);
                                final errStr = e.toString();
                                if (errStr.contains('Company profile not found')) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please complete your company profile first.'), backgroundColor: Colors.orange),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CompanyProfileFormScreen()),
                                  ).then((_) => _loadCompanyData());
                                } else {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Posting failed: $e'), backgroundColor: AppColors.error));
                                }
                              }
                            },
                      child: isPosting ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish Requirement'),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        title: Row(
          children: [
            const Icon(Icons.business, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'BuildHire',
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
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
        unselectedItemColor: Colors.black54,
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
              onPressed: _showPostJobModal,
              backgroundColor: AppColors.primary,
              tooltip: 'Post Job',
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
      body: _tabIndex == 0
          ? const FeedScreen()
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadCompanyData,
                child: _isLoading
                    ? const Padding(padding: EdgeInsets.all(20), child: SmartSkeleton.list(itemCount: 4))
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _companyHeader(textTheme),
                          const SizedBox(height: 16),

                          if (_tabIndex == 1) ...[
                            _applicationsTab(textTheme),
                          ] else if (_tabIndex == 2) ...[
                            _siteJobsTab(textTheme),
                          ] else if (_tabIndex == 3) ...[
                            _analyticsTab(textTheme),
                          ] else ...[
                            _chatsTab(textTheme),
                          ],
                        ],
                      ),
              ),
            ),

    );
  }

  Widget _chatsTab(TextTheme textTheme) {
    if (_companyConversations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('No applicant chats yet', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'When you update an application status with a remark, a conversation will be created here with the candidate.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final companyUserId = _myProfile?['id']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Applicant Chats (${_companyConversations.length})',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _loadCompanyData,
              tooltip: 'Refresh chats',
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._companyConversations.map((map) {
          final conv = Conversation.fromJson(map, currentUserId: companyUserId);
          final seekerName = conv.company.isNotEmpty ? conv.company : 'Applicant';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(conversation: conv, isCompany: true),
                  ),
                ).then((_) => _loadCompanyData());
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.dark,
                      child: Text(
                        seekerName.isNotEmpty ? seekerName[0].toUpperCase() : 'A',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  seekerName,
                                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (conv.lastMessageAt.isNotEmpty)
                                Text(conv.lastMessageAt, style: textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            conv.jobTitle,
                            style: textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conv.lastMessage.isNotEmpty ? conv.lastMessage : 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (conv.unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            '${conv.unreadCount}',
                            style: textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _companyHeader(TextTheme textTheme) {
    final rawName = _myProfile?['name']?.toString() ?? _myProfile?['companyName']?.toString() ?? _myProfile?['fullName']?.toString() ?? 'Employer Portal';
    final companyName = rawName.replaceAll(RegExp(r'\s+Admin$', caseSensitive: false), '');
    final logoUrl = _myProfile?['logoUrl']?.toString();
    final status = (_myProfile?['verificationStatus'] ?? 'pending').toString().toUpperCase();
    final statusColor = status == 'VERIFIED' ? Colors.green : (status == 'REJECTED' ? AppColors.error : Colors.orange);

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
                  ? ClipOval(child: Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.domain, color: Colors.white)))
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

  // --- TAB 1: APPLICATIONS LIST ---

  Widget _applicationsTab(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Applications (${_applications.length})', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (_selectedAppIds.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _isBulkAction ? null : _bulkShortlist,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                icon: const Icon(Icons.done_all, size: 16),
                label: Text('Shortlist (${_selectedAppIds.length})', style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['all', 'pending', 'shortlisted', 'accepted', 'rejected'].map((st) {
              final isSel = _appStatusFilter == st;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(st.toUpperCase(), style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.dark, fontWeight: FontWeight.bold)),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _appStatusFilter = st);
                      _loadCompanyData();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        if (_applications.isEmpty)
          _emptyCard(textTheme, 'No Applications Found', 'Post a job requirement or change filter to view candidates.')
        else
          ..._applications.map((app) => _applicationCard(app, textTheme)),
      ],
    );
  }

  Widget _applicationCard(Map<String, dynamic> app, TextTheme textTheme) {
    final user = app['user'] is Map ? app['user'] : <String, dynamic>{};
    final job = app['job'] is Map ? app['job'] : <String, dynamic>{};
    final userName = user['fullName'] ?? user['name'] ?? 'Worker Candidate';
    final userPhone = user['phone'] ?? app['contactPhone'] ?? 'N/A';
    final jobTitle = job['title'] ?? 'Construction Role';
    final status = (app['status'] ?? 'pending').toString();

    return InkWell(
      onTap: () => _showApplicationDetailsModal(app),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                const CircleAvatar(
                  backgroundColor: Colors.black12,
                  child: Icon(Icons.person, color: AppColors.dark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Role: $jobTitle', style: textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusFgColor(status))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (app['coverNote'] != null && app['coverNote'].toString().isNotEmpty) ...[
              Text('Cover Note: ${app['coverNote']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(userPhone, style: textTheme.bodySmall),
                  ],
                ),
                Text('Tap to review candidate →', style: textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: SITE JOBS LIST ---

  Widget _siteJobsTab(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Posted Site Jobs (${_companyJobs.length})', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _showPostJobModal,
              icon: const Icon(Icons.add),
              label: const Text('New Job'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_companyJobs.isEmpty)
          _emptyCard(textTheme, 'No Jobs Posted Yet', 'Create a new job requirement to start receiving worker applications.')
        else
          ..._companyJobs.map((job) => _jobCard(job, textTheme)),
      ],
    );
  }

  Widget _jobCard(Map<String, dynamic> job, TextTheme textTheme) {
    final jobId = job['id']?.toString() ?? '';
    final title = job['title']?.toString() ?? 'Job Requirement';
    final location = job['location']?.toString() ?? 'Location N/A';
    final pay = job['compensation'] ?? job['dailyPay'] ?? 0;
    final status = (job['status'] ?? 'draft').toString();
    final headcount = job['workforceRequired'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusFgColor(status))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(location, style: textTheme.bodySmall),
              const SizedBox(width: 14),
              const Icon(Icons.groups_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('$headcount Workers', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text('Daily Pay: ₹ $pay / day', style: textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          const Divider(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'draft')
                ElevatedButton.icon(
                  onPressed: () => _publishJob(jobId),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  icon: const Icon(Icons.publish, size: 14),
                  label: const Text('Publish Job', style: TextStyle(fontSize: 12)),
                ),
              if (status == 'published') ...[
                OutlinedButton.icon(
                  onPressed: () => _closeJob(jobId),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  icon: const Icon(Icons.block, size: 14),
                  label: const Text('Close Job', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 3: ANALYTICS REPORT ---

  Widget _analyticsTab(TextTheme textTheme) {
    var d = _reportsData ?? {};
    if (d['data'] is Map) {
      d = Map<String, dynamic>.from(d['data']);
    }
    final totalJobs = d['totalJobs'] ?? _companyJobs.length;
    final totalApps = d['totalApplications'] ?? _applications.length;
    final avgApps = d['averageApplicationsPerJob'] ?? 0;
    final funnel = d['funnel'] is Map ? Map<String, dynamic>.from(d['funnel']) : <String, dynamic>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hiring Overview & Funnel Analytics', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        Row(
          children: [
            _statTile('Total Jobs', '$totalJobs', Icons.work_outline, AppColors.primary),
            const SizedBox(width: 10),
            _statTile('Applications', '$totalApps', Icons.people_outline, Colors.blue),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statTile('Avg Applicants/Job', '$avgApps', Icons.analytics_outlined, Colors.purple),
          ],
        ),
        const SizedBox(height: 18),

        Text('Recruitment Funnel Stage Stats', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        _funnelBar('Pending Review', funnel['pending'] ?? 0, totalApps, Colors.orange),
        _funnelBar('Shortlisted', funnel['shortlisted'] ?? 0, totalApps, Colors.blue),
        _funnelBar('Accepted / Hired', funnel['accepted'] ?? 0, totalApps, Colors.green),
        _funnelBar('Rejected', funnel['rejected'] ?? 0, totalApps, AppColors.error),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _funnelBar(String label, dynamic countVal, dynamic totalVal, Color color) {
    final count = num.tryParse(countVal.toString()) ?? 0;
    final total = num.tryParse(totalVal.toString()) ?? 1;
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$count Candidate(s)', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio.toDouble(),
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
    
  }

  Widget _emptyCard(TextTheme textTheme, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 44, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: textTheme.bodySmall),
        ],
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
      case 'accepted':
        return Colors.green.withValues(alpha: 0.12);
      case 'shortlisted':
        return Colors.blue.withValues(alpha: 0.12);
      case 'closed':
      case 'rejected':
        return AppColors.error.withValues(alpha: 0.12);
      case 'draft':
      case 'pending':
      default:
        return Colors.orange.withValues(alpha: 0.12);
    }
  }

  Color _getStatusFgColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
      case 'accepted':
        return Colors.green;
      case 'shortlisted':
        return Colors.blue;
      case 'closed':
      case 'rejected':
        return AppColors.error;
      case 'draft':
      case 'pending':
      default:
        return Colors.orange.shade800;
    }
  }
}
