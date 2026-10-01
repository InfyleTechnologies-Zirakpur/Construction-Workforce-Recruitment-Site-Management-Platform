import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';
import '../company/company_home_screen.dart';
import '../jobs/my_jobs_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().load();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'application_update':
      case 'application':
        return Icons.assignment_turned_in_outlined;
      case 'newMessage':
      case 'message':
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'new_job':
      case 'job':
        return Icons.work_outline;
      case 'attendance_event':
      case 'attendance':
        return Icons.access_time;
      case 'project_assignment':
      case 'assignment':
        return Icons.assignment_ind_outlined;
      case 'site_assignment':
        return Icons.location_city_outlined;
      case 'daily_report_submitted':
        return Icons.description_outlined;
      case 'project_update':
        return Icons.update_outlined;
      case 'admin_announcement':
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColorFor(String type) {
    switch (type) {
      case 'application_update':
        return Colors.green;
      case 'newMessage':
        return Colors.blue;
      case 'new_job':
        return AppColors.primary;
      case 'admin_announcement':
        return Colors.purple;
      case 'attendance_event':
        return Colors.orange;
      default:
        return AppColors.dark;
    }
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _onTapNotification(WorkerNotification notification) async {
    if (!notification.isRead) {
      await context.read<NotificationsCubit>().markRead(notification.id);
    }

    if (!mounted) return;
    if (notification.type == 'application_update' || notification.type == 'application') {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final role = await storage.read(key: 'role');
      if (!mounted) return;
      if (role == 'company') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CompanyHomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyJobsScreen(initialFilter: MyJobsFilter.applied)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await context.read<NotificationsCubit>().markAllRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, LoadState<List<WorkerNotification>>>(
        builder: (context, state) {
          if (state is Idle<List<WorkerNotification>> ||
              state is Loading<List<WorkerNotification>>) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: SmartSkeleton.list(
                itemCount: 4,
                hasLeading: true,
                leadingIsCircle: true,
                hasTags: false,
              ),
            );
          }

          if (state is Failed<List<WorkerNotification>>) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Unable to load notifications', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.read<NotificationsCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = (state as Loaded<List<WorkerNotification>>).data;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none, size: 48, color: Colors.black26),
                  const SizedBox(height: 12),
                  Text("You're all caught up", style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    "No notifications right now.",
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<NotificationsCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = notifications[i];
                final color = _iconColorFor(n.type);

                return InkWell(
                  onTap: () => _onTapNotification(n),
                  child: Container(
                    color: n.isRead ? Colors.transparent : color.withOpacity(0.06),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(_iconFor(n.type), color: color, size: 20),
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
                                      n.title,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 8, top: 4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(n.body, style: textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(n.time),
                                style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
