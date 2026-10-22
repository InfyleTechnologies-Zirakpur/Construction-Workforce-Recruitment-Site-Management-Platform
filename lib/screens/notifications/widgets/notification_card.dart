import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
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

  IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('application')) return Icons.assignment_turned_in_rounded;
    if (t.contains('job')) return Icons.work_outline_rounded;
    if (t.contains('message') || t.contains('chat')) return Icons.chat_bubble_outline_rounded;
    if (t.contains('attendance')) return Icons.access_time_rounded;
    if (t.contains('announcement')) return Icons.campaign_outlined;
    return Icons.notifications_none_rounded;
  }

  Color _iconColorFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('application')) return const Color(0xFF2E7D32);
    if (t.contains('message') || t.contains('chat')) return const Color(0xFF1976D2);
    if (t.contains('attendance')) return const Color(0xFFE65100);
    if (t.contains('announcement')) return const Color(0xFF7B1FA2);
    if (t.contains('job')) return isCompany ? AppColors.companyPrimary : AppColors.primary;
    return isCompany ? AppColors.companyPrimary : AppColors.dark;
  }

  Color _iconBgColorFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('application')) return const Color(0xFFE8F5E9);
    if (t.contains('message') || t.contains('chat')) return const Color(0xFFE3F2FD);
    if (t.contains('attendance')) return const Color(0xFFFFF3E0);
    if (t.contains('announcement')) return const Color(0xFFF3E5F5);
    if (t.contains('job')) {
      return isCompany ? AppColors.companyTagBackground : AppColors.peachBackground;
    }
    return const Color(0xFFF2F4F7);
  }

  Color _borderColorFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('application')) return const Color(0xFFC8E6C9);
    if (t.contains('message') || t.contains('chat')) return const Color(0xFFBBDEFB);
    if (t.contains('attendance')) return const Color(0xFFFFE0B2);
    if (t.contains('announcement')) return const Color(0xFFE1BEE7);
    if (t.contains('job')) {
      return isCompany ? AppColors.companyTagBorder : AppColors.peachBorder;
    }
    return AppColors.border;
  }

  String _categoryLabel(String type) {
    final t = type.toLowerCase();
    if (t.contains('application')) return 'Application';
    if (t.contains('job')) return 'Job Alert';
    if (t.contains('message') || t.contains('chat')) return 'Message';
    if (t.contains('attendance')) return 'Attendance';
    if (t.contains('announcement')) return 'Announcement';
    return 'General';
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

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final color = _iconColorFor(notification.type);
    final bgColor = _iconBgColorFor(notification.type);
    final iconBorder = _borderColorFor(notification.type);
    final category = _categoryLabel(notification.type);
    final timeStr = _formatTime(notification.time);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? (isCompany ? AppColors.companyTagBorder : AppColors.peachBorder)
              : AppColors.border,
          width: isUnread ? 1.4 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread
                ? (isCompany
                    ? AppColors.companyPrimary.withValues(alpha: 0.06)
                    : AppColors.primary.withValues(alpha: 0.05))
                : const Color(0x06000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading Icon Avatar
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconBorder, width: 1),
                  ),
                  child: Center(
                    child: Icon(
                      _iconFor(notification.type),
                      color: color,
                      size: 21,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Main Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Category tag, NEW indicator, and Timestamp
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isCompany ? AppColors.companyTagBackground : AppColors.peachBackground,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: isCompany ? AppColors.companyTagBorder : AppColors.peachBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: isCompany ? AppColors.companyPrimary : AppColors.peachText,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (timeStr.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 11.5,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Notification Title
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.dark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Notification Body
                      Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing Chevron
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
