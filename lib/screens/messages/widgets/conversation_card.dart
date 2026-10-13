import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../features/bloc/worker_blocs.dart';
import '../chat_screen.dart';

class ConversationCard extends StatelessWidget {
  final Conversation conversation;

  const ConversationCard({
    super.key,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasUnread = conversation.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread ? AppColors.primary : AppColors.border,
          width: hasUnread ? 1.4 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.read<MessagesCubit>().markAsRead(conversation.id);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversation: conversation),
              ),
            ).then((_) {
              if (context.mounted) {
                context.read<MessagesCubit>().load(silent: true);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: AppColors.peachBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.peachBorder, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      conversation.company.isNotEmpty
                          ? conversation.company[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              conversation.company,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.dark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            conversation.lastMessageAt,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                              color: hasUnread ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (conversation.jobTitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.peachBackground,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            conversation.jobTitle,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.peachText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        conversation.lastMessage.isNotEmpty
                            ? conversation.lastMessage
                            : 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          color: hasUnread ? AppColors.dark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasUnread)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
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
