import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

class NotificationDetailsSheet extends StatelessWidget {
  final WorkerNotification notification;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final bool isCompany;

  const NotificationDetailsSheet({
    super.key,
    required this.notification,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.isCompany = false,
  });

  String _formatFullDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final month = months[dt.month - 1];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$month ${dt.day}, ${dt.year} • $hour:$minute $period';
    } catch (_) {
      return raw;
    }
  }

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

  String _typeLabelFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('application')) return 'Application Update';
    if (t.contains('job')) return 'Job Alert';
    if (t.contains('message') || t.contains('chat')) return 'Direct Message';
    if (t.contains('attendance')) return 'Attendance Event';
    if (t.contains('announcement')) return 'Announcement';
    return 'Notification';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _iconColorFor(notification.type);
    final bgColor = _iconBgColorFor(notification.type);
    final category = _typeLabelFor(notification.type);
    final dateString = _formatFullDate(notification.time);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top category & icon row
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(_iconFor(notification.type), color: color, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      if (dateString.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateString,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notification Title
            Text(
              notification.title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.dark,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),

            // Message Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Text(
                notification.body.isNotEmpty
                    ? notification.body
                    : 'No additional details provided for this alert.',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.dark,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                if (onPrimaryAction != null && primaryActionLabel != null) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onPrimaryAction!();
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(primaryActionLabel!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompany ? AppColors.companyPrimary : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dark,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
