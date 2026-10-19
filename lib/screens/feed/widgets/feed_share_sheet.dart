import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../features/bloc/worker_blocs.dart';

class FeedShareSheet extends StatelessWidget {
  final FeedPost post;

  const FeedShareSheet({super.key, required this.post});

  static void show(BuildContext context, FeedPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedShareSheet(post: post),
    );
  }

  String _generateShareText() {
    final titleStr = post.taggedTitle != null ? '\nRole: ${post.taggedTitle}' : '';
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
          content: Text('WhatsApp not installed. Post content copied to clipboard!'),
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
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.card,
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
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
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
}
