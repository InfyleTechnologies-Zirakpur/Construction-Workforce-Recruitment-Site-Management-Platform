import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/feed_post_model.dart';

class FeedPostOptionsSheet extends StatelessWidget {
  final FeedPost post;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onReport;

  const FeedPostOptionsSheet({
    super.key,
    required this.post,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.onReport,
  });

  static Future<void> show(
    BuildContext context, {
    required FeedPost post,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onShare,
    VoidCallback? onReport,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FeedPostOptionsSheet(
        post: post,
        onEdit: onEdit,
        onDelete: onDelete,
        onShare: onShare,
        onReport: onReport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themePrimary = Theme.of(context).primaryColor;
    final isComp = themePrimary.toARGB32() == AppColors.companyPrimary.toARGB32();
    final activeChipBg = isComp ? AppColors.companyTagBackground : AppColors.peachBackground;
    final activeChipBorder = isComp ? AppColors.companyTagBorder : AppColors.peachBorder;
    final activeChipText = isComp ? AppColors.companyTagText : AppColors.peachText;
    final activeIconBg = activeChipBg;
    final activeIconColor = themePrimary;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Post Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Post by ${post.authorName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (post.taggedTitle != null && post.taggedTitle!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: activeChipBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: activeChipBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        post.taggedTitle!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: activeChipText,
                        ),
                      ),
                    )
                  else if (post.tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: activeChipBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: activeChipBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        post.tags.first,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: activeChipText,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              if (onEdit != null) ...[
                _buildOptionTile(
                  icon: Icons.edit_outlined,
                  iconColor: activeIconColor,
                  iconBgColor: activeIconBg,
                  title: 'Edit Post',
                  subtitle: 'Update your post message or photos',
                  onTap: () {
                    Navigator.of(context).pop();
                    onEdit!();
                  },
                ),
                const SizedBox(height: 6),
              ],
              if (onDelete != null) ...[
                _buildOptionTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: isComp ? AppColors.companyPrimary : AppColors.error,
                  iconBgColor: isComp ? AppColors.companyTagBackground : AppColors.error.withValues(alpha: 0.12),
                  title: 'Delete Post',
                  subtitle: 'Permanently remove this post from the feed',
                  isDestructive: !isComp,
                  onTap: () {
                    Navigator.of(context).pop();
                    onDelete!();
                  },
                ),
                const SizedBox(height: 6),
              ],
              if (onShare != null) ...[
                _buildOptionTile(
                  icon: Icons.share_outlined,
                  iconColor: activeIconColor,
                  iconBgColor: activeIconBg,
                  title: 'Share Post',
                  subtitle: 'Share with friends or other workers',
                  onTap: () {
                    Navigator.of(context).pop();
                    onShare!();
                  },
                ),
                const SizedBox(height: 6),
              ],
              if (!post.isMyPost && onReport != null) ...[
                _buildOptionTile(
                  icon: Icons.flag_outlined,
                  iconColor: activeIconColor,
                  iconBgColor: activeIconBg,
                  title: 'Report Post',
                  subtitle: 'Flag abusive, fake, or unsafe content',
                  isDestructive: false,
                  onTap: () {
                    Navigator.of(context).pop();
                    onReport!();
                  },
                ),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dark,
                    side: const BorderSide(
                      color: AppColors.border,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDestructive ? AppColors.error : AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
