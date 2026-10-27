import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../features/bloc/worker_blocs.dart';

class FeedCommentsSheet extends StatefulWidget {
  final FeedPost post;
  final bool isCompany;

  const FeedCommentsSheet({super.key, required this.post, this.isCompany = false});

  static void show(BuildContext context, FeedPost post, {bool isCompany = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedCommentsSheet(post: post, isCompany: isCompany),
    );
  }

  @override
  State<FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends State<FeedCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<PostComment>? _liveComments;
  bool _isLoadingComments = true;
  String _myAuthorName = '';
  String _myAuthorRole = 'Hiring Employer';
  bool _userIsCompany = false;

  bool get _isCompany => widget.isCompany || _userIsCompany;
  Color get _themePrimary => _isCompany ? AppColors.companyPrimary : AppColors.primary;

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
            _userIsCompany = true;
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
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
              if (profileState.data.skills.isNotEmpty) {
                myRole = profileState.data.skills.first;
              }
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
                  color: AppColors.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
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
                            icon: const Icon(Icons.close, size: 22, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoadingComments &&
                              (_liveComments == null || _liveComments!.isEmpty) &&
                              post.comments.isEmpty
                          ? Center(child: CircularProgressIndicator(color: _themePrimary))
                          : (commentsList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 40,
                                        color: AppColors.textMuted,
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
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x0A000000),
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
                                  fontSize: 15.5,
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
                            icon: Icon(
                              Icons.send_rounded,
                              color: _themePrimary,
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
              Builder(
                builder: (context) {
                  final isComp = _isCompany;
                  return CircleAvatar(
                    radius: 16,
                    backgroundColor: isComp ? AppColors.companyPrimary : AppColors.primary,
                    child: Text(
                      comment.authorName.isNotEmpty
                          ? comment.authorName[0].toUpperCase()
                          : (isComp ? 'C' : 'U'),
                      style: TextStyle(
                        color: isComp ? AppColors.dark : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
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
                                  fontSize: 15,
                                  color: AppColors.dark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${_formatCommentTime(comment.createdAt)}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.text,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 15.5,
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
                fontSize: 12,
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
                          fontSize: 14,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${_formatCommentTime(reply.createdAt)}',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reply.text,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14.5,
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
