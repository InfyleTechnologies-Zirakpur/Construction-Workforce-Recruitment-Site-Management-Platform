import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

class MyJobsStatsBar extends StatelessWidget {
  final List<Job> allJobs;

  const MyJobsStatsBar({
    super.key,
    required this.allJobs,
  });

  @override
  Widget build(BuildContext context) {
    final savedCount = allJobs.where((j) => j.saved).length;
    final appliedCount = allJobs.where((j) => j.applied).length;
    final underReviewCount = allJobs.where((j) {
      return j.applied && (j.applicationStatus == null || j.applicationStatus == 'pending');
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
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
          _buildStatColumn('Saved Roles', '$savedCount', Icons.bookmark_added_outlined),
          _buildDivider(),
          _buildStatColumn('Applications', '$appliedCount', Icons.assignment_outlined),
          _buildDivider(),
          _buildStatColumn('Under Review', '$underReviewCount', Icons.schedule_outlined),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
