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
                backgroundColor: post.isMyPost ? AppColors.primary : const Color(0xFFF5A623),
                child: Text(
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.dark,
            ),
          ),
          if ((post.taggedTitle != null && post.taggedTitle!.isNotEmpty) ||
              (post.location != null && post.location!.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.peachBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.peachBorder, width: 0.8),
              ),
              child: Row(
                children: [
                  if (post.taggedTitle != null && post.taggedTitle!.isNotEmpty) ...[
                    const Icon(Icons.work_outline, size: 14, color: AppColors.peachText),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        post.taggedTitle!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.peachText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (post.taggedTitle != null &&
                      post.taggedTitle!.isNotEmpty &&
                      post.location != null &&
                      post.location!.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('|', style: TextStyle(color: AppColors.peachBorder, fontSize: 12)),
                    ),
                  if (post.location != null && post.location!.isNotEmpty) ...[
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.peachText),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        post.location!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.peachText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                          fontSize: 13.5,
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
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.dark),
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
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.dark),
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
