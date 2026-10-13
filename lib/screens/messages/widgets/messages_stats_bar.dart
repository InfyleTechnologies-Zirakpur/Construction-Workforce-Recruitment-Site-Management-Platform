import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

class MessagesStatsBar extends StatelessWidget {
  final List<Conversation> conversations;

  const MessagesStatsBar({
    super.key,
    required this.conversations,
  });

  @override
  Widget build(BuildContext context) {
    final total = conversations.length;
    final unreadTotal = conversations.fold<int>(
      0,
      (sum, c) => sum + c.unreadCount,
    );
    final employersCount = conversations
        .map((c) => c.company.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
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
          _buildStatColumn('Conversations', '$total', Icons.chat_bubble_outline_rounded),
          _buildDivider(),
          _buildStatColumn('Unread', '$unreadTotal', Icons.mark_chat_unread_outlined),
          _buildDivider(),
          _buildStatColumn('Employers', '$employersCount', Icons.business_outlined),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
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
