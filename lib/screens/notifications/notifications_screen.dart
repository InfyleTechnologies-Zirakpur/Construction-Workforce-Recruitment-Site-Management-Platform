import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';
import '../company/company_home_screen.dart';
import '../home/home_page.dart';
import '../home/widgets/job_details_sheet.dart';
import '../jobs/my_jobs_screen.dart';
import '../messages/chat_screen.dart';
import '../messages/messages_screen.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_details_sheet.dart';

enum NotificationFilter { all, applications, messages }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationFilter _selectedFilter = NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationsCubit>().load();
        context.read<JobsCubit>().load();
        context.read<MessagesCubit>().load();
      }
    });
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
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final role = await storage.read(key: 'role');
    if (!mounted) return;
    final isCompany = role == 'company';

    if (t.contains('application') || t.contains('applied')) {
      if (isCompany) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const CompanyHomeScreen(initialTabIndex: 1),
          ),
          (route) => false,
        );
      } else {
        // Try finding the specific job/application
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
      if (isCompany) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const CompanyHomeScreen(initialTabIndex: 2),
          ),
          (route) => false,
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

        if (matchedJob != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => JobDetailsSheet(job: matchedJob!),
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const HomePage(initialNavIndex: 1),
            ),
            (route) => false,
          );
        }
      }
    } else if (t.contains('message') || t.contains('chat')) {
      if (isCompany) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const CompanyHomeScreen(initialTabIndex: 4),
          ),
          (route) => false,
        );
      } else {
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
                (c.jobTitle.isNotEmpty && notifText.contains(c.jobTitle.toLowerCase()))
              ),
              orElse: () => null,
            );
          }
        }

        if (matchedConv != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversation: matchedConv!),
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
    } else if (t.contains('attendance') ||
        t.contains('site') ||
        t.contains('project') ||
        t.contains('assignment') ||
        t.contains('report')) {
      if (isCompany) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const CompanyHomeScreen(initialTabIndex: 2),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MyJobsScreen(initialFilter: MyJobsFilter.applied),
          ),
        );
      }
    }
  }

  String? _getPrimaryActionLabel(WorkerNotification notification) {
    final t = notification.type.toLowerCase();
    if (t.contains('application') || t.contains('applied')) return 'View Applications';
    if (t.contains('job')) return 'Browse Jobs';
    if (t.contains('message') || t.contains('chat')) return 'Open Messages';
    if (t.contains('attendance') ||
        t.contains('site') ||
        t.contains('project') ||
        t.contains('assignment') ||
        t.contains('report')) {
      return 'View Details';
    }
    return null;
  }

  void _onTapNotification(WorkerNotification notification) {
    if (!notification.isRead) {
      context.read<NotificationsCubit>().markRead(notification.id);
    }

    final actionLabel = _getPrimaryActionLabel(notification);

    if (actionLabel != null) {
      _handlePrimaryAction(notification);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => NotificationDetailsSheet(
          notification: notification,
        ),
      );
    }
  }

  Widget _buildFilterChip(String label, NotificationFilter filter, int count) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.peachBackground : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You're all caught up",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'When companies update applications or post matching jobs, they will appear here.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                }
              },
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Explore Jobs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
            fontSize: 18,
            color: AppColors.dark,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          BlocBuilder<NotificationsCubit, LoadState<List<WorkerNotification>>>(
            builder: (context, state) {
              if (state is! Loaded<List<WorkerNotification>>) return const SizedBox.shrink();
              final unreadCount = state.data.where((n) => !n.isRead).length;
              if (unreadCount == 0) return const SizedBox.shrink();

              return TextButton.icon(
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
                icon: const Icon(Icons.done_all_rounded, size: 17, color: AppColors.primary),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
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
                          backgroundColor: AppColors.primary,
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
            final filteredNotifications = _filterNotifications(allNotifications);

            final appCount = allNotifications
                .where((n) => n.type.toLowerCase().contains('application'))
                .length;
            final msgCount = allNotifications
                .where((n) =>
                    n.type.toLowerCase().contains('message') ||
                    n.type.toLowerCase().contains('chat'))
                .length;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => context.read<NotificationsCubit>().load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Page Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity & Updates',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stay informed on applications and messages',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
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
                  const SizedBox(height: 16),

                  // Notifications List or Empty State
                  if (filteredNotifications.isEmpty)
                    _buildEmptyState(context, textTheme)
                  else
                    ...filteredNotifications.map((notification) {
                      return NotificationCard(
                        notification: notification,
                        onTap: () => _onTapNotification(notification),
                      );
                    }),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
