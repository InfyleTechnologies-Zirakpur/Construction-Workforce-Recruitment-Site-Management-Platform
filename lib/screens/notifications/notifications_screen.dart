import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';

/// Full notifications list. Wire this up from the Home AppBar bell icon:
///
///   Navigator.of(context).push(
///     MaterialPageRoute(builder: (_) => const NotificationsScreen()),
///   );
///
/// Assumes `NotificationsCubit` is already provided above this screen in the
/// widget tree (same pattern as `ProfileCubit` in WorkerProfileScreen) —
/// if it isn't yet, add it alongside your other cubits wherever those are
/// provided (likely main.dart / an app-level MultiBlocProvider).
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
      case 'job':
        return Icons.work_outline;
      case 'application':
        return Icons.assignment_turned_in_outlined;
      case 'attendance':
        return Icons.access_time;
      case 'project':
        return Icons.construction_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Future<void> _onTapNotification(WorkerNotification notification) async {
    if (!notification.isRead) {
      await context.read<NotificationsCubit>().markRead(notification.id);
    }
    // TODO: route to the relevant screen based on notification.type
    // (e.g. job -> job details, application -> My Jobs tab, attendance -> attendance screen).
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
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
                return InkWell(
                  onTap: () => _onTapNotification(n),
                  child: Container(
                    color: n.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.dark.withOpacity(0.08),
                          child: Icon(_iconFor(n.type), color: AppColors.dark, size: 20),
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
                                n.time,
                                style: textTheme.labelSmall,
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
