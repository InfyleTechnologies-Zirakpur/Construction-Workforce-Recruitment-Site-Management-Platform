import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../features/bloc/feed_cubit.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/company_repository.dart';
import '../../features/repositories/worker_repository.dart';
import '../auth/login_screen.dart';
import '../feed/create_feed_screen.dart';
import '../feed/widgets/feed_comments_sheet.dart';
import '../feed/widgets/feed_post_card.dart';
import 'company_profile_form_screen.dart';
import 'widgets/company_candidate_card.dart';
import 'widgets/company_post_job_sheet.dart';

class CompanyProfileScreen extends StatefulWidget {
  final String? userId;
  final String? companyId;
  final Map<String, dynamic>? initialProfile;
  final bool isReadOnly;

  const CompanyProfileScreen({
    super.key,
    this.userId,
    this.companyId,
    this.initialProfile,
    this.isReadOnly = false,
  });

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _repo = CompanyRepository();
  final _workerRepo = WorkerRepository();

  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  Map<String, dynamic>? _profile;
  String? _error;

  List<Map<String, dynamic>> _companyJobs = [];
  List<Map<String, dynamic>> _companyApplications = [];
  List<FeedPost> _companyPosts = [];

  Map<String, dynamic>? _selectedJobForApplicants;
  String _applicantStatusFilter = 'all';
  String _applicantSearchQuery = '';
  final _applicantSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _applicantSearchController.dispose();
    super.dispose();
  }

  Future<void> _updateApplicationStatus(
    String appId,
    String status, {
    String? remarks,
    Map<String, dynamic>? app,
  }) async {
    final note = remarks?.trim();
    try {
      await _repo.updateApplicationStatus(appId, status: status, remark: note);
      if (mounted) {
        setState(() {
          final idx = _companyApplications.indexWhere((a) => (a['id'] ?? a['_id'])?.toString() == appId);
          if (idx != -1) {
            final updated = Map<String, dynamic>.from(_companyApplications[idx]);
            updated['status'] = status;
            if (note != null) updated['reviewRemarks'] = note;
            _companyApplications[idx] = updated;
          }
        });
        _showMessage('Application status updated to ${status.toUpperCase()}');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to update status: $e');
      }
    }
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadProfile(),
        _loadJobs(),
        _loadPosts(),
        _loadApplications(),
      ]);
    } catch (e) {
      // Handled in individual methods or fallback
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProfile() async {
    try {
      Map<String, dynamic>? prof;
      if (widget.initialProfile != null) {
        prof = widget.initialProfile;
      } else if (widget.userId != null && widget.userId!.trim().isNotEmpty) {
        prof = await _repo.getCompanyByUserId(widget.userId!.trim());
        if (prof == null && widget.companyId != null && widget.companyId!.trim().isNotEmpty) {
          prof = await _repo.getCompanyById(widget.companyId!.trim());
        }
      } else if (widget.companyId != null && widget.companyId!.trim().isNotEmpty) {
        prof = await _repo.getCompanyById(widget.companyId!.trim());
      } else {
        prof = await _repo.getMyCompanyProfile();
        if (prof == null) {
          final profiles = await _repo.getMyProfiles();
          if (profiles.isNotEmpty) prof = profiles.first;
        }
      }
      if (mounted) {
        setState(() => _profile = prof);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await _repo.getCompanyJobs();
      if (mounted) {
        setState(() => _companyJobs = jobs);
      }
    } catch (_) {}
  }

  Future<void> _loadApplications() async {
    try {
      final apps = await _repo.getCompanyApplications(limit: 100);
      if (mounted) {
        setState(() => _companyApplications = apps);
      }
    } catch (_) {}
  }

  Future<void> _loadPosts() async {
    try {
      final res = await _workerRepo.fetchPosts(page: 1, limit: 50);
      final items = res['items'] as List<FeedPost>? ?? [];
      final compName = _getCompanyName().toLowerCase();
      final currentUserId = await _workerRepo.getCurrentUserId();
      final profileUserId = widget.userId ??
          (_profile?['userId'] ??
              _profile?['id'] ??
              _profile?['_id'] ??
              (_profile?['user'] is Map ? (_profile?['user']['id'] ?? _profile?['user']['_id']) : null) ??
              (_profile?['owner'] is Map ? (_profile?['owner']['id'] ?? _profile?['owner']['_id']) : null))
              ?.toString();

      final filtered = items.where((p) {
        if (widget.isReadOnly) {
          if (profileUserId != null && profileUserId.isNotEmpty && p.authorId == profileUserId) return true;
          if (compName.isNotEmpty && compName != 'company' && p.authorName.toLowerCase().contains(compName)) return true;
          return false;
        }
        if (p.isMyPost) return true;
        if (currentUserId != null && currentUserId.isNotEmpty && p.authorId == currentUserId) return true;
        if (profileUserId != null && profileUserId.isNotEmpty && p.authorId == profileUserId) return true;
        if (compName.isNotEmpty && compName != 'company' && p.authorName.toLowerCase().contains(compName)) return true;
        return false;
      }).toList();

      if (mounted) {
        try {
          final feedState = context.read<FeedCubit>().state;
          if (feedState is Loaded<List<FeedPost>>) {
            for (int i = 0; i < filtered.length; i++) {
              final match = feedState.data.where((cp) => cp.id == filtered[i].id);
              if (match.isNotEmpty) {
                final m = match.first;
                filtered[i] = filtered[i].copyWith(
                  likesCount: m.likesCount,
                  isLiked: m.isLiked,
                  commentsCount: m.commentsCount,
                );
              }
            }
          }
        } catch (_) {}

        setState(() => _companyPosts = filtered);
      }
    } catch (_) {}
  }

  void _syncPostsWithCubit(List<FeedPost> cubitPosts) {
    if (_companyPosts.isEmpty) return;
    bool changed = false;
    final updated = _companyPosts.map((cp) {
      final match = cubitPosts.where((p) => p.id == cp.id);
      if (match.isNotEmpty) {
        final m = match.first;
        if (m.likesCount != cp.likesCount || m.isLiked != cp.isLiked || m.commentsCount != cp.commentsCount) {
          changed = true;
          return cp.copyWith(
            likesCount: m.likesCount,
            isLiked: m.isLiked,
            commentsCount: m.commentsCount,
          );
        }
      }
      return cp;
    }).toList();

    if (changed && mounted) {
      setState(() => _companyPosts = updated);
    }
  }

  Future<void> _toggleLike(FeedPost post) async {
    // 1. Optimistic update in local list
    setState(() {
      final idx = _companyPosts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        final cur = _companyPosts[idx];
        final newIsLiked = !cur.isLiked;
        final newCount = newIsLiked ? cur.likesCount + 1 : (cur.likesCount > 0 ? cur.likesCount - 1 : 0);
        _companyPosts[idx] = cur.copyWith(isLiked: newIsLiked, likesCount: newCount);
      }
    });

    // 2. Trigger FeedCubit or backend repository
    try {
      await context.read<FeedCubit>().toggleLike(post.id);
    } catch (_) {
      try {
        final res = await _workerRepo.toggleLikePost(post.id);
        if (mounted) {
          setState(() {
            final idx = _companyPosts.indexWhere((p) => p.id == post.id);
            if (idx != -1) {
              _companyPosts[idx] = _companyPosts[idx].copyWith(
                isLiked: res['isLiked'] as bool? ?? !_companyPosts[idx].isLiked,
                likesCount: res['likesCount'] as int? ?? _companyPosts[idx].likesCount,
              );
            }
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _openComments(FeedPost post) async {

    await FeedCommentsSheet.show(context, post, isCompany: true);
    if (mounted) {
      try {
        final feedState = context.read<FeedCubit>().state;
        if (feedState is Loaded<List<FeedPost>>) {
          _syncPostsWithCubit(feedState.data);
        }
      } catch (_) {}
      _loadPosts();
    }
  }

  void _sharePost(FeedPost post) {
    try {
      context.read<FeedCubit>().incrementShare(post.id);
    } catch (_) {}

    final String authorPart = post.authorName.trim().isNotEmpty
        ? 'Posted by: ${post.authorName.trim()}\n'
        : '';
    final String shareText =
        '${post.content}\n\n${authorPart}-- Shared via BuildHire App';
    try {
      Share.share(shareText, subject: 'BuildHire Feed Post');
    } catch (_) {}
  }

  void _editPost(FeedPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateFeedScreen(postToEdit: post, isCompany: true)),
    ).then((_) {
      _loadPosts();
      try {
        context.read<FeedCubit>().load(refresh: true);
      } catch (_) {}
    });
  }

  Future<void> _deletePost(FeedPost post) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Post?',
      message: 'Are you sure you want to delete this post? This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
      isCompany: true,
    );
    if (confirmed && mounted) {
      try {
        context.read<FeedCubit>().deletePost(post.id);
      } catch (_) {}
      setState(() {
        _companyPosts.removeWhere((p) => p.id == post.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post deleted successfully.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _formatPostTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    if (diff.inDays < 7) return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  String _getCompanyName() {
    if (_profile == null) return 'Company';
    final name = (_profile!['name'] ??
            _profile!['companyName'] ??
            _profile!['businessName'] ??
            (_profile!['owner'] is Map ? _profile!['owner']['companyName'] : null) ??
            (_profile!['user'] is Map ? (_profile!['user']['companyName'] ?? _profile!['user']['name']) : null))
        ?.toString()
        .trim();
    return (name != null && name.isNotEmpty) ? name : 'Company';
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'Company') return 'CO';
    final parts = name.split(RegExp(r'[\s&]+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 3 ? 3 : name.length).toUpperCase();
  }

  Future<void> _uploadLogo() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await image.readAsBytes();
      final url = await WorkerRepository().uploadProfilePhoto(
        bytes: bytes,
        filename: image.name,
      );

      if (url.isNotEmpty && _profile != null) {
        final profileId = (_profile!['id'] ?? _profile!['_id'])?.toString();
        if (profileId != null) {
          await _repo.updateCompanyProfile(profileId, {'logoUrl': url});
        }
        if (mounted) {
          _showMessage('Company logo updated successfully.');
          _loadProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Logo upload failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _editProfile(Map<String, dynamic> p) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyProfileFormScreen(profile: p),
      ),
    );
    if (updated == true) _loadAllData();
  }

  Future<void> _launchExternalUrl(String urlString) async {
    if (urlString.isEmpty) return;
    var validUrl = urlString.trim();
    if (!validUrl.startsWith('http://') && !validUrl.startsWith('https://')) {
      validUrl = 'https://$validUrl';
    }
    final uri = Uri.tryParse(validUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        _showMessage('Could not open link: $validUrl');
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Log Out Company?',
      message: 'Are you sure you want to log out of your employer portal?',
      confirmLabel: 'Log Out',
      cancelLabel: 'Cancel',
      icon: Icons.logout_rounded,
      isDestructive: false,
      isCompany: true,
    );

    if (confirm && mounted) {
      try {
        await NotificationService.instance.handleLogout();
      } catch (_) {}
      try {
        const storage = FlutterSecureStorage();
        String? fcmToken;
        try {
          fcmToken = await storage.read(key: 'fcmDeviceToken');
        } catch (_) {}
        try {
          await _repo.logout(fcmToken: fcmToken);
        } catch (_) {}
        await storage.deleteAll();
      } catch (_) {}

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile ?? <String, dynamic>{};

    return BlocListener<FeedCubit, LoadState<List<FeedPost>>>(
      listener: (context, state) {
        if (state is Loaded<List<FeedPost>>) {
          _syncPostsWithCubit(state.data);
        }
      },
      child: Theme(
        data: AppTheme.companyTheme(context),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.companyPrimary,
                        strokeWidth: 3.5,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading profile...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : DefaultTabController(
                  length: 3,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeroBanner(p),
                              _buildCompanyMetaAndStats(p),
                              _buildContactInfoList(p),
                              _buildSocialMediaSection(p),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SliverTabBarDelegate(
                            TabBar(
                              labelColor: AppColors.companyPrimary,
                              unselectedLabelColor: const Color(0xFF64748B),
                              indicatorColor: AppColors.companyPrimary,
                              indicatorWeight: 3.0,
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                              tabs: [
                                Tab(text: 'Posts (${_companyPosts.length})'),
                                Tab(text: 'Jobs (${_companyJobs.length})'),
                                const Tab(text: 'About'),
                              ],
                            ),
                          ),
                        ),
                      ];
                    },
                    body: TabBarView(
                      children: [
                        _buildPostsTab(),
                        _buildJobsTab(p),
                        _buildAboutTab(p),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // --- 1. Top Banner & Overlapping Logo & Action Buttons ---
  Widget _buildHeroBanner(Map<String, dynamic> p) {
    final companyName = _getCompanyName();
    final initials = _getInitials(companyName);
    final logoUrl = (p['logoUrl'] ?? p['avatarUrl'])?.toString().trim();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Top Amber Banner (strictly using existing company theme!)
        Container(
          height: 160,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF59E0B), // Warm amber company color
                Color(0xFFD97706), // Rich gold amber
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 14, top: 6),
                child: Navigator.canPop(context)
                    ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // Bottom space so Stack child can overlap
        Container(
          margin: const EdgeInsets.only(top: 160),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!widget.isReadOnly) ...[
                ElevatedButton.icon(
                  onPressed: () => _editProfile(p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.companyPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Preview Button (Outlined)
              OutlinedButton.icon(
                onPressed: () {
                  _showMessage('Viewing public preview mode');
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF1E293B)),
                label: const Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Overlapping Square Logo Card
        Positioned(
          left: 16,
          top: 110,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white,
                    child: (logoUrl != null && logoUrl.isNotEmpty)
                        ? Image.network(
                            logoUrl.startsWith('http') ? logoUrl : 'https://$logoUrl',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => _buildLogoInitials(initials),
                          )
                        : _buildLogoInitials(initials),
                  ),
                ),
              ),

              // Upload Logo Camera Badge
              if (!widget.isReadOnly)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isUploadingPhoto ? null : _uploadLogo,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.companyPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoInitials(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: AppColors.companyPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  // --- 2. Company Title, Hiring Badge & 3 Stat Cards ---
  Widget _buildCompanyMetaAndStats(Map<String, dynamic> p) {
    final companyName = _getCompanyName();
    final teamSize = p['teamSizeRange']?.toString().trim();
    final employeeCount = (teamSize != null && teamSize.isNotEmpty && teamSize != 'N/A')
        ? (teamSize.contains('+') ? teamSize : '$teamSize+')
        : '0';

    final ongoingCount = '${_companyJobs.length}';
    final completedCount = (p['completedProjectsCount'] ?? p['completedProjects'] ?? '0').toString();

    final status = (p['verificationStatus'] ?? 'pending').toString().toLowerCase();
    final isVerified = status == 'verified';
    final isHiring = _companyJobs.isNotEmpty;
    final badgeText = isHiring
        ? 'Actively Hiring'
        : (isVerified ? 'Verified Company' : 'Pending Verification');
    final badgeBg = isHiring || isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final badgeFg = isHiring || isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Title
          Text(
            companyName,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Hiring / Verification Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: badgeFg,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 3 Stat Cards in a row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF16A34A),
                  value: completedCount,
                  label: 'Completed',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.access_time_rounded,
                  iconColor: AppColors.companyPrimary,
                  value: ongoingCount,
                  label: 'Ongoing',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_outline_rounded,
                  iconColor: const Color(0xFF9333EA),
                  value: employeeCount,
                  label: 'Employees',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Contact & Meta Info List ---
  Widget _buildContactInfoList(Map<String, dynamic> p) {
    final yearEstablished = p['yearEstablished']?.toString().trim();
    final email = (p['contactEmail'] ?? p['email'])?.toString().trim();
    final phone = (p['contactPhone'] ?? p['phone'])?.toString().trim();
    final altPhone = p['alternatePhone']?.toString().trim();
    final city = p['city']?.toString().trim() ?? '';
    final state = p['state']?.toString().trim() ?? '';
    final address = p['address']?.toString().trim() ?? '';
    final pincode = p['pincode']?.toString().trim() ?? '';
    final fullAddress = [address, city, state, pincode].where((s) => s.isNotEmpty).join(', ');
    final website = p['website']?.toString().trim();

    final hasYear = yearEstablished != null && yearEstablished.isNotEmpty && yearEstablished != 'N/A';
    final hasEmail = email != null && email.isNotEmpty;
    final hasPhone = phone != null && phone.isNotEmpty;
    final hasAltPhone = altPhone != null && altPhone.isNotEmpty;
    final hasAddress = fullAddress.isNotEmpty;
    final hasWebsite = website != null && website.isNotEmpty;

    final hasAnyContact = hasYear || hasEmail || hasPhone || hasAltPhone || hasAddress || hasWebsite;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasAnyContact)
            const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFF94A3B8)),
                SizedBox(width: 8),
                Text(
                  'No contact details added yet.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            )
          else ...[
            if (hasYear) ...[
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                text: 'Established in $yearEstablished',
              ),
              const SizedBox(height: 14),
            ],
            if (hasEmail) ...[
              _buildInfoRow(
                icon: Icons.mail_outline_rounded,
                text: email,
                onTap: () => _launchExternalUrl('mailto:$email'),
              ),
              const SizedBox(height: 14),
            ],
            if (hasPhone) ...[
              _buildInfoRow(
                icon: Icons.phone_outlined,
                text: phone,
                onTap: () => _launchExternalUrl('tel:$phone'),
              ),
              const SizedBox(height: 14),
            ],
            if (hasAltPhone) ...[
              _buildInfoRow(
                icon: Icons.phone_callback_outlined,
                text: altPhone,
                onTap: () => _launchExternalUrl('tel:$altPhone'),
              ),
              const SizedBox(height: 14),
            ],
            if (hasAddress) ...[
              _buildInfoRow(
                icon: Icons.location_on_outlined,
                text: fullAddress,
              ),
              const SizedBox(height: 14),
            ],
            if (hasWebsite)
              _buildInfoRow(
                icon: Icons.language_rounded,
                text: website,
                isLink: true,
                onTap: () => _launchExternalUrl(website),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    final rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isLink ? FontWeight.w600 : FontWeight.w500,
              color: isLink ? AppColors.companyPrimary : const Color(0xFF334155),
              decoration: isLink ? TextDecoration.underline : TextDecoration.none,
              decorationColor: AppColors.companyPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: rowContent,
      );
    }
    return rowContent;
  }

  // --- 4. Social Media Section ---
  Widget _buildSocialMediaSection(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Social Media',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // LinkedIn
              Expanded(
                child: _buildSocialCard(
                  backgroundColor: const Color(0xFFF0F7FF),
                  borderColor: const Color(0xFFDBEAFE),
                  child: const Text(
                    'in',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A66C2),
                      fontFamily: 'serif',
                    ),
                  ),
                  onTap: () => _launchExternalUrl('https://www.linkedin.com/'),
                ),
              ),
              const SizedBox(width: 12),

              // Facebook
              Expanded(
                child: _buildSocialCard(
                  backgroundColor: const Color(0xFFF0F7FF),
                  borderColor: const Color(0xFFDBEAFE),
                  child: const Text(
                    'f',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1877F2),
                    ),
                  ),
                  onTap: () => _launchExternalUrl('https://www.facebook.com/'),
                ),
              ),
              const SizedBox(width: 12),

              // Twitter / X
              Expanded(
                child: _buildSocialCard(
                  backgroundColor: const Color(0xFFF0F7FF),
                  borderColor: const Color(0xFFDBEAFE),
                  child: const Icon(
                    Icons.tag_rounded,
                    color: Color(0xFF1DA1F2),
                    size: 20,
                  ),
                  onTap: () => _launchExternalUrl('https://twitter.com/'),
                ),
              ),
              const SizedBox(width: 12),

              // Instagram
              Expanded(
                child: _buildSocialCard(
                  backgroundColor: const Color(0xFFFDF2F8),
                  borderColor: const Color(0xFFFCE7F3),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFFE1306C),
                    size: 20,
                  ),
                  onTap: () => _launchExternalUrl('https://www.instagram.com/'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard({
    required Color backgroundColor,
    required Color borderColor,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  // --- 5. Tab 1: Posts Tab ---
  Widget _buildPostsTab() {
    if (_companyPosts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.feed_outlined, size: 48, color: Color(0xFF94A3B8)),
                SizedBox(height: 12),
                Text(
                  'No posts published yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Company announcements and site achievements will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _companyPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final post = _companyPosts[index];
        return FeedPostCard(
          post: post,
          formattedTime: _formatPostTime(post.createdAt),
          onLikeToggle: () => _toggleLike(post),
          onCommentTap: () => _openComments(post),
          onShareTap: () => _sharePost(post),
          onEditTap: (post.isMyPost && !widget.isReadOnly) ? () => _editPost(post) : null,
          onDeleteTap: (post.isMyPost && !widget.isReadOnly) ? () => _deletePost(post) : null,
          isCompany: true,
        );
      },
    );
  }

  // --- 6. Tab 2: Jobs Tab ---
  Widget _buildJobsTab(Map<String, dynamic> p) {
    if (_selectedJobForApplicants != null) {
      return _buildManageApplicantsView(context, _selectedJobForApplicants!);
    }

    if (_companyJobs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.work_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                const Text(
                  'No active job postings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Publish new workforce requirements to recruit skilled laborers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                if (!widget.isReadOnly) ...[
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      CompanyPostJobSheet.show(
                        context,
                        myProfile: _profile,
                        onJobPosted: () {
                          _loadJobs();
                          _loadApplications();
                        },
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
                    icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    label: const Text('Post a Job Requirement'),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _companyJobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildJobCard(context, _companyJobs[index]);
      },
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    final isClosed = _isJobClosed(job);
    final title = (job['title'] ?? 'Construction Worker').toString();
    final location = (job['location'] ?? 'Site Location').toString();
    final salary = _formatSalary(job);
    final jobType = (job['type'] ?? job['employmentType'] ?? 'Full-time').toString();
    final exp = (job['experience'] ?? job['experienceRequired'] ?? '1-3 years').toString();
    final posted = _formatTimeAgo(job['createdAt']);

    final jobApps = _getApplicationsForJob(job);
    final totalApplicants = jobApps.length;
    final appliedCount = _countStatus(jobApps, 'applied');
    final shortlistedCount = _countStatus(jobApps, 'shortlisted');
    final hiredCount = _countStatus(jobApps, 'hired');
    final rejectedCount = _countStatus(jobApps, 'rejected');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Title with pencil edit icon + Status Badge
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 18, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!widget.isReadOnly) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openEditJob(job),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isClosed ? const Color(0xFFF3F4F6) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isClosed ? 'Closed' : 'Active',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isClosed ? const Color(0xFF6B7280) : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Location Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF4B5563),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4B5563),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Details Row: Salary • Job Type • Experience
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                Text(
                  salary,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('•', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                ),
                Text(
                  jobType,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('•', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                ),
                Text(
                  exp,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),

          // Posted Time
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
            child: Text(
              posted,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),

          // Divider
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),

          // Total Applicants Row
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 14, bottom: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  size: 20,
                  color: Color(0xFF1E293B),
                ),
                const SizedBox(width: 8),
                Text(
                  '$totalApplicants Total Applicants',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          // 4 Status Metric Boxes (Applied, Shortlisted, Hired, Rejected)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    icon: Icons.access_time_rounded,
                    iconColor: const Color(0xFF2563EB),
                    count: appliedCount,
                    countColor: const Color(0xFF1D4ED8),
                    label: 'Applied',
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricBox(
                    icon: Icons.visibility_outlined,
                    iconColor: const Color(0xFFD97706),
                    count: shortlistedCount,
                    countColor: const Color(0xFFB45309),
                    label: 'Shortlisted',
                    bgColor: const Color(0xFFFEFCE8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricBox(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF16A34A),
                    count: hiredCount,
                    countColor: const Color(0xFF15803D),
                    label: 'Hired',
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricBox(
                    icon: Icons.cancel_outlined,
                    iconColor: const Color(0xFFDC2626),
                    count: rejectedCount,
                    countColor: const Color(0xFFB91C1C),
                    label: 'Rejected',
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Buttons Row: [ Manage Applicants ] & [ Edit Job ]
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 18),
            child: Row(
              children: [
                // Primary Yellow "Manage Applicants" button
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedJobForApplicants = job;
                        _applicantStatusFilter = 'all';
                        _applicantSearchQuery = '';
                        _applicantSearchController.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.companyPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Manage Applicants',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                if (!widget.isReadOnly) ...[
                  const SizedBox(width: 10),
                  // Outlined "Edit Job" button
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => _openEditJob(job),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Edit Job',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required Color iconColor,
    required int count,
    required Color countColor,
    required String label,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: countColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateFilterCard({
    required String category,
    required int count,
    required Color countColor,
    required String label,
  }) {
    final isSelected = _applicantStatusFilter == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_applicantStatusFilter == category) {
            _applicantStatusFilter = 'all';
          } else {
            _applicantStatusFilter = category;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? countColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? countColor.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: countColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageApplicantsView(BuildContext context, Map<String, dynamic> job) {
    final title = (job['title'] ?? 'Job Requirement').toString();
    final location = (job['location'] ?? job['description'] ?? 'Site Location').toString();

    final allJobApps = _getApplicationsForJob(job);
    final appliedCount = _countStatus(allJobApps, 'applied');
    final shortlistedCount = _countStatus(allJobApps, 'shortlisted');
    final hiredCount = _countStatus(allJobApps, 'hired');
    final rejectedCount = _countStatus(allJobApps, 'rejected');

    // Filter by candidate status
    List<Map<String, dynamic>> filtered = allJobApps;
    if (_applicantStatusFilter != 'all') {
      filtered = filtered.where((a) {
        final s = (a['status'] ?? 'pending').toString().toLowerCase().trim();
        switch (_applicantStatusFilter) {
          case 'applied':
            return s == 'pending' || s == 'applied';
          case 'shortlisted':
            return s == 'shortlisted';
          case 'hired':
            return s == 'accepted' || s == 'hired';
          case 'rejected':
            return s == 'rejected';
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search query
    if (_applicantSearchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        final user = a['user'] is Map ? a['user'] as Map<String, dynamic> : <String, dynamic>{};
        final name = (user['fullName'] ?? user['name'] ?? a['workerName'] ?? '').toString().toLowerCase();
        final company = (user['company'] ?? user['trade'] ?? a['trade'] ?? '').toString().toLowerCase();
        final phone = (user['phone'] ?? a['phone'] ?? '').toString().toLowerCase();
        final q = _applicantSearchQuery.toLowerCase();
        return name.contains(q) || company.contains(q) || phone.contains(q);
      }).toList();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // 1. Top Section: Title with pencil icon & Red Close Button (Exact replica of Image)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!widget.isReadOnly) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openEditJob(job),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Red Close Button: [ ✕ Close ]
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedJobForApplicants = null;
                  _applicantStatusFilter = 'all';
                  _applicantSearchQuery = '';
                  _applicantSearchController.clear();
                });
              },
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              label: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626), // Vibrant red
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Search applicants textfield
        TextField(
          controller: _applicantSearchController,
          onChanged: (val) {
            setState(() {
              _applicantSearchQuery = val.trim();
            });
          },
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            hintText: 'Search applicants...',
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 15,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Filter Metric Cards Row (Applied, Shortlisted, Hired, Rejected)
        Row(
          children: [
            Expanded(
              child: _buildCandidateFilterCard(
                category: 'applied',
                count: appliedCount,
                countColor: const Color(0xFF2563EB),
                label: 'Applied',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCandidateFilterCard(
                category: 'shortlisted',
                count: shortlistedCount,
                countColor: const Color(0xFFD97706),
                label: 'Shortlisted',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCandidateFilterCard(
                category: 'hired',
                count: hiredCount,
                countColor: const Color(0xFF16A34A),
                label: 'Hired',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCandidateFilterCard(
                category: 'rejected',
                count: rejectedCount,
                countColor: const Color(0xFFDC2626),
                label: 'Rejected',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4. Candidate Cards List
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Icon(Icons.person_search_outlined, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  _applicantSearchQuery.isNotEmpty
                      ? 'No applicants matching "$_applicantSearchQuery"'
                      : (_applicantStatusFilter != 'all'
                          ? 'No ${_applicantStatusFilter.toUpperCase()} Applicants'
                          : 'No Applicants Found'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Applicants for this role will appear here with full contact info & credentials.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return CompanyCandidateCard(
                app: filtered[index],
                job: job,
                onUpdateStatus: _updateApplicationStatus,
                isReadOnly: widget.isReadOnly,
              );
            },
          ),
      ],
    );
  }

  void _showManageApplicantsModal(BuildContext context, Map<String, dynamic> job) {
    setState(() {
      _selectedJobForApplicants = job;
      _applicantStatusFilter = 'all';
      _applicantSearchQuery = '';
      _applicantSearchController.clear();
    });
  }

  void _openEditJob(Map<String, dynamic> job) {
    CompanyPostJobSheet.show(
      context,
      myProfile: _profile,
      existingJob: job,
      onJobPosted: () {
        _loadJobs();
        _loadApplications();
      },
    );
  }

  bool _isJobClosed(Map<String, dynamic> job) {
    final st = (job['status'] ?? 'published').toString().toLowerCase().trim();
    return st == 'closed' || st == 'inactive' || st == 'expired';
  }

  List<Map<String, dynamic>> _getApplicationsForJob(Map<String, dynamic> job) {
    final jobId = (job['id'] ?? job['_id'] ?? job['jobId'])?.toString().trim();
    final jobTitle = job['title']?.toString().toLowerCase().trim();

    return _companyApplications.where((app) {
      final rawJob = app['job'];
      final appJob = rawJob is Map ? rawJob as Map<String, dynamic> : <String, dynamic>{};
      final appJobId = (app['jobId'] ?? app['job_id'] ?? (rawJob is String ? rawJob : (appJob['id'] ?? appJob['_id'])))?.toString().trim();

      if (jobId != null && jobId.isNotEmpty && appJobId != null && appJobId.isNotEmpty) {
        if (appJobId == jobId) return true;
      }

      final appTitle = (appJob['title'] ?? app['jobTitle'])?.toString().toLowerCase().trim();
      if (jobTitle != null && jobTitle.isNotEmpty && appTitle != null && appTitle.isNotEmpty) {
        if (jobTitle == appTitle) return true;
      }

      return false;
    }).toList();
  }

  int _countStatus(List<Map<String, dynamic>> apps, String category) {
    return apps.where((a) {
      final s = (a['status'] ?? 'pending').toString().toLowerCase().trim();
      switch (category) {
        case 'applied':
          return s == 'pending' || s == 'applied';
        case 'shortlisted':
          return s == 'shortlisted';
        case 'hired':
          return s == 'accepted' || s == 'hired';
        case 'rejected':
          return s == 'rejected';
        default:
          return true;
      }
    }).length;
  }

  String _formatTimeAgo(dynamic dateVal) {
    if (dateVal == null) return 'Recently';
    try {
      final dt = dateVal is DateTime ? dateVal : DateTime.parse(dateVal.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inDays >= 30) {
        final m = (diff.inDays / 30).floor();
        return 'Posted $m month${m > 1 ? 's' : ''} ago';
      } else if (diff.inDays >= 1) {
        return 'Posted ${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      } else if (diff.inHours >= 1) {
        return 'Posted ${diff.inHours} hr${diff.inHours > 1 ? 's' : ''} ago';
      } else {
        return 'Posted today';
      }
    } catch (_) {
      return 'Recently';
    }
  }

  String _formatSalary(Map<String, dynamic> job) {
    final comp = job['compensation'] ?? job['salary'] ?? job['pay'] ?? job['wage'] ?? job['dailyPay'];
    if (comp == null || comp.toString().trim().isEmpty) {
      return 'Salary Negotiable';
    }
    final s = comp.toString().trim();
    if (s == '0' || s == '₹0') {
      return 'Salary Negotiable';
    }
    if (s.startsWith('₹') || s.toLowerCase().contains('lpa') || s.contains('/')) {
      return s;
    }
    final numVal = num.tryParse(s);
    if (numVal != null) {
      if (numVal == 0) return 'Salary Negotiable';
      if (numVal >= 100000) {
        final inLakhs = numVal / 100000;
        final formatted = inLakhs % 1 == 0 ? inLakhs.toStringAsFixed(0) : inLakhs.toStringAsFixed(1);
        return '₹$formatted LPA';
      }
      return '₹$numVal/day';
    }
    return '₹$s';
  }

  // --- 7. Tab 3: About Tab ---
  Widget _buildAboutTab(Map<String, dynamic> p) {
    final description = p['description']?.toString().trim();
    final hasDesc = description != null && description.isNotEmpty;

    final ownerName = (p['owner'] is Map
            ? (p['owner']['fullName'] ?? p['owner']['name'])
            : (p['user'] is Map ? (p['user']['fullName'] ?? p['user']['name']) : null))
        ?.toString()
        .trim();

    final businessType = p['businessType']?.toString().trim();
    final yearEstablished = p['yearEstablished']?.toString().trim();
    final teamSize = p['teamSizeRange']?.toString().trim();

    final email = (p['contactEmail'] ?? p['email'])?.toString().trim();
    final phone = (p['contactPhone'] ?? p['phone'])?.toString().trim();
    final altPhone = p['alternatePhone']?.toString().trim();
    final website = p['website']?.toString().trim();

    final address = p['address']?.toString().trim();
    final city = p['city']?.toString().trim();
    final state = p['state']?.toString().trim();
    final pincode = p['pincode']?.toString().trim();

    final cin = p['registrationNumber']?.toString().trim();
    final gstin = p['gstNumber']?.toString().trim();
    final pan = p['panNumber']?.toString().trim();
    final status = (p['verificationStatus'] ?? 'pending').toString().toLowerCase();
    final isVerified = status == 'verified';
    final remarks = p['verificationRemarks']?.toString().trim();

    final specializations = (p['specializations'] is List)
        ? List<String>.from(p['specializations']).where((s) => s.trim().isNotEmpty).toList()
        : <String>[];

    final operationalAreas = (p['operationalAreas'] is List)
        ? List<String>.from(p['operationalAreas']).where((a) => a.trim().isNotEmpty).toList()
        : <String>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // 1. Basic Details
        _buildAboutSectionCard(
          title: 'Basic Details',
          icon: Icons.business_rounded,
          onEdit: widget.isReadOnly ? null : () => _editProfile(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDesc) ...[
                const Text(
                  'About Company',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: Color(0xFF334155),
                  ),
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
              ],
              if (ownerName != null && ownerName.isNotEmpty) ...[
                _buildDetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Authorized Representative',
                  value: ownerName,
                ),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
              ],
              _buildDetailRow(
                icon: Icons.domain_outlined,
                label: 'Business Entity Type',
                value: (businessType != null && businessType.isNotEmpty) ? businessType : 'Not specified',
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Year Established',
                value: (yearEstablished != null && yearEstablished.isNotEmpty && yearEstablished != 'N/A')
                    ? yearEstablished
                    : 'Not specified',
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDetailRow(
                icon: Icons.groups_outlined,
                label: 'Workforce / Team Size',
                value: (teamSize != null && teamSize.isNotEmpty && teamSize != 'N/A')
                    ? '$teamSize employees'
                    : 'Not specified',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Contact & Communication
        _buildAboutSectionCard(
          title: 'Contact & Communication',
          icon: Icons.contact_phone_outlined,
          onEdit: widget.isReadOnly ? null : () => _editProfile(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                icon: Icons.email_outlined,
                label: 'Official Email',
                value: (email != null && email.isNotEmpty) ? email : 'Not provided',
                isLink: email != null && email.isNotEmpty,
                onTap: (email != null && email.isNotEmpty) ? () => _launchExternalUrl('mailto:$email') : null,
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDetailRow(
                icon: Icons.phone_outlined,
                label: 'Primary Phone',
                value: (phone != null && phone.isNotEmpty) ? phone : 'Not provided',
                isLink: phone != null && phone.isNotEmpty,
                onTap: (phone != null && phone.isNotEmpty) ? () => _launchExternalUrl('tel:$phone') : null,
              ),
              if (altPhone != null && altPhone.isNotEmpty) ...[
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _buildDetailRow(
                  icon: Icons.phone_callback_outlined,
                  label: 'Alternate Phone',
                  value: altPhone,
                  isLink: true,
                  onTap: () => _launchExternalUrl('tel:$altPhone'),
                ),
              ],
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDetailRow(
                icon: Icons.language_outlined,
                label: 'Official Website',
                value: (website != null && website.isNotEmpty) ? website : 'Not provided',
                isLink: website != null && website.isNotEmpty,
                onTap: (website != null && website.isNotEmpty) ? () => _launchExternalUrl(website) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Address & Location
        _buildAboutSectionCard(
          title: 'Address & Location',
          icon: Icons.location_on_outlined,
          onEdit: widget.isReadOnly ? null : () => _editProfile(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                icon: Icons.map_outlined,
                label: 'Registered Street Address',
                value: (address != null && address.isNotEmpty) ? address : 'Not provided',
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDetailRow(
                icon: Icons.location_city_outlined,
                label: 'City & State',
                value: [city, state].where((s) => s != null && s.isNotEmpty).isNotEmpty
                    ? [city, state].where((s) => s != null && s.isNotEmpty).join(', ')
                    : 'Not provided',
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDetailRow(
                icon: Icons.markunread_mailbox_outlined,
                label: 'Postal Pincode',
                value: (pincode != null && pincode.isNotEmpty) ? pincode : 'Not provided',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Legal & Registration
        _buildAboutSectionCard(
          title: 'Legal & Registration',
          icon: Icons.badge_outlined,
          onEdit: widget.isReadOnly ? null : () => _editProfile(p),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isVerified ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                width: 0.8,
              ),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isVerified ? const Color(0xFF15803D) : const Color(0xFFD97706),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (remarks != null && remarks.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          remarks,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              _buildDetailRow(
                icon: Icons.verified_user_outlined,
                label: 'CIN / Registration Number',
                value: (cin != null && cin.isNotEmpty) ? cin : 'Not provided',
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDetailRow(
                icon: Icons.receipt_long_outlined,
                label: 'GST Number (GSTIN)',
                value: (gstin != null && gstin.isNotEmpty) ? gstin : 'Not provided',
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDetailRow(
                icon: Icons.credit_card_outlined,
                label: 'PAN Card Number',
                value: (pan != null && pan.isNotEmpty) ? pan : 'Not provided',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Business Scope & Trades
        _buildAboutSectionCard(
          title: 'Business Scope',
          icon: Icons.work_outline_rounded,
          onEdit: widget.isReadOnly ? null : () => _editProfile(p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Project Specializations',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              specializations.isNotEmpty
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: specializations.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.companyTagBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.companyTagBorder, width: 0.8),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.companyTagText,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : const Text(
                      'No specializations specified.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF94A3B8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
              const SizedBox(height: 18),
              const Text(
                'Operational Areas',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              operationalAreas.isNotEmpty
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: operationalAreas.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                          ),
                          child: Text(
                            a,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : const Text(
                      'No operational areas specified.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF94A3B8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ],
          ),
        ),

        // 6. Action Buttons
        if (!widget.isReadOnly) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _editProfile(p),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.companyPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
              label: const Text(
                'Edit Company Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Log Out Company',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAboutSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onEdit,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.companyTagBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.companyPrimary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: AppColors.companyPrimary),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.companyPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (trailing != null)
                trailing,
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    final valueWidget = Text(
      value,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: isLink ? AppColors.companyPrimary : const Color(0xFF0F172A),
        decoration: isLink ? TextDecoration.underline : TextDecoration.none,
        decorationColor: AppColors.companyPrimary,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.companyTagBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.companyPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                if (onTap != null)
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(4),
                    child: valueWidget,
                  )
                else
                  valueWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Sticky TabBar Delegate ---
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return true;
  }
}
