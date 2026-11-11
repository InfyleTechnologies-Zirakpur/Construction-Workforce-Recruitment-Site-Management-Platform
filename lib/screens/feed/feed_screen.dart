import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/company_repository.dart';
import '../../features/repositories/worker_repository.dart';
import '../company/company_profile_screen.dart';
import '../profile/worker_profile_screen.dart';
import 'widgets/feed_comments_sheet.dart';
import 'widgets/feed_post_card.dart';
import 'widgets/feed_share_sheet.dart';
import 'widgets/feed_stats_bar.dart';
import 'widgets/tender_feed_card.dart';
import '../../core/data/sub_contractor_dummy_data.dart';

class FeedScreen extends StatefulWidget {
  final bool? isCompany;
  const FeedScreen({super.key, this.isCompany});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // 0 = All Feed, 1 = My Posts
  int _selectedFilter = 0;

  int _activeJobs = 0;
  int _newJobsToday = 0;
  late bool _isCompany;
  String? _userAvatarUrl;

  // Tender / Job Opportunities posted by Companies for Sub Contractors (Centralized Dummy Store)
  List<TenderJobItem> _tenders = SubContractorDummyData.getInitialFeedTenders();

  // Default featured community post matching design if feed is fresh (Sharma Construction)
  final FeedPost _sampleCommunityPost = SubContractorDummyData.getSampleFeaturedPost();

