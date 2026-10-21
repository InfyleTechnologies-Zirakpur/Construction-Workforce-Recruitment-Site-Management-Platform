import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

class ProfileStatsBar extends StatelessWidget {
  final WorkerProfile profile;
  final int verifiedDocsCount;

  const ProfileStatsBar({
    super.key,
    required this.profile,
    required this.verifiedDocsCount,
  });

  @override
  Widget build(BuildContext context) {
    final wage = profile.salaryExpectation.trim().isNotEmpty
        ? profile.salaryExpectation.trim()
        : '₹600/day';
    final skillsCount = profile.skills.length;

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
          _buildStatColumn('Expected Wage', wage, Icons.payments_outlined),
          _buildDivider(),
          _buildStatColumn('Trade Skills', '$skillsCount', Icons.construction_outlined),
          _buildDivider(),
          _buildStatColumn('Documents', '$verifiedDocsCount/2', Icons.verified_outlined),
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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
