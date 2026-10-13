import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../messages/chat_screen.dart';

class CompanyChatsView extends StatelessWidget {
  final List<Map<String, dynamic>> companyConversations;
  final String? companyUserId;
  final VoidCallback onRefresh;

  const CompanyChatsView({
    super.key,
    required this.companyConversations,
    required this.companyUserId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (companyConversations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('No applicant chats yet', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'When you update an application status with a remark, a conversation will be created here with the candidate.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Applicant Chats (${companyConversations.length})',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: onRefresh,
              tooltip: 'Refresh chats',
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...companyConversations.map((map) {
          final conv = Conversation.fromJson(map, currentUserId: companyUserId);
          final seekerName = conv.company.isNotEmpty ? conv.company : 'Applicant';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(conversation: conv, isCompany: true),
                  ),
                ).then((_) => onRefresh());
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.dark,
                      child: Text(
                        seekerName.isNotEmpty ? seekerName[0].toUpperCase() : 'A',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(seekerName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              if (conv.lastMessageAt.isNotEmpty)
                                Text(conv.lastMessageAt, style: textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            conv.jobTitle,
                            style: textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conv.lastMessage.isNotEmpty ? conv.lastMessage : 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (conv.unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            '${conv.unreadCount}',
                            style: textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