  @override
  void initState() {
    super.initState();
    _isCompany = widget.isCompany ?? true;
    if (widget.isCompany == null) {
      _checkUserRole();
    }
    _loadJobCounts();
    _loadUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FeedCubit>().load();
      }
    });
  }

  Future<void> _checkUserRole() async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final role = await storage.read(key: 'role');
      if (mounted && role != null) {
        setState(() {
          _isCompany = role == 'company' || role == 'subcontractor' || role == 'sub_contractor';
        });
      }
    } catch (_) {}
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

  Future<void> _loadUserProfile() async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final avatar = await storage.read(key: 'avatarUrl');
      if (mounted && avatar != null && avatar.isNotEmpty) {
        setState(() => _userAvatarUrl = avatar);
      }
      if (_isCompany) {
        final profile = await CompanyRepository().getMyCompanyProfile();
        if (mounted && profile != null) {
          final logo = (profile['logoUrl'] ?? profile['avatarUrl'])?.toString();
          if (logo != null && logo.isNotEmpty) {
            setState(() => _userAvatarUrl = logo);
          }
          final compName = (profile['name'] ?? profile['companyName'] ?? profile['businessName'])?.toString();
          if (compName != null && compName.trim().isNotEmpty) {
            await storage.write(key: 'companyName', value: compName.trim());
          }
        }
      }
    } catch (_) {}
  }

  void _openMyProfile() {
    if (_isCompany) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => const CompanyProfileScreen(isReadOnly: false),
            ),
          )
          .then((_) => _loadUserProfile());
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const WorkerProfileScreen(),
        ),
      );
    }
  }

  void _openAuthorProfile(FeedPost post) {
    if (post.isMyPost) {
      _openMyProfile();
      return;
    }

    final isWorker = post.authorRole.toLowerCase().contains('seeker') ||
        post.authorRole.toLowerCase().contains('worker') ||
        post.authorRole.toLowerCase().contains('labor');

    if (isWorker) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const WorkerProfileScreen(),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CompanyProfileScreen(
            userId: post.authorId,
            companyId: post.companyId,
            isReadOnly: true,
          ),
        ),
      );
    }
  }



  Color get _themePrimary => _isCompany ? AppColors.companyPrimary : AppColors.primary;

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    if (diff.inDays < 7) return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  void _showCommentsModal(FeedPost post) {
    FeedCommentsSheet.show(context, post, isCompany: _isCompany);
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

  Future<void> _confirmDeletePost(FeedPost post) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Post?',
      message: 'Are you sure you want to delete this post? This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      icon: Icons.delete_outline_rounded,
      isDestructive: false,
      isCompany: _isCompany,
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

  void _onApplyTender(TenderJobItem tender) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final noteController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.companyPrimary,
                    child: Text(
                      tender.companyName.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tender.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          tender.companyName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.companyTagBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.companyTagBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget: ${tender.budget}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.companyTagText,
                      ),
                    ),
                    Text(
                      'Deadline: ${tender.deadline}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.companyTagText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Proposal / Cover Note',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe your workforce capabilities, team size, and availability...',
                  hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      final idx = _tenders.indexWhere((t) => t.id == tender.id);
                      if (idx != -1) {
                        _tenders[idx] = _tenders[idx].copyWith(
                          isApplied: true,
                          applicantsCount: _tenders[idx].applicantsCount + 1,
                        );
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Proposal submitted successfully to ${tender.companyName}!'),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.companyPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Application',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onToggleBookmark(TenderJobItem tender) {
    setState(() {
      final idx = _tenders.indexWhere((t) => t.id == tender.id);
      if (idx != -1) {
        final newSaved = !_tenders[idx].isSaved;
        _tenders[idx] = _tenders[idx].copyWith(isSaved: newSaved);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newSaved ? 'Saved to bookmarks' : 'Removed from bookmarks'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    final activeBg = _isCompany ? AppColors.companyTagBackground : AppColors.peachBackground;
    final activeBorder = _isCompany ? AppColors.companyTagBorder : AppColors.peachBorder;
    final activeText = _isCompany ? AppColors.companyPrimary : AppColors.primary;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeBorder : const Color(0xFFEAECF0),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? activeText : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildSubContractorFeed(BuildContext context) {
    return BlocBuilder<FeedCubit, LoadState<List<FeedPost>>>(
      builder: (context, state) {
        final List<FeedPost> livePosts = state is Loaded<List<FeedPost>> ? state.data : [];
        final communityPost = livePosts.isNotEmpty ? livePosts.first : _sampleCommunityPost;
        final additionalPosts = livePosts.length > 1 ? livePosts.sublist(1) : <FeedPost>[];

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // 1. Welcome Back Top Banner (Warm Amber / Gold Gradient - Old Theme)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF59E0B), // Warm Amber
                    Color(0xFFD97706), // Rich Golden Amber
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Welcome Back! 🙏',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Explore new opportunities and stay updated',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Section Header: "Company Feed" + "3 New Jobs" pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Company Feed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.companyTagBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.companyTagBorder),
                  ),
                  child: Text(
                    '${_tenders.length} New Jobs',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.companyTagText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Featured Community Post (Sharma Construction)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FeedPostCard(
                post: communityPost,
                formattedTime: _formatTime(communityPost.createdAt),
                onLikeToggle: () {
                  if (livePosts.isNotEmpty) {
                    context.read<FeedCubit>().toggleLike(communityPost.id);
                  }
                },
                onCommentTap: () => _showCommentsModal(communityPost),
                onShareTap: () => _showShareModal(communityPost),
                onEditTap: null,
                onDeleteTap: communityPost.isMyPost ? () => _confirmDeletePost(communityPost) : null,
                onProfileTap: () => _openAuthorProfile(communityPost),
                isCompany: true,
              ),
            ),

            // 4. Company Tender / Job Cards for Sub Contractors to apply
            ..._tenders.map((tender) {
              return TenderFeedCard(
                item: tender,
                onApply: () => _onApplyTender(tender),
                onBookmarkToggle: () => _onToggleBookmark(tender),
              );
            }),

            // 5. Additional live community posts if present
            ...additionalPosts.map((post) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FeedPostCard(
                  post: post,
                  formattedTime: _formatTime(post.createdAt),
                  onLikeToggle: () => context.read<FeedCubit>().toggleLike(post.id),
                  onCommentTap: () => _showCommentsModal(post),
                  onShareTap: () => _showShareModal(post),
                  onEditTap: null,
                  onDeleteTap: post.isMyPost ? () => _confirmDeletePost(post) : null,
                  onProfileTap: () => _openAuthorProfile(post),
                  isCompany: true,
                ),
              );
            }),

            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _themePrimary,
          onRefresh: () async {
            await Future.wait([
              _loadJobCounts(),
              _loadUserProfile(),
            ]);
            if (context.mounted) {
              await context.read<FeedCubit>().load(refresh: true);
            }
          },
          child: _isCompany ? _buildSubContractorFeed(context) : ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Industry Feed',
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
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Feed Highlights Stat Bar
              FeedStatsBar(
                activeJobs: _activeJobs,
                newJobsToday: _newJobsToday,
                isCompany: _isCompany,
              ),

              // Section Header & Segment Control matching TradeFilterBar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest Updates',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Posts List Section
              BlocBuilder<FeedCubit, LoadState<List<FeedPost>>>(
                builder: (context, state) {
                  if (state is Idle || state is Loading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: _themePrimary,
                              strokeWidth: 3.5,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Loading posts...',
                              style: TextStyle(
                                fontSize: 16,
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
                            style: ElevatedButton.styleFrom(backgroundColor: _themePrimary),
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
                                color: _themePrimary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.feed_outlined,
                                size: 44,
                                color: _themePrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No post here',
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
                                  ? 'You haven\'t posted anything yet'
                                  : 'No feed posts available right now',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
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
                          onEditTap: null,
                          onDeleteTap: post.isMyPost ? () => _confirmDeletePost(post) : null,
                          onProfileTap: () => _openAuthorProfile(post),
                          isCompany: _isCompany,
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
      floatingActionButton: null,
    );
  }
}
