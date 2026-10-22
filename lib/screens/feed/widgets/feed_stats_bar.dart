import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';


class FeedStatsBar extends StatelessWidget {
  final int activeJobs;
  final int newJobsToday;
  final int totalPosts;
  final bool isCompany;

  const FeedStatsBar({
    super.key,
    required this.activeJobs,
    required this.newJobsToday,
    required this.totalPosts,
    this.isCompany = false,
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
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0), width: 1.0),
      ),
      child: Row(
        children: [
          _buildStatColumn(
            count: '$activeJobs',
            label: 'Active Jobs',
            color: isCompany ? AppColors.companyPrimary : AppColors.primary,
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEAECF0)),
          _buildStatColumn(
            count: '$newJobsToday',
            label: 'New Today',
            color: AppColors.dark,
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEAECF0)),
          _buildStatColumn(
            count: '$totalPosts',
            label: 'Feed Posts',
            color: AppColors.dark,
          ),
        ],
      ),
    );
  }
}
