import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/company_repository.dart';
import '../auth/login_screen.dart';
import '../feed/feed_screen.dart';
import 'company_profile_form_screen.dart';
import 'company_profile_screen.dart';
import 'widgets/company_analytics_view.dart';
import 'widgets/company_app_bar.dart';
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
    context.read<NotificationsCubit>().load();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repo.getCompanyApplications(limit: 100)
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
        final rawApps = results[0] as List<Map<String, dynamic>>;
        final profiles = results[1] as List<Map<String, dynamic>>;
        final myProfile = profiles.isNotEmpty ? profiles.first : null;
        final rawJobs = results[2] as List<Map<String, dynamic>>;
        final reportsData = results[3] as Map<String, dynamic>;
        final conversations = results[4] as List<Map<String, dynamic>>;

        final myCompanyId = (myProfile?['id'] ?? myProfile?['_id'])?.toString().trim();
        final myCompanyName = myProfile?['name']?.toString().toLowerCase().trim();

        // 1. Filter jobs that belong to this company
        List<Map<String, dynamic>> companyJobs = rawJobs;
        if (myCompanyId != null && myCompanyId.isNotEmpty) {
          final matchedJobs = rawJobs.where((j) {
            final c = j['company'];
            final cId = (j['companyId'] ?? (c is Map ? (c['id'] ?? c['_id']) : null))?.toString().trim();
            final cName = (c is Map ? c['name'] : null)?.toString().toLowerCase().trim();
            return (cId != null && cId == myCompanyId) || (myCompanyName != null && cName != null && cName == myCompanyName);
          }).toList();
          if (matchedJobs.isNotEmpty) {
            companyJobs = matchedJobs;
          }
        }

        // 2. Collect all job IDs belonging to this company
        final companyJobIds = companyJobs
            .map((j) => (j['id'] ?? j['_id'] ?? j['jobId'])?.toString().trim())
            .where((id) => id != null && id.isNotEmpty)
            .toSet();

        // 3. Filter applications to only those submitted for this company's jobs
        List<Map<String, dynamic>> companyApps = rawApps;
        if (myCompanyId != null && myCompanyId.isNotEmpty) {
          companyApps = rawApps.where((app) {
            final rawJob = app['job'];
            final appJob = rawJob is Map ? rawJob as Map<String, dynamic> : <String, dynamic>{};
            final appJobId = (app['jobId'] ?? app['job_id'] ?? (rawJob is String ? rawJob : (appJob['id'] ?? appJob['_id'])))?.toString().trim();

            if (appJobId != null && companyJobIds.contains(appJobId)) {
              return true;
            }

            final appCompany = appJob['company'];
            final appCompId = (appJob['companyId'] ?? (appCompany is Map ? (appCompany['id'] ?? appCompany['_id']) : null))?.toString().trim();
            final appCompName = (appCompany is Map ? appCompany['name'] : null)?.toString().toLowerCase().trim();
            if (appCompId != null && appCompId == myCompanyId) return true;
            if (myCompanyName != null && appCompName != null && appCompName == myCompanyName) return true;

            return false;
          }).toList();
        }

        setState(() {
          _applications = companyApps;
          _myProfile = myProfile;
          _companyJobs = companyJobs;
          _reportsData = reportsData;
          _companyConversations = conversations;
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
      title: 'Log Out Company?',
      message: 'Are you sure you want to log out of your employer portal?',
      confirmLabel: 'Log Out',
      cancelLabel: 'Cancel',
      icon: Icons.logout_rounded,
      isDestructive: false,
      isCompany: true,
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
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Close Job Requirement?',
      message:
          'Are you sure you want to close this job posting? Workers will no longer be able to apply.',
      confirmLabel: 'Close Job',
      cancelLabel: 'Cancel',
      icon: Icons.work_off_rounded,
      isDestructive: false,
      isCompany: true,
    );

    if (confirm && mounted) {
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

  Future<void> _updateAppStatus(
    String appId,
    String status, {
    String? remarks,
    Map<String, dynamic>? app,
  }) async {
    final note = remarks?.trim();
    try {
      await _repo.updateApplicationStatus(appId, status: status, remark: note);

   
      final targetApp = app ??
          _applications.firstWhere(
            (a) => (a['id'] ?? a['_id'])?.toString() == appId,
            orElse: () => <String, dynamic>{},
          );

      final rawJob = targetApp['job'];
      final jobMap = rawJob is Map ? Map<String, dynamic>.from(rawJob) : <String, dynamic>{};
      final jobId = (targetApp['jobId'] ?? jobMap['id'] ?? jobMap['_id'])?.toString() ?? '';
      final jobTitle = (jobMap['title'] ?? targetApp['jobTitle'] ?? 'Job').toString();

      final rawUser = targetApp['user'] ?? targetApp['worker'] ?? targetApp['seeker'];
      final userMap = rawUser is Map ? Map<String, dynamic>.from(rawUser) : <String, dynamic>{};
      final candidateUserId = (targetApp['userId'] ?? userMap['id'] ?? userMap['_id'] ?? targetApp['seekerId'])?.toString();

      // If remarks were entered, send them as chat message & notification
      if (note != null && note.isNotEmpty) {
        final statusCapitalized = status.substring(0, 1).toUpperCase() + status.substring(1);
        final chatText = 'Application $statusCapitalized: $note';

        // 1. Send as chat message if conversation exists or can be matched
        try {
          Map<String, dynamic>? matchedConv;
          for (final conv in _companyConversations) {
            final convAppId = conv['applicationId']?.toString();
            final convJobId = (conv['jobId'] ?? (conv['job'] is Map ? conv['job']['id'] : null))?.toString();
            final convSeekerId = (conv['seekerId'] ??
                    (conv['seeker'] is Map ? conv['seeker']['id'] : null) ??
                    conv['userId'])
                ?.toString();

            if (convAppId != null && convAppId.isNotEmpty && convAppId == appId) {
              matchedConv = conv;
              break;
            }
            if (candidateUserId != null &&
                candidateUserId.isNotEmpty &&
                convSeekerId == candidateUserId) {
              if (jobId.isEmpty || convJobId == null || convJobId.isEmpty || convJobId == jobId) {
                matchedConv = conv;
                break;
              }
            }
          }

          if (matchedConv != null) {
            final convId = matchedConv['id']?.toString() ?? '';
            if (convId.isNotEmpty) {
              await _repo.sendMessage(convId, chatText);
            }
          } else {
            // Attempt to dispatch to conversation ID = appId in case backend matches conversation to application
            try {
              await _repo.sendMessage(appId, chatText);
            } catch (_) {}
          }
        } catch (_) {}

        // 2. Dispatch in-app notification directly to candidate
        if (candidateUserId != null && candidateUserId.isNotEmpty) {
          try {
            await _repo.sendNotification(
              title: 'Application $statusCapitalized: $jobTitle',
              body: note,
              event: 'application_update',
              userIds: [candidateUserId],
              referenceId: appId,
            );
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          for (final a in _applications) {
            if ((a['id'] ?? a['_id'])?.toString() == appId) {
              a['status'] = status;
              if (note != null && note.isNotEmpty) {
                a['reviewRemarks'] = note;
                a['remark'] = note;
              }
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(note != null && note.isNotEmpty
                ? 'Application $status & remarks sent to candidate!'
                : 'Application $status!'),
            backgroundColor: Colors.green,
          ),
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

  bool get _isCompanyVerified {
    final status = (_myProfile?['verificationStatus'] ?? 'pending').toString().toLowerCase().trim();
    return status == 'verified' || status == 'approved' || status == 'completed';
  }

  Widget _companyHeader(TextTheme textTheme) {
    if (_isCompanyVerified) return const SizedBox.shrink();

    final hasProfile = _myProfile != null;
    final rawName = _myProfile?['name']?.toString() ??
        _myProfile?['companyName']?.toString() ??
        _myProfile?['fullName']?.toString() ??
        'Company Profile';
    final companyName = rawName.replaceAll(RegExp(r'\s+Admin$', caseSensitive: false), '');
    final status = hasProfile
        ? (_myProfile?['verificationStatus'] ?? 'pending').toString().toUpperCase()
        : 'REQUIRED';
    final statusColor = !hasProfile
        ? AppColors.companyPrimary
        : (status == 'VERIFIED'
            ? AppColors.success
            : (status == 'REJECTED' ? AppColors.error : const Color(0xFFF59E0B)));

    return InkWell(
      onTap: () async {
        if (!hasProfile) {
          final shouldSetup = await AppConfirmDialog.show(
            context,
            title: 'Company Profile Required',
            message:
                'You must register your company profile credentials before posting job requirements on the platform.',
            confirmLabel: 'Setup Profile',
            cancelLabel: 'Cancel',
            icon: Icons.business_rounded,
            isDestructive: false,
          );
          if (shouldSetup && mounted) {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const CompanyProfileFormScreen()),
            );
            if (created == true && mounted) _loadCompanyData();
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
          ).then((_) => _loadCompanyData());
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/company_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.dark,
                        AppColors.dark.withValues(alpha: 0.94),
                        AppColors.dark.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: !hasProfile ? AppColors.companyTagBackground : AppColors.companyPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        !hasProfile ? Icons.domain_add_rounded : Icons.apartment_rounded,
                        color: !hasProfile ? AppColors.companyPrimary : Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hasProfile ? companyName : 'Complete Profile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasProfile
                                ? 'Manage site hiring & company details'
                                : 'Set up credentials to start posting job requirements',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                      size: 20,
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
    final textTheme = Theme.of(context).textTheme;

    return Theme(
      data: AppTheme.companyTheme(context),
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: CompanyAppBar(
        logoUrl: _myProfile?['logoUrl']?.toString() ??
            _myProfile?['avatarUrl']?.toString() ??
            _myProfile?['logo']?.toString() ??
            _myProfile?['avatar']?.toString() ??
            _myProfile?['profileImage']?.toString() ??
            _myProfile?['imageUrl']?.toString() ??
            _myProfile?['image']?.toString() ??
            (_myProfile?['user'] is Map
                ? (_myProfile!['user']['avatarUrl'] ?? _myProfile!['user']['avatar'])?.toString()
                : null),
        companyName: _myProfile?['name']?.toString() ??
            _myProfile?['companyName']?.toString() ??
            _myProfile?['businessName']?.toString(),
        onProfileTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
        ).then((_) => _loadCompanyData()),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (idx) => setState(() => _tabIndex = idx),
          selectedItemColor: AppColors.companyPrimary,
          unselectedItemColor: const Color(0xFF6B7280),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.home_outlined, size: 23),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.home, size: 23, color: AppColors.companyPrimary),
              ),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.group_outlined, size: 23),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.group, size: 23, color: AppColors.companyPrimary),
              ),
              label: 'Applications',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.business_center_outlined, size: 23),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.business_center, size: 23, color: AppColors.companyPrimary),
              ),
              label: 'Site Jobs',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.bar_chart_rounded, size: 23),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.bar_chart_rounded, size: 23, color: AppColors.companyPrimary),
              ),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.chat_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.chat, size: 22, color: AppColors.companyPrimary),
              ),
              label: 'Chats',
            ),
          ],
        ),
      ),
      floatingActionButton: (_tabIndex == 1 || _tabIndex == 2)
          ? FloatingActionButton(
              onPressed: () => CompanyPostJobSheet.show(
                context,
                myProfile: _myProfile,
                onJobPosted: _loadCompanyData,
              ),
              backgroundColor: AppColors.companyPrimary,
              tooltip: 'Post Job',
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      body: _tabIndex == 0
          ? const FeedScreen(isCompany: true)
          : SafeArea(
              child: RefreshIndicator(
                color: AppColors.companyPrimary,
                onRefresh: _loadCompanyData,
                child: _isLoading
                    ? const Padding(padding: EdgeInsets.all(20), child: SmartSkeleton.list(itemCount: 4))
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (!_isCompanyVerified) ...[
                            _companyHeader(textTheme),
                            const SizedBox(height: 16),
                          ],
                          if (_tabIndex == 1)
                            CompanyApplicationsView(
                              applications: _applications,
                              statusFilter: _appStatusFilter,
                              onStatusFilterChanged: (st) {
                                setState(() => _appStatusFilter = st);
                              },
                              selectedAppIds: _selectedAppIds,
                              isBulkAction: _isBulkAction,
                              onBulkShortlist: _bulkShortlist,
                              onUpdateStatus: _updateAppStatus,
                              onRefresh: _loadCompanyData,
                            )
                          else if (_tabIndex == 2)
                            CompanySiteJobsView(
                              companyJobs: _companyJobs,
                              applications: _applications,
                              onNewJob: () => CompanyPostJobSheet.show(
                                context,
                                myProfile: _myProfile,
                                onJobPosted: _loadCompanyData,
                              ),
                              onPublishJob: _publishJob,
                              onCloseJob: _closeJob,
                              onUpdateStatus: _updateAppStatus,
                              onViewApplicants: () => setState(() => _tabIndex = 1),
                            )
                          else if (_tabIndex == 3)
                            CompanyAnalyticsView(
                              reportsData: _reportsData,
                              jobsCount: _companyJobs.length,
                              applicationsCount: _applications.length,
                              companyJobs: _companyJobs,
                              applications: _applications,
                              onNavigateToJobs: () => setState(() => _tabIndex = 2),
                              onNavigateToApplications: (status) {
                                setState(() {
                                  _appStatusFilter = status;
                                  _tabIndex = 1;
                                });
                              },
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
      ),
    );
  }
}
