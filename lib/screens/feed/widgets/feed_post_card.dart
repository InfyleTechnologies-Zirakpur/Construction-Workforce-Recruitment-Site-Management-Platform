import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import 'feed_post_options_sheet.dart';

class FeedPostCard extends StatefulWidget {
  final FeedPost post;
  final String formattedTime;
  final VoidCallback onLikeToggle;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onProfileTap;
  final bool? isCompany;
  const FeedPostCard({
    super.key,
    required this.post,
    required this.formattedTime,
    required this.onLikeToggle,
    required this.onCommentTap,
    required this.onShareTap,
    this.onEditTap,
    this.onDeleteTap,
    this.onProfileTap,
    this.isCompany,
  });

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  bool _isExpanded = false;
  late final TapGestureRecognizer _toggleRecognizer;

  @override
  void initState() {
    super.initState();
    _toggleRecognizer = TapGestureRecognizer()
      ..onTap = () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      };
  }

  @override
  void dispose() {
    _toggleRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isAuthorCompany = post.authorRole.toLowerCase().contains('company') ||
        post.authorRole.toLowerCase().contains('employer') ||
        post.authorRole.toLowerCase().contains('contractor');
    final isCompanyFlow = widget.isCompany == true ||
        Theme.of(context).primaryColor.toARGB32() == AppColors.companyPrimary.toARGB32();
    final themePrimary = isCompanyFlow ? AppColors.companyPrimary : AppColors.primary;
    final avatarBg = isCompanyFlow ? AppColors.companyPrimary : AppColors.primary;
    final avatarTextColor = isCompanyFlow ? AppColors.dark : Colors.white;

    final hasRole = post.taggedTitle != null &&
        post.taggedTitle!.trim().isNotEmpty &&
        post.taggedTitle!.trim().toLowerCase() != 'site report';
    final hasLocation = post.location != null && post.location!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onProfileTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: avatarBg,
                        backgroundImage: (post.authorAvatarUrl != null &&
                                post.authorAvatarUrl!.trim().isNotEmpty &&
                                post.authorAvatarUrl != 'null' &&
                                post.authorAvatarUrl != 'undefined')
                            ? NetworkImage(post.authorAvatarUrl!.trim())
                            : null,
                        child: (post.authorAvatarUrl != null &&
                                post.authorAvatarUrl!.trim().isNotEmpty &&
                                post.authorAvatarUrl != 'null' &&
                                post.authorAvatarUrl != 'undefined')
                            ? null
                            : Text(
                                post.authorName.length >= 3 && post.authorName.contains(' ')
                                    ? post.authorName
                                          .split(' ')
                                          .take(2)
                                          .map((e) => e.isNotEmpty ? e[0] : '')
                                          .join('')
                                          .toUpperCase()
                                    : (post.authorName.isNotEmpty
                                          ? post.authorName.substring(0, post.authorName.length.clamp(1, 3)).toUpperCase()
                                          : (isCompanyFlow ? 'C' : 'U')),
                                style: TextStyle(
                                  color: avatarTextColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: AppColors.dark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.formattedTime,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => FeedPostOptionsSheet.show(
                    context,
                    post: post,
                    onEdit: widget.onEditTap,
                    onDelete: widget.onDeleteTap,
                    onShare: widget.onShareTap,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.more_vert,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const textStyle = TextStyle(
                fontSize: 16.5,
                height: 1.45,
                color: AppColors.dark,
              );

              final textSpan = TextSpan(
                text: post.content,
                style: textStyle,
              );

              final textPainter = TextPainter(
                text: textSpan,
                textDirection: Directionality.of(context),
                maxLines: 5,
              )..layout(maxWidth: constraints.maxWidth);

              final bool isLong = textPainter.didExceedMaxLines ||
                  post.content.split('\n').length > 5;

              if (!isLong) {
                return Text(
                  post.content,
                  style: textStyle,
                );
              }

              if (_isExpanded) {
                return Text.rich(
                  TextSpan(
                    style: textStyle,
                    children: [
                      TextSpan(text: post.content),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: 'View less',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                        recognizer: _toggleRecognizer,
                      ),
                    ],
                  ),
                );
              }

              final linkSpan = TextSpan(
                text: ' ... View more',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryColor,
                ),
              );

              int low = 0;
              int high = post.content.length;
              int cutIndex = 0;

              while (low <= high) {
                final mid = (low + high) ~/ 2;
                final cleanSub = post.content.substring(0, mid).replaceAll(RegExp(r'\n+$'), '');

                final testSpan = TextSpan(
                  style: textStyle,
                  children: [
                    TextSpan(text: cleanSub),
                    linkSpan,
                  ],
                );
                final tp = TextPainter(
                  text: testSpan,
                  textDirection: Directionality.of(context),
                  maxLines: 5,
                )..layout(maxWidth: constraints.maxWidth);

                if (!tp.didExceedMaxLines) {
                  cutIndex = mid;
                  low = mid + 1;
                } else {
                  high = mid - 1;
                }
              }

              String finalSub = post.content.substring(0, cutIndex).replaceAll(RegExp(r'\n+$'), '');
              if (cutIndex < post.content.length) {
                final lastSpace = finalSub.lastIndexOf(' ');
                final lastNewline = finalSub.lastIndexOf('\n');
                final boundary = lastSpace > lastNewline ? lastSpace : -1;
                if (boundary != -1 && boundary > finalSub.length - 25) {
                  finalSub = finalSub.substring(0, boundary);
                }
              }
              finalSub = finalSub.trimRight();

              return Text.rich(
                TextSpan(
                  style: textStyle,
                  children: [
                    TextSpan(text: finalSub),
                    TextSpan(
                      text: ' ... View more',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColor,
                      ),
                      recognizer: _toggleRecognizer,
                    ),
                  ],
                ),
                maxLines: 5,
                overflow: TextOverflow.clip,
              );
            },
          ),
          if (hasRole || hasLocation) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasRole)
                    Text(
                      post.taggedTitle!.trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (hasLocation) ...[
                    if (hasRole) const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: themePrimary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            post.location!.trim(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
            '${post.likesCount} ${post.likesCount == 1 ? 'like' : 'likes'}   '
            '${post.commentsCount} ${post.commentsCount == 1 ? 'comment' : 'comments'}   '
            '${post.sharesCount} ${post.sharesCount == 1 ? 'share' : 'shares'}',
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: widget.onLikeToggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                        size: 19,
                        color: post.isLiked ? themePrimary : AppColors.dark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Like',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: post.isLiked ? FontWeight.bold : FontWeight.w600,
                          color: post.isLiked ? themePrimary : AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onCommentTap,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 19, color: AppColors.dark),
                      SizedBox(width: 6),
                      Text(
                        'Comment',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.dark),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onShareTap,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 19, color: AppColors.dark),
                      SizedBox(width: 6),
                      Text(
                        'Share',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AppColors.dark),
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
