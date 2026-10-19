import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

class NotificationsStatsBar extends StatelessWidget {
  final List<WorkerNotification> notifications;

  const NotificationsStatsBar({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    final total = notifications.length;
    final unread = notifications.where((n) => !n.isRead).length;
    final updates = notifications.where((n) {
      final t = n.type.toLowerCase();
      return t.contains('app') || t.contains('job');
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatColumn(
            'Total Alerts',
            '$total',
            Icons.notifications_active_outlined,
            AppColors.primary,
          ),
          _buildDivider(),
          _buildStatColumn(
            'Unread',
            '$unread',
            unread > 0 ? Icons.mark_email_unread_outlined : Icons.drafts_outlined,
            unread > 0 ? AppColors.primary : AppColors.textSecondary,
          ),
          _buildDivider(),
          _buildStatColumn(
            'Jobs & Apps',
            '$updates',
            Icons.work_outline_rounded,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
