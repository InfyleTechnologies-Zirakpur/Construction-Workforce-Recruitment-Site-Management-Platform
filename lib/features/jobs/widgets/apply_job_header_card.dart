import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

/// Top job overview card for ApplyJobScreen matching Jobs Screen aesthetics:
/// company badge, wage & location highlights card, and peach skill tags.
class ApplyJobHeaderCard extends StatelessWidget {
  final Job job;

  const ApplyJobHeaderCard({super.key, required this.job});

  Widget _buildHighlightCol(String val, String label, Color valColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.peachBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.peachBorder, width: 1),
                ),
                child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.company,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                _buildHighlightCol('₹${job.dailyPay}/day', 'Daily Pay', AppColors.primary),
                Container(width: 1, height: 32, color: AppColors.border),
                _buildHighlightCol(job.location.isNotEmpty ? job.location : 'Site', 'Location', AppColors.textSecondary),
                Container(width: 1, height: 32, color: AppColors.border),
                _buildHighlightCol(
                  job.projectType.isNotEmpty ? job.projectType : 'Full time',
                  'Work Type',
                  AppColors.textSecondary,
                ),
              ],
            ),
          ),
          if (job.skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: job.skills.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.peachBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.peachBorder, width: 0.8),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    color: AppColors.peachText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
