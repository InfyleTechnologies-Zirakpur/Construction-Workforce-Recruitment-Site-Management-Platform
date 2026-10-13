import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';


class FeedStatsBar extends StatelessWidget {
  final int activeJobs;
  final int newJobsToday;
  final int totalPosts;

  const FeedStatsBar({
    super.key,
    required this.activeJobs,
    required this.newJobsToday,
    required this.totalPosts,
  });

  Widget _buildStatColumn({
    required String count,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatColumn(
            count: '$activeJobs',
            label: 'Active Jobs',
            color: AppColors.primary,
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          _buildStatColumn(
            count: '$newJobsToday',
            label: 'New Today',
            color: AppColors.dark,
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          _buildStatColumn(
            count: '$totalPosts',
            label: 'Feed Posts',
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
