import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../messages/chat_screen.dart';

class CompanyChatsView extends StatefulWidget {
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
  State<CompanyChatsView> createState() => _CompanyChatsViewState();
}

class _CompanyChatsViewState extends State<CompanyChatsView> {
  int _selectedFilter = 0; // 0 = All, 1 = Unread

  List<Conversation> _parsedConversations() {
    return widget.companyConversations.map((map) {
      return Conversation.fromJson(map, currentUserId: widget.companyUserId);
    }).toList();
  }

  List<Conversation> _filter(List<Conversation> conversations) {
    if (_selectedFilter == 1) {
      return conversations.where((c) => c.unreadCount > 0).toList();
    }
    return conversations;
  }

  Widget _buildFilterChip(String label, int index, int count) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.companyTagBackground : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.companyPrimary : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.companyPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.companyPrimary : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
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

  Widget _buildStatsBar(List<Conversation> allConversations) {
    final total = allConversations.length;
    final unreadTotal = allConversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
    final candidatesCount = allConversations
        .map((c) => (c.seekerName ?? c.company).trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;

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
          _buildStatColumn('Conversations', '$total', Icons.chat_bubble_outline_rounded),
          _buildDivider(),
          _buildStatColumn('Unread', '$unreadTotal', Icons.mark_chat_unread_outlined),
          _buildDivider(),
          _buildStatColumn('Candidates', '$candidatesCount', Icons.people_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.companyPrimary, size: 20),
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

  Widget _buildEmptyState(BuildContext context, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.companyPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 44,
              color: AppColors.companyPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages here',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppColors.dark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == 1
                ? 'You have read all your candidate messages'
                : 'When you update application status or chat with candidates, conversations will appear here.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, Conversation conv) {
    final textTheme = Theme.of(context).textTheme;
    final hasUnread = conv.unreadCount > 0;
    final candidateName = (conv.seekerName != null && conv.seekerName!.trim().isNotEmpty)
        ? conv.seekerName!.trim()
        : (conv.company.isNotEmpty ? conv.company : 'Candidate');
    final avatarUrl = conv.seekerAvatarUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread ? AppColors.companyPrimary : AppColors.border,
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(conversation: conv, isCompany: true),
              ),
            ).then((_) => widget.onRefresh());
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
                    color: AppColors.companyTagBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.companyTagBorder, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarUrl != null && avatarUrl.startsWith('http')
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildInitialAvatar(candidateName),
                        )
                      : _buildInitialAvatar(candidateName),
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
                              candidateName,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: AppColors.dark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conv.lastMessageAt.isNotEmpty)
                            Text(
                              conv.lastMessageAt,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                color: hasUnread ? AppColors.companyPrimary : AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      if (conv.jobTitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.companyTagBackground,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            conv.jobTitle,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.companyTagText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        conv.lastMessage.isNotEmpty ? conv.lastMessage : 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
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
                      color: AppColors.companyPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conv.unreadCount}',
                      style: const TextStyle(
                        fontSize: 13,
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

  Widget _buildInitialAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'C',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.companyPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final allConversations = _parsedConversations();
    final filteredConversations = _filter(allConversations);

    final total = allConversations.length;
    final unreadCount = allConversations.where((c) => c.unreadCount > 0).length;
    final displayCount = _selectedFilter == 1 ? unreadCount : filteredConversations.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Summary Stats Bar
        _buildStatsBar(allConversations),

        // Filter Segment Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', 0, total),
              const SizedBox(width: 8),
              _buildFilterChip('Unread', 1, unreadCount),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Section Header matching Job Seeker messages screen
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedFilter == 1 ? 'Unread Messages' : 'Recent Conversations',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              if (displayCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.companyTagBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.companyTagBorder, width: 0.8),
                  ),
                  child: Text(
                    '$displayCount ${_selectedFilter == 1 ? 'unread' : 'chats'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.companyTagText,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Conversation List Section
        if (filteredConversations.isEmpty)
          _buildEmptyState(context, textTheme)
        else
          ...filteredConversations.map((c) => _buildConversationCard(context, c)),

        const SizedBox(height: 32),
      ],
    );
  }
}
