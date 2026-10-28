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
import '../feed/create_feed_screen.dart';
import '../settings/settings_screen.dart';
import 'company_profile_form_screen.dart';
import 'company_profile_screen.dart';
import 'widgets/company_analytics_view.dart';
import 'widgets/company_app_bar.dart';
import 'widgets/company_hiring_view.dart';
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

  Future<void> _loadCompanyData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
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
        _loadCompanyData(showLoading: false);
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
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Theme(
      data: AppTheme.companyTheme(context),
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: (_tabIndex == 2 || _tabIndex == 4)
          ? null
          : const CompanyAppBar(
              showSettings: false,
              showProfileAvatar: false,
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.business_center_outlined,
                label: 'Hiring',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.add_box_outlined,
                label: 'Post',
                isAction: true,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.settings_outlined,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: null,
      body: _tabIndex == 0
          ? const FeedScreen(isCompany: true)
          : _tabIndex == 2
              ? CreateFeedScreen(
                  isCompany: true,
                  isTab: true,
                  onPostSuccess: () {
                    setState(() => _tabIndex = 0);
                    _loadCompanyData();
                  },
                )
              : _tabIndex == 4
                  ? const SettingsScreen(isTab: true)
                  : SafeArea(
                      child: RefreshIndicator(
                        color: AppColors.companyPrimary,
                        onRefresh: _loadCompanyData,
                        child: _isLoading
                            ? const Padding(padding: EdgeInsets.all(20), child: SmartSkeleton.list(itemCount: 4))
                            : ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  if (_tabIndex == 1)
                                    CompanyHiringView(
                                      applications: _applications,
                                      companyJobs: _companyJobs,
                                      statusFilter: _appStatusFilter,
                                      onStatusFilterChanged: (st) {
                                        setState(() => _appStatusFilter = st);
                                      },
                                      selectedAppIds: _selectedAppIds,
                                      isBulkAction: _isBulkAction,
                                      onBulkShortlist: _bulkShortlist,
                                      onUpdateStatus: _updateAppStatus,
                                      onRefresh: _loadCompanyData,
                                      myProfile: _myProfile,
                                      onNewJob: () => CompanyPostJobSheet.show(
                                        context,
                                        myProfile: _myProfile,
                                        onJobPosted: _loadCompanyData,
                                      ),
                                      onEditJob: (job) => CompanyPostJobSheet.show(
                                        context,
                                        myProfile: _myProfile,
                                        existingJob: job,
                                        onJobPosted: _loadCompanyData,
                                      ),
                                    )
                                  else if (_tabIndex == 3)
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

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool isAction = false,
  }) {
    final isSelected = _tabIndex == index;

    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        width: 62,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.companyPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.dark : const Color(0xFF334155),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.dark : const Color(0xFF334155),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
