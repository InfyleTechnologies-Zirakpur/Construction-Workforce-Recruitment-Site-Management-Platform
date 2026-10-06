import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/worker_repository.dart';
import 'create_feed_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // 0 = All Feed, 1 = My Posts
  int _selectedFilter = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isCompany = false;
  int _activeJobs = 0;
  int _newJobsToday = 0;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _loadJobCounts();
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

  Future<void> _checkRole() async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final role = await storage.read(key: 'role');
      if (mounted && role == 'company') {
        setState(() => _isCompany = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsBottomSheet(post: post),
    );
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
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _ShareBottomSheet(post: post),
        );
      }
    }
  }

  void _confirmDeletePost(FeedPost post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Post',
          style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: AppColors.dark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FeedCubit>().deletePost(post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post deleted successfully.')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
              // Headline Slogan Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Construction feeds',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Engineers, Operators, Masons & Drivers ke liye best opportunities',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search jobs by role or location...',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Job Stat Cards from GET /jobs/counts API
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_activeJobs',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Active Jobs',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.dark,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.dark.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_newJobsToday',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'New Jobs Today',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Header & Segment Control
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest Updates',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.dark,
                    ),
                  ),
                  // Segment Control (All Feed vs My Posts)
                  Container(
                    height: 36,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _selectedFilter = 0),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedFilter == 0
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'All Feed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedFilter == 0
                                    ? Colors.white
                                    : AppColors.dark,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _selectedFilter = 1),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedFilter == 1
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'My Posts',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedFilter == 1
                                    ? Colors.white
                                    : AppColors.dark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Posts List Section
              BlocBuilder<FeedCubit, LoadState<List<FeedPost>>>(
                builder: (context, state) {
                  if (state is Idle || state is Loading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is Failed<List<FeedPost>>) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Failed to load feed',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context.read<FeedCubit>().load(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final allPosts = (state as Loaded<List<FeedPost>>).data;
                  var posts = _selectedFilter == 1
                      ? allPosts.where((p) => p.isMyPost).toList()
                      : allPosts;

                  if (_searchQuery.isNotEmpty) {
                    posts = posts.where((p) {
                      final c = p.content.toLowerCase();
                      final loc = (p.location ?? '').toLowerCase();
                      final title = (p.taggedTitle ?? '').toLowerCase();
                      final role = p.authorRole.toLowerCase();
                      return c.contains(_searchQuery) ||
                          loc.contains(_searchQuery) ||
                          title.contains(_searchQuery) ||
                          role.contains(_searchQuery);
                    }).toList();
                  }

                  if (posts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              _selectedFilter == 1
                                  ? Icons.mode_comment_outlined
                                  : Icons.feed_outlined,
                              size: 48,
                              color: Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFilter == 1
                                  ? 'You haven\'t posted anything yet'
                                  : (_searchQuery.isNotEmpty
                                        ? 'No feed posts matched "$_searchQuery"'
                                        : 'No feed posts available right now'),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _openCreatePost,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Feed Post'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
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
                        child: _FeedPostCard(
                          post: post,
                          formattedTime: _formatTime(post.createdAt),
                          onLikeToggle: () =>
                              context.read<FeedCubit>().toggleLike(post.id),
                          onCommentTap: () => _showCommentsModal(post),
                          onShareTap: () => _showShareModal(post),
                          onEditTap: post.isMyPost
                              ? () => _openEditPost(post)
                              : null,
                          onDeleteTap: post.isMyPost
                              ? () => _confirmDeletePost(post)
                              : null,
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
        icon: const Icon(
          Icons.edit_note_rounded,
          color: Colors.white,
          size: 24,
        ),
        label: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _openEditPost(FeedPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateFeedScreen(postToEdit: post)),
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final String formattedTime;
  final VoidCallback onLikeToggle;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const _FeedPostCard({
    required this.post,
    required this.formattedTime,
    required this.onLikeToggle,
    required this.onCommentTap,
    required this.onShareTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: post.isMyPost
                    ? AppColors.primary
                    : const Color(
                        0xFFF5A623,
                      ), // Warm yellow/orange from screenshot
                child: Text(
                  post.authorName.length >= 3 && post.authorName.contains(' ')
                      ? post.authorName
                            .split(' ')
                            .take(2)
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .join('')
                            .toUpperCase()
                      : (post.authorName.isNotEmpty
                            ? post.authorName
                                  .substring(
                                    0,
                                    post.authorName.length.clamp(1, 3),
                                  )
                                  .toUpperCase()
                            : 'U'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.authorName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.dark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.isMyPost) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedTime,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit & Delete Menu Options for Post Author (User & Company)
              if (onDeleteTap != null || onEditTap != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (val == 'edit' && onEditTap != null) onEditTap!();
                    if (val == 'delete' && onDeleteTap != null) onDeleteTap!();
                  },
                  itemBuilder: (ctx) => [
                    if (onEditTap != null)
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: AppColors.dark,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Edit Post',
                              style: TextStyle(
                                color: AppColors.dark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (onDeleteTap != null)
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Post',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Post Body Text
          Text(
            post.content,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.dark,
            ),
          ),

          // Inner Tagged Container Box
          if ((post.taggedTitle != null && post.taggedTitle!.isNotEmpty) ||
              (post.location != null && post.location!.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.taggedTitle != null &&
                      post.taggedTitle!.isNotEmpty) ...[
                    Text(
                      post.taggedTitle!,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (post.location != null && post.location!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.location!,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          Text(
            '${post.likesCount} likes   ${post.commentsCount} comments   ${post.sharesCount} shares',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: onLikeToggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_alt_outlined,
                        size: 19,
                        color: post.isLiked
                            ? AppColors.primary
                            : AppColors.dark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Like',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: post.isLiked
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: post.isLiked
                              ? AppColors.primary
                              : AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              InkWell(
                onTap: onCommentTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 19,
                        color: AppColors.dark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Comment',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Share Action
              InkWell(
                onTap: onShareTap,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        size: 19,
                        color: AppColors.dark,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentsBottomSheet extends StatefulWidget {
  final FeedPost post;

  const _CommentsBottomSheet({required this.post});

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<PostComment>? _liveComments;
  bool _isLoadingComments = true;
  String _myAuthorName = '';
  String _myAuthorRole = 'Hiring Employer';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadLiveComments();
  }

  Future<void> _loadUserInfo() async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final role = await storage.read(key: 'role');
      final cName = await storage.read(key: 'companyName');
      final fName = await storage.read(key: 'fullName');
      final name = await storage.read(key: 'name');
      final resolvedName = (cName?.isNotEmpty == true)
          ? cName
          : ((fName?.isNotEmpty == true)
                ? fName
                : ((name?.isNotEmpty == true) ? name : null));
      if (mounted) {
        setState(() {
          if (resolvedName != null && resolvedName.isNotEmpty) {
            _myAuthorName = resolvedName;
          }
          if (role == 'company') {
            _myAuthorRole = 'Hiring Employer';
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadLiveComments() async {
    final comments = await context.read<FeedCubit>().fetchComments(
      widget.post.id,
    );
    if (mounted) {
      setState(() {
        _liveComments = comments;
        _isLoadingComments = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment(String authorName, String authorRole) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    await context.read<FeedCubit>().addComment(
      widget.post.id,
      text: text,
      authorName: authorName,
      authorRole: authorRole,
    );

    _commentController.clear();
    _loadLiveComments();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment posted!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _formatCommentTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<FeedCubit, LoadState<List<FeedPost>>>(
      builder: (context, state) {
        FeedPost post = widget.post;
        if (state is Loaded<List<FeedPost>>) {
          final found = state.data.where((p) => p.id == widget.post.id);
          if (found.isNotEmpty) post = found.first;
        }

        return BlocBuilder<ProfileCubit, LoadState<WorkerProfile>>(
          builder: (context, profileState) {
            String myName = '';
            String myRole = _myAuthorRole;

            if (profileState is Loaded<WorkerProfile> &&
                profileState.data.name.isNotEmpty) {
              myName = profileState.data.name;
              if (profileState.data.skills.isNotEmpty)
                myRole = profileState.data.skills.first;
            }

            if (myName.isEmpty && _myAuthorName.isNotEmpty) {
              myName = _myAuthorName;
            }

            if (myName.isEmpty) {
              myName = 'Company';
            }

            final commentsList = _liveComments ?? post.comments;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Comments (${post.commentsCount})',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 22),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Comments List
                    Expanded(
                      child:
                          _isLoadingComments &&
                              (_liveComments == null ||
                                  _liveComments!.isEmpty) &&
                              post.comments.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : (commentsList.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 40,
                                          color: Colors.black26,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No comments yet.',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Be the first to join the discussion!',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: commentsList.length,
                                    itemBuilder: (ctx, i) {
                                      final c = commentsList[i];
                                      return _buildCommentItem(c, textTheme);
                                    },
                                  )),
                    ),

                    // Comment Input Bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: const TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.textMuted,
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _sendComment(myName, myRole),
                            icon: const Icon(
                              Icons.send_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentItem(PostComment comment, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  comment.authorName.isNotEmpty
                      ? comment.authorName[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.authorName,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.dark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${_formatCommentTime(comment.createdAt)}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.text,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 13.5,
                              color: AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Render Nested Replies indented if any
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 10),
              child: Column(
                children: comment.replies
                    .map((reply) => _buildReplyItem(reply, textTheme))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(PostComment reply, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.dark,
            child: Text(
              reply.authorName.isNotEmpty
                  ? reply.authorName[0].toUpperCase()
                  : 'R',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        reply.authorName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${_formatCommentTime(reply.createdAt)}',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reply.text,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 12.5,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Working Share Bottom Sheet
class _ShareBottomSheet extends StatelessWidget {
  final FeedPost post;

  const _ShareBottomSheet({required this.post});

  String _generateShareText() {
    final titleStr = post.taggedTitle != null
        ? '\nRole: ${post.taggedTitle}'
        : '';
    final locStr = post.location != null ? '\nLocation: ${post.location}' : '';
    return '📌 BuildHire Feed Update from ${post.authorName}:\n"${post.content}"$titleStr$locStr\n\nShared via BuildHire App';
  }

  void _copyToClipboard(BuildContext context) {
    final text = _generateShareText();
    Clipboard.setData(ClipboardData(text: text));
    context.read<FeedCubit>().incrementShare(post.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Post content copied to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final text = Uri.encodeComponent(_generateShareText());
    final url = Uri.parse('whatsapp://send?text=$text');
    context.read<FeedCubit>().incrementShare(post.id);
    Navigator.pop(context);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Clipboard.setData(ClipboardData(text: _generateShareText()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp not installed. Post content copied to clipboard!',
          ),
        ),
      );
    }
  }

  Future<void> _shareSMS(BuildContext context) async {
    final text = Uri.encodeComponent(_generateShareText());
    final url = Uri.parse('sms:?body=$text');
    context.read<FeedCubit>().incrementShare(post.id);
    Navigator.pop(context);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Clipboard.setData(ClipboardData(text: _generateShareText()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied post text to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Share Post',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: AppColors.dark),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _shareOption(
                icon: Icons.share_rounded,
                label: 'All Apps',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  context.read<FeedCubit>().incrementShare(post.id);
                  Share.share(_generateShareText());
                },
              ),
              _shareOption(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _shareWhatsApp(context),
              ),
              _shareOption(
                icon: Icons.copy,
                label: 'Copy Text',
                color: AppColors.dark,
                onTap: () => _copyToClipboard(context),
              ),
              _shareOption(
                icon: Icons.sms_outlined,
                label: 'SMS',
                color: AppColors.primary,
                onTap: () => _shareSMS(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _shareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
