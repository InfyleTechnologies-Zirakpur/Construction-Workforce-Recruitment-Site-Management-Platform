import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/company_repository.dart';
import '../../features/repositories/worker_repository.dart';
import '../company/company_home_screen.dart';
import '../company/widgets/company_applicant_review_sheet.dart';
import '../home/home_page.dart';
import '../home/widgets/job_details_sheet.dart';
import '../jobs/my_jobs_screen.dart';
import '../messages/messages_screen.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_details_sheet.dart';

enum NotificationFilter { all, applications, messages }

class NotificationsScreen extends StatefulWidget {
  final String? targetNotificationId;
  final String? targetReferenceId;
  final WorkerNotification? initialNotification;
  final bool? isCompany;

  const NotificationsScreen({
    super.key,
    this.targetNotificationId,
    this.targetReferenceId,
    this.initialNotification,
    this.isCompany,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _selectedFilter = NotificationFilter.all;
  bool _hasHandledTarget = false;
  bool _isCompany = false;

  bool get _effectiveIsCompany {
    if (widget.isCompany == true) return true;
    if (_isCompany) return true;
    final theme = Theme.of(context);
    if (theme.primaryColor == AppColors.companyPrimary ||
        theme.colorScheme.primary == AppColors.companyPrimary) {
      return true;
    }
    return false;
  }

  Color get _themePrimary => _effectiveIsCompany ? AppColors.companyPrimary : AppColors.primary;
  Color get _chipSelectedBg => _effectiveIsCompany ? AppColors.companyTagBackground : AppColors.peachBackground;
  Color get _chipSelectedBorder => _effectiveIsCompany ? AppColors.companyPrimary : AppColors.primary;
  Color get _chipSelectedText => _effectiveIsCompany ? AppColors.companyPrimary : AppColors.primary;

  @override
  void initState() {
    super.initState();
    _isCompany = widget.isCompany ?? false;
    _checkRole();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationsCubit>().load();
        context.read<JobsCubit>().load();
        context.read<MessagesCubit>().load();

        if (widget.initialNotification != null && !_hasHandledTarget) {
          _hasHandledTarget = true;
          _onTapNotification(widget.initialNotification!);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompany != null && widget.isCompany != _isCompany) {
      setState(() => _isCompany = widget.isCompany!);
    }
  }

  Future<void> _checkRole() async {
    if (widget.isCompany == true) {
      if (!_isCompany && mounted) setState(() => _isCompany = true);
      return;
    }
    try {
      const storage1 = FlutterSecureStorage();
      final role1 = await storage1.read(key: 'role');
      if (role1 == 'company') {
        if (mounted && !_isCompany) setState(() => _isCompany = true);
        return;
      }
      const storage2 = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final role2 = await storage2.read(key: 'role');
      if (role2 == 'company') {
        if (mounted && !_isCompany) setState(() => _isCompany = true);
        return;
      }
    } catch (_) {}
  }

  List<WorkerNotification> _filterNotifications(List<WorkerNotification> all) {
    switch (_selectedFilter) {
      case NotificationFilter.all:
        return all;
      case NotificationFilter.applications:
        return all.where((n) => n.type.toLowerCase().contains('application')).toList();
      case NotificationFilter.messages:
        return all
            .where((n) =>
                n.type.toLowerCase().contains('message') ||
                n.type.toLowerCase().contains('chat'))
            .toList();
    }
  }

  Future<void> _handlePrimaryAction(WorkerNotification notification) async {
    final t = notification.type.toLowerCase();
    final refId = notification.referenceId;

    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(),
    );
    final role = await storage.read(key: 'role');
    if (!mounted) return;
    final isCompany = widget.isCompany ?? (role == 'company');

    if (t.contains('message') || t.contains('chat')) {
      // 1. CHAT / MESSAGE: Redirect to that particular conversation!
      Conversation? matchedConv;
      final msgState = context.read<MessagesCubit>().state;
      if (msgState is Loaded<List<Conversation>>) {
        final allConvs = msgState.data;
        if (refId != null && refId.isNotEmpty) {
          matchedConv = allConvs.cast<Conversation?>().firstWhere(
            (c) => c?.id == refId || c?.jobId == refId || c?.applicationId == refId,
            orElse: () => null,
          );
        }
        if (matchedConv == null) {
          final notifText = '${notification.title} ${notification.body}'.toLowerCase();
          matchedConv = allConvs.cast<Conversation?>().firstWhere(
            (c) => c != null && (
              (c.company.isNotEmpty && notifText.contains(c.company.toLowerCase())) ||
              (c.jobTitle.isNotEmpty && notifText.contains(c.jobTitle.toLowerCase())) ||
              (c.seekerName != null && c.seekerName!.isNotEmpty && notifText.contains(c.seekerName!.toLowerCase()))
            ),
            orElse: () => null,
          );
        }
      }

      // If not in cubit cache yet, try fetching conversations
      if (matchedConv == null) {
        try {
          if (isCompany) {
            final raw = await CompanyRepository().getConversations();
            for (final item in raw) {
              final c = Conversation.fromJson(item);
              if (c.id == refId || c.jobId == refId || c.applicationId == refId) {
                matchedConv = c;
                break;
              }
            }
          } else {
            final convs = await WorkerRepository().conversations();
            matchedConv = convs.cast<Conversation?>().firstWhere(
              (c) => c?.id == refId || c?.jobId == refId || c?.applicationId == refId,
              orElse: () => null,
            );
          }
        } catch (_) {}
      }

      if (!mounted) return;

      if (matchedConv != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: matchedConv!, isCompany: isCompany),
          ),
        );
      } else {
        if (isCompany) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CompanyHomeScreen(initialTabIndex: 4),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MessagesScreen(),
            ),
          );
        }
      }
    } else if (t.contains('application') || t.contains('applied')) {
      // 2. APPLICATION: Redirect to that particular application/applicant!
      if (isCompany) {
        Map<String, dynamic>? matchedApp;
        if (refId != null && refId.isNotEmpty) {
          try {
            final apps = await CompanyRepository().getCompanyApplications(limit: 100);
            matchedApp = apps.cast<Map<String, dynamic>?>().firstWhere(
              (a) => (a?['id'] ?? a?['_id'] ?? a?['jobId'])?.toString() == refId,
              orElse: () => null,
            );
          } catch (_) {}
        }
        if (!mounted) return;

        if (matchedApp != null) {
          CompanyApplicantReviewSheet.show(
            context,
            app: matchedApp,
            onUpdateStatus: (appId, status, {remarks, app}) async {
              try {
                await CompanyRepository().updateApplicationStatus(appId, status: status, remark: remarks);
              } catch (_) {}
            },
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CompanyHomeScreen(initialTabIndex: 1),
            ),
          );
        }
      } else {
        Job? matchedJob;
        final jobsState = context.read<JobsCubit>().state;
        if (jobsState is Loaded<List<Job>>) {
          final allJobs = jobsState.data;
          if (refId != null && refId.isNotEmpty) {
            matchedJob = allJobs.cast<Job?>().firstWhere(
              (j) => j?.id == refId || j?.applicationId == refId,
              orElse: () => null,
            );
          }
          if (matchedJob == null) {
            final notifText = '${notification.title} ${notification.body}'.toLowerCase();
            matchedJob = allJobs.cast<Job?>().firstWhere(
              (j) => j != null && (
                (j.title.isNotEmpty && notifText.contains(j.title.toLowerCase())) ||
                (j.company.isNotEmpty && notifText.contains(j.company.toLowerCase()))
              ),
              orElse: () => null,
            );
          }
        }
        if (matchedJob == null && refId != null && refId.isNotEmpty) {
          try {
            matchedJob = await WorkerRepository().getJobById(refId);
          } catch (_) {}
        }
        if (!mounted) return;

        if (matchedJob != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => JobDetailsSheet(job: matchedJob!),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MyJobsScreen(initialFilter: MyJobsFilter.applied),
            ),
          );
        }
      }
    } else if (t.contains('job')) {
      // 3. JOB: Redirect to that particular job!
      if (isCompany) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CompanyHomeScreen(initialTabIndex: 2),
          ),
        );
      } else {
        Job? matchedJob;
        final jobsState = context.read<JobsCubit>().state;
        if (jobsState is Loaded<List<Job>>) {
          final allJobs = jobsState.data;
          if (refId != null && refId.isNotEmpty) {
            matchedJob = allJobs.cast<Job?>().firstWhere(
              (j) => j?.id == refId,
              orElse: () => null,
            );
          }
          if (matchedJob == null) {
            final notifText = '${notification.title} ${notification.body}'.toLowerCase();
            matchedJob = allJobs.cast<Job?>().firstWhere(
              (j) => j != null && (
                (j.title.isNotEmpty && notifText.contains(j.title.toLowerCase())) ||
                (j.company.isNotEmpty && notifText.contains(j.company.toLowerCase()))
              ),
              orElse: () => null,
            );
          }
        }
        if (matchedJob == null && refId != null && refId.isNotEmpty) {
          try {
            matchedJob = await WorkerRepository().getJobById(refId);
          } catch (_) {}
        }
        if (!mounted) return;

        if (matchedJob != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => JobDetailsSheet(job: matchedJob!),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HomePage(initialNavIndex: 1),
            ),
          );
        }
      }
    } else {
      // 4. GENERAL / ANNOUNCEMENTS / ATTENDANCE: Show full details sheet
      _showNotificationSheet(notification);
    }
  }

  void _showNotificationSheet(WorkerNotification notification) {
    final actionLabel = _getPrimaryActionLabel(notification);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationDetailsSheet(
        notification: notification,
        primaryActionLabel: actionLabel,
        isCompany: _effectiveIsCompany,
        onPrimaryAction: actionLabel != null ? () => _handlePrimaryAction(notification) : null,
      ),
    );
  }

  void _onTapNotification(WorkerNotification notification) {
    if (!notification.isRead) {
      context.read<NotificationsCubit>().markRead(notification.id);
    }
    _handlePrimaryAction(notification);
  }

  String? _getPrimaryActionLabel(WorkerNotification notification) {
    final t = notification.type.toLowerCase();
    if (t.contains('application') || t.contains('applied')) return 'View Application';
    if (t.contains('job')) return 'View Job';
    if (t.contains('message') || t.contains('chat')) return 'Open Chat';
    if (t.contains('attendance') ||
        t.contains('site') ||
        t.contains('project') ||
        t.contains('assignment') ||
        t.contains('report')) {
      return 'View Details';
    }
    return null;
  }

  Widget _buildFilterChip(String label, NotificationFilter filter, int count) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected ? _chipSelectedBg : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _chipSelectedBorder : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _chipSelectedText : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? _themePrimary : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _themePrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: _themePrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You're all caught up",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _effectiveIsCompany
                  ? 'When candidates apply to your jobs or send messages, alerts will appear here.'
                  : 'When companies update applications or post matching jobs, they will appear here.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  if (_effectiveIsCompany) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const CompanyHomeScreen()),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  }
                }
              },
              icon: Icon(_effectiveIsCompany ? Icons.business_center_outlined : Icons.explore_outlined, size: 18),
              label: Text(_effectiveIsCompany ? 'Manage Jobs' : 'Explore Jobs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _themePrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final scaffold = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.dark, size: 19),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.dark,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationsCubit, LoadState<List<WorkerNotification>>>(
            builder: (context, state) {
              if (state is! Loaded<List<WorkerNotification>>) {
                return const SizedBox(width: 48);
              }
              final unreadCount = state.data.where((n) => !n.isRead).length;
              if (unreadCount == 0) return const SizedBox(width: 48);

              return Tooltip(
                message: 'Mark all as read',
                child: IconButton(
                  icon: Icon(Icons.done_all_rounded, size: 22, color: _themePrimary),
                  onPressed: () async {
                    await context.read<NotificationsCubit>().markAllRead();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.dark,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<NotificationsCubit, LoadState<List<WorkerNotification>>>(
          builder: (context, state) {
            if (state is Idle<List<WorkerNotification>> ||
                state is Loading<List<WorkerNotification>>) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: SmartSkeleton.list(
                  itemCount: 5,
                  hasLeading: true,
                  leadingIsCircle: false,
                  hasTags: false,
                ),
              );
            }

            if (state is Failed<List<WorkerNotification>>) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load notifications',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.message,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.read<NotificationsCubit>().load(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _themePrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allNotifications = (state as Loaded<List<WorkerNotification>>).data;
            if (!_hasHandledTarget && (widget.targetNotificationId != null || widget.targetReferenceId != null)) {
              _hasHandledTarget = true;
              WorkerNotification? matched;
              if (widget.targetNotificationId != null) {
                matched = allNotifications.cast<WorkerNotification?>().firstWhere(
                  (n) => n?.id == widget.targetNotificationId,
                  orElse: () => null,
                );
              }
              if (matched == null && widget.targetReferenceId != null) {
                matched = allNotifications.cast<WorkerNotification?>().firstWhere(
                  (n) => n?.referenceId == widget.targetReferenceId,
                  orElse: () => null,
                );
              }
              if (matched != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _onTapNotification(matched!);
                });
              }
            }
            final filteredNotifications = _filterNotifications(allNotifications);
            final newNotifications = filteredNotifications.where((n) => !n.isRead).toList();
            final earlierNotifications = filteredNotifications.where((n) => n.isRead).toList();

            final appCount = allNotifications
                .where((n) => n.type.toLowerCase().contains('application'))
                .length;
            final msgCount = allNotifications
                .where((n) =>
                    n.type.toLowerCase().contains('message') ||
                    n.type.toLowerCase().contains('chat'))
                .length;

            return RefreshIndicator(
              color: _themePrimary,
              onRefresh: () async => context.read<NotificationsCubit>().load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 30),
                children: [
                  const SizedBox(height: 12),

                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip('All', NotificationFilter.all, allNotifications.length),
                          const SizedBox(width: 8),
                          _buildFilterChip('Applications', NotificationFilter.applications, appCount),
                          const SizedBox(width: 8),
                          _buildFilterChip('Messages', NotificationFilter.messages, msgCount),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notifications List or Empty State
                  if (filteredNotifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildEmptyState(context, textTheme),
                    )
                  else ...[
                    // 1. "New (count)" Section Header & Items
                    if (newNotifications.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: AppColors.card,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'New (${newNotifications.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                await context.read<NotificationsCubit>().markAllRead();
                              },
                              child: Text(
                                'Mark all as read',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: _themePrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...newNotifications.map((notification) {
                        return Column(
                          children: [
                            NotificationCard(
                              notification: notification,
                              isCompany: _effectiveIsCompany,
                              onTap: () => _onTapNotification(notification),
                            ),
                            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                          ],
                        );
                      }),
                    ],

                    // 2. "Earlier" Section Header & Items
                    if (earlierNotifications.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          newNotifications.isNotEmpty ? 20 : 12,
                          16,
                          10,
                        ),
                        color: AppColors.card,
                        child: const Text(
                          'Earlier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      ...earlierNotifications.map((notification) {
                        return Column(
                          children: [
                            NotificationCard(
                              notification: notification,
                              isCompany: _effectiveIsCompany,
                              onTap: () => _onTapNotification(notification),
                            ),
                            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                          ],
                        );
                      }),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );

    if (_effectiveIsCompany) {
      return Theme(
        data: AppTheme.companyTheme(context),
        child: scaffold,
      );
    }
    return scaffold;
  }
}
