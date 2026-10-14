import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../features/bloc/worker_blocs.dart';
import 'widgets/conversation_card.dart';
import 'widgets/messages_stats_bar.dart';

export 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  final VoidCallback? onExploreJobs;

  const MessagesScreen({super.key, this.onExploreJobs});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // 0 = All, 1 = Unread
  int _selectedFilter = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MessagesCubit>().load();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> _filter(List<Conversation> conversations) {
    var result = _selectedFilter == 1
        ? conversations.where((c) => c.unreadCount > 0).toList()
        : conversations;

    if (_searchQuery.isNotEmpty) {
      result = result.where((c) {
        final comp = c.company.toLowerCase();
        final title = c.jobTitle.toLowerCase();
        final msg = c.lastMessage.toLowerCase();
        return comp.contains(_searchQuery) ||
            title.contains(_searchQuery) ||
            msg.contains(_searchQuery);
      }).toList();
    }

    return result;
  }

  Widget _buildFilterChip(String label, int index, int count) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.peachBackground : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
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

  Widget _buildEmptyState(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages here',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No conversations found matching "$_searchQuery"'
                  : (_selectedFilter == 1
                      ? 'You have read all your messages'
                      : 'When an employer reviews your application, conversations will appear here.'),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onExploreJobs != null) {
                  widget.onExploreJobs!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Explore Jobs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final content = RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => context.read<MessagesCubit>().load(),
      child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stay in touch with employers about your applications',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar matching Jobs & Feed screen
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search messages by employer or job...',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),

              // Summary Stats Bar
              BlocBuilder<MessagesCubit, LoadState<List<Conversation>>>(
                builder: (context, state) {
                  final allConversations = state is Loaded<List<Conversation>>
                      ? state.data
                      : <Conversation>[];
                  return MessagesStatsBar(conversations: allConversations);
                },
              ),

              // Filter Segment Bar
              BlocBuilder<MessagesCubit, LoadState<List<Conversation>>>(
                builder: (context, state) {
                  final allConversations = state is Loaded<List<Conversation>>
                      ? state.data
                      : <Conversation>[];
                  final total = allConversations.length;
                  final unreadCount = allConversations.where((c) => c.unreadCount > 0).length;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 0, total),
                        const SizedBox(width: 8),
                        _buildFilterChip('Unread', 1, unreadCount),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Section Header matching Jobs Header
              BlocBuilder<MessagesCubit, LoadState<List<Conversation>>>(
                builder: (context, state) {
                  final allConversations = state is Loaded<List<Conversation>>
                      ? state.data
                      : <Conversation>[];
                  final count = _selectedFilter == 1
                      ? allConversations.where((c) => c.unreadCount > 0).length
                      : allConversations.length;

                  return Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedFilter == 1 ? 'Unread Messages' : 'Recent Conversations',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                        if (count > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.peachBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.peachBorder, width: 0.8),
                            ),
                            child: Text(
                              '$count ${_selectedFilter == 1 ? 'unread' : 'chats'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.peachText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // Conversations List Section
              BlocBuilder<MessagesCubit, LoadState<List<Conversation>>>(
                builder: (context, state) {
                  if (state is Idle<List<Conversation>> ||
                      state is Loading<List<Conversation>>) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3.5,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading messages...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is Failed<List<Conversation>>) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Unable to load messages', style: textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => context.read<MessagesCubit>().load(),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text('Retry', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allConversations = (state as Loaded<List<Conversation>>).data;
                  final conversations = _filter(allConversations);

                  if (conversations.isEmpty) {
                    return _buildEmptyState(context, textTheme);
                  }

                  return Column(
                    children: conversations.map((c) {
                      return ConversationCard(conversation: c);
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        );

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (canPop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.dark, size: 19),
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'Messages',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.dark,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: content),
    );
  }
}
