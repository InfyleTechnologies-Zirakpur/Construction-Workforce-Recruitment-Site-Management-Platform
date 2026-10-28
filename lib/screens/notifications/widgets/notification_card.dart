import 'package:flutter/material.dart';

import '../../../core/models/models.dart';

class NotificationCard extends StatelessWidget {
  final WorkerNotification notification;
  final VoidCallback onTap;
  final bool isCompany;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.isCompany = false,
  });

  IconData _iconFor(String type, String title) {
    final t = '${type.toLowerCase()} ${title.toLowerCase()}';
    if (t.contains('multiple')) return Icons.group_outlined;
    if (t.contains('applicant') || t.contains('application') || t.contains('applied')) {
      return Icons.person_add_outlined;
    }
    if (t.contains('like')) return Icons.favorite_border_rounded;
    if (t.contains('comment')) return Icons.chat_bubble_outline_rounded;
    if (t.contains('post')) return Icons.campaign_outlined;
    if (t.contains('announcement') || t.contains('broadcast')) return Icons.campaign_outlined;
    if (t.contains('update') || t.contains('version')) return Icons.system_update_alt_rounded;
    if (t.contains('message') || t.contains('chat')) return Icons.mail_outline_rounded;
    if (t.contains('job')) return Icons.work_outline_rounded;
    if (t.contains('attendance') || t.contains('checkin')) return Icons.access_time_rounded;
    return Icons.notifications_none_rounded;
  }

  Color _iconColorFor(String type, String title) {
    final t = '${type.toLowerCase()} ${title.toLowerCase()}';
    if (t.contains('like')) return const Color(0xFFE11D48); // Rose red
    if (t.contains('comment')) return const Color(0xFF16A34A); // Green
    if (t.contains('post')) return const Color(0xFF9333EA); // Purple
    if (t.contains('announcement')) return const Color(0xFFEA580C); // Orange
    if (t.contains('update')) return const Color(0xFF0D9488); // Teal
    if (t.contains('applicant') || t.contains('application') || t.contains('multiple')) {
      return const Color(0xFF2563EB); // Blue
    }
    if (t.contains('message') || t.contains('chat')) return const Color(0xFF2563EB);
    return const Color(0xFF2563EB);
  }

  Color _iconBgColorFor(String type, String title) {
    final t = '${type.toLowerCase()} ${title.toLowerCase()}';
    if (t.contains('like')) return const Color(0xFFFFF1F2);
    if (t.contains('comment')) return const Color(0xFFF0FDF4);
    if (t.contains('post')) return const Color(0xFFFAF5FF);
    if (t.contains('announcement')) return const Color(0xFFFFF7ED);
    if (t.contains('update')) return const Color(0xFFF0FDFA);
    if (t.contains('applicant') || t.contains('application') || t.contains('multiple')) {
      return const Color(0xFFEFF6FF);
    }
    if (t.contains('message') || t.contains('chat')) return const Color(0xFFEFF6FF);
    return const Color(0xFFEFF6FF);
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) {
        final m = diff.inMinutes;
        return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
      }
      if (diff.inHours < 24) {
        final h = diff.inHours;
        return '$h ${h == 1 ? 'hour' : 'hours'} ago';
      }
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) {
        final d = diff.inDays;
        return '$d ${d == 1 ? 'day' : 'days'} ago';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final color = _iconColorFor(notification.type, notification.title);
    final bgColor = _iconBgColorFor(notification.type, notification.title);
    final timeStr = _formatTime(notification.time);
    final accentColor = isCompany ? const Color(0xFFF5A623) : const Color(0xFF2563EB);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  _iconFor(notification.type, notification.title),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title, Subtitle, Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Title + Unread Dot
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title.isNotEmpty
                                ? notification.title
                                : 'Notification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8.5,
                            height: 8.5,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Body Description
                    Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Time Ago
                    if (timeStr.isNotEmpty)
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF94A3B8),
                        ),
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
}
