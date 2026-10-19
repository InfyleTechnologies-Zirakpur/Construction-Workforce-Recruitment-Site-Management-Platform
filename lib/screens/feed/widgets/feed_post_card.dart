import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import 'feed_post_options_sheet.dart';

class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final String formattedTime;
  final VoidCallback onLikeToggle;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const FeedPostCard({
    super.key,
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
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
                                  : 'U'),
                        style: const TextStyle(
                          color: AppColors.dark,
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
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => FeedPostOptionsSheet.show(
                    context,
                    post: post,
                    onEdit: onEditTap,
                    onDelete: onDeleteTap,
                    onShare: onShareTap,
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
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.4,
              color: AppColors.dark,
            ),
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
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: Color(0xFF6B7280),
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
                onTap: onLikeToggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                        size: 19,
                        color: post.isLiked ? AppColors.primary : AppColors.dark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Like',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: post.isLiked ? FontWeight.bold : FontWeight.w600,
                          color: post.isLiked ? AppColors.primary : AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: onCommentTap,
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
                onTap: onShareTap,
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
