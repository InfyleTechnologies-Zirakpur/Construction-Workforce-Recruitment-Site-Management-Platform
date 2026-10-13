import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CompanySiteJobsView extends StatelessWidget {
  final List<Map<String, dynamic>> companyJobs;
  final VoidCallback onNewJob;
  final Function(String jobId) onPublishJob;
  final Function(String jobId) onCloseJob;

  const CompanySiteJobsView({
    super.key,
    required this.companyJobs,
    required this.onNewJob,
    required this.onPublishJob,
    required this.onCloseJob,
  });

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
      case 'accepted':
        return Colors.green.withValues(alpha: 0.12);
      case 'shortlisted':
        return Colors.blue.withValues(alpha: 0.12);
      case 'closed':
      case 'rejected':
        return AppColors.error.withValues(alpha: 0.12);
      case 'draft':
      case 'pending':
      default:
        return Colors.orange.withValues(alpha: 0.12);
    }
  }

  Color _getStatusFgColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
      case 'accepted':
        return Colors.green;
      case 'shortlisted':
        return Colors.blue;
      case 'closed':
      case 'rejected':
        return AppColors.error;
      case 'draft':
      case 'pending':
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Posted Site Jobs (${companyJobs.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark)),
            TextButton.icon(
              onPressed: onNewJob,
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text('New Job', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (companyJobs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.inbox_outlined, size: 44, color: AppColors.primary),
                SizedBox(height: 10),
                Text('No Jobs Posted Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark)),
                SizedBox(height: 4),
                Text('Create a new job requirement to start receiving worker applications.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          )
        else
          ...companyJobs.map((job) {
            final jobId = job['id']?.toString() ?? '';
            final title = job['title']?.toString() ?? 'Job Requirement';
            final location = job['location']?.toString() ?? 'Location N/A';
            final pay = job['compensation'] ?? job['dailyPay'] ?? 0;
            final status = (job['status'] ?? 'draft').toString();
            final headcount = job['workforceRequired'] ?? 1;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.dark)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusFgColor(status))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(width: 14),
                      const Icon(Icons.groups_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('$headcount Workers', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Daily Pay: ₹ $pay / day', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Divider(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (status == 'draft')
                        ElevatedButton.icon(
                          onPressed: () => onPublishJob(jobId),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                          icon: const Icon(Icons.publish, size: 14),
                          label: const Text('Publish Job', style: TextStyle(fontSize: 12)),
                        ),
                      if (status == 'published') ...[
                        OutlinedButton.icon(
                          onPressed: () => onCloseJob(jobId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          icon: const Icon(Icons.block, size: 14),
                          label: const Text('Close Job', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
