import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CompleteProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double progress;
  final int progressPercent;
  final VoidCallback? onBackPressed;

  const CompleteProfileAppBar({
    super.key,
    required this.progress,
    required this.progressPercent,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(63);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.card,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.dark, size: 19),
        tooltip: 'Back',
        onPressed: onBackPressed ?? () => Navigator.maybePop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Flow',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Hire',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            'Complete Profile Registration',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: progressPercent == 100 ? const Color(0xFFDCFCE7) : AppColors.peachBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: progressPercent == 100 ? const Color(0xFF86EFAC) : AppColors.peachBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                progressPercent == 100 ? Icons.check_circle_rounded : Icons.bolt_rounded,
                size: 13,
                color: progressPercent == 100 ? const Color(0xFF15803D) : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '$progressPercent% Done',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: progressPercent == 100 ? const Color(0xFF15803D) : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 3,
        ),
      ),
    );
  }
}
