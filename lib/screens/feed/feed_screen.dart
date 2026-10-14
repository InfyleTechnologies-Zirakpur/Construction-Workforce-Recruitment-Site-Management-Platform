import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/worker_repository.dart';
import 'create_feed_screen.dart';
import 'widgets/feed_comments_sheet.dart';
import 'widgets/feed_post_card.dart';
import 'widgets/feed_share_sheet.dart';
import 'widgets/feed_stats_bar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // 0 = All Feed, 1 = My Posts
  int _selectedFilter = 0;

  int _activeJobs = 0;
  int _newJobsToday = 0;

  @override
  void initState() {
    super.initState();
    _loadJobCounts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FeedCubit>().load();
      }
    });
  }

  Future<void> _loadJobCounts() async {
    try {
      final counts = await WorkerRepository().getJobCounts();
      if (mounted) {
        setState(() {
          _activeJobs = counts['activeJobs'] ?? 0;
          _newJobsToday = counts['newJobsToday'] ?? 0;
        });
      }
    } catch (_) {}
  }



  void _openCreatePost() {
    Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const CreateFeedScreen()))
        .then((created) {
      if (created == true && mounted) {
        setState(() => _selectedFilter = 1);
      }
    });
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  void _showCommentsModal(FeedPost post) {
    FeedCommentsSheet.show(context, post);
  }

  void _showShareModal(FeedPost post) {
    context.read<FeedCubit>().incrementShare(post.id);

    final String authorPart = post.authorName.trim().isNotEmpty
        ? 'Posted by: ${post.authorName.trim()}\n'
        : '';
    final String shareText =
        '${post.content}\n\n${authorPart}-- Shared via BuildHire App';

    try {
      Share.share(
        shareText,
        subject: 'BuildHire Feed Post',
      );
    } catch (_) {
      if (mounted) {
        FeedShareSheet.show(context, post);
      }
    }
  }

  void _openEditPost(FeedPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateFeedScreen(postToEdit: post)),
    );
  }

  Future<void> _confirmDeletePost(FeedPost post) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Post?',
      message: 'Are you sure you want to delete this post? This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      icon: Icons.delete_outline_rounded,
      isDestructive: false,
    );

    if (confirmed && mounted) {
      context.read<FeedCubit>().deletePost(post.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post deleted successfully.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.peachBackground : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await _loadJobCounts();
            if (context.mounted) {
              await context.read<FeedCubit>().load(refresh: true);
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Feed',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'See here whats happening in the market',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),


              // Feed Highlights Stat Bar matching JobsStatsBar
              BlocBuilder<FeedCubit, LoadState<List<FeedPost>>>(
                builder: (context, state) {
                  final totalPosts = state is Loaded<List<FeedPost>> ? state.data.length : 0;
                  return FeedStatsBar(
                    activeJobs: _activeJobs,
                    newJobsToday: _newJobsToday,
                    totalPosts: totalPosts,
                  );
                },
              ),

              // Section Header & Segment Control matching TradeFilterBar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest Updates',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.dark,
                    ),
                  ),
                  Row(
                    children: [
                      _buildFilterChip('All Feed', 0),
                      const SizedBox(width: 8),
                      _buildFilterChip('My Posts', 1),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Posts List Section
              BlocBuilder<FeedCubit, LoadState<List<FeedPost>>>(
                builder: (context, state) {
                  if (state is Idle || state is Loading) {
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
                              'Loading posts...',
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

                  if (state is Failed<List<FeedPost>>) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Failed to load feed', style: textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context.read<FeedCubit>().load(),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }

                  final allPosts = (state as Loaded<List<FeedPost>>).data;
                  final posts = _selectedFilter == 1
                      ? allPosts.where((p) => p.isMyPost).toList()
                      : allPosts;

                  if (posts.isEmpty) {
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
                                Icons.feed_outlined,
                                size: 44,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No post here',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: AppColors.dark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedFilter == 1
                                  ? 'You haven\'t posted anything yet'
                                  : 'No feed posts available right now',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: _openCreatePost,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Create Post'),
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

                  return Column(
                    children: posts.map((post) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FeedPostCard(
                          post: post,
                          formattedTime: _formatTime(post.createdAt),
                          onLikeToggle: () => context.read<FeedCubit>().toggleLike(post.id),
                          onCommentTap: () => _showCommentsModal(post),
                          onShareTap: () => _showShareModal(post),
                          onEditTap: post.isMyPost ? () => _openEditPost(post) : null,
                          onDeleteTap: post.isMyPost ? () => _confirmDeletePost(post) : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
        label: const Text(
          'Create Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
