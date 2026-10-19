import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../../features/bloc/worker_blocs.dart';
import '../../home/widgets/job_details_sheet.dart';
import '../my_jobs_screen.dart';

class MyJobCard extends StatelessWidget {
  final Job job;
  final MyJobsFilter filter;

  const MyJobCard({
    super.key,
    required this.job,
    required this.filter,
  });

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobDetailsSheet(job: job),
    );
  }

  void _toggleSave(BuildContext context) {
    if (job.saved) {
      context.read<JobsCubit>().unsave(job.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job removed from saved bookmarks'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      context.read<JobsCubit>().save(job.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job saved to bookmarks'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _withdrawApplication(BuildContext context) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Withdraw Application?',
      message: 'Are you sure you want to withdraw your application for "${job.title}" at ${job.company}?',
      confirmLabel: 'Withdraw',
      cancelLabel: 'Keep Application',
      icon: Icons.assignment_return_outlined,
      isDestructive: false,
    );

    if (confirm && context.mounted) {
      final appId = job.applicationId ?? '';
      await context.read<JobsCubit>().withdraw(appId, jobId: job.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Application withdrawn successfully'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isApplied = filter == MyJobsFilter.applied;

    final status = (job.applicationStatus ?? 'pending').toLowerCase();
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;
    final String statusDescription;

    if (!isApplied) {
      statusLabel = 'Saved';
      statusColor = AppColors.primary;
      statusIcon = Icons.bookmark_added_outlined;
      statusDescription = 'Saved opportunity';
    } else {
      switch (status) {
        case 'accepted':
          statusLabel = 'Accepted';
          statusColor = const Color(0xFF16A34A);
          statusIcon = Icons.check_circle_outline;
          statusDescription = 'Status: Application accepted by employer';
          break;
        case 'rejected':
          statusLabel = 'Rejected';
          statusColor = const Color(0xFFDC2626);
          statusIcon = Icons.highlight_off;
          statusDescription = 'Status: Application rejected';
          break;
        case 'shortlisted':
          statusLabel = 'Shortlisted';
          statusColor = const Color(0xFF7C3AED);
          statusIcon = Icons.star_border;
          statusDescription = 'Status: Shortlisted for review';
          break;
        case 'withdrawn':
          statusLabel = 'Withdrawn';
          statusColor = AppColors.textMuted;
          statusIcon = Icons.remove_circle_outline;
          statusDescription = 'Status: Application withdrawn';
          break;
        case 'pending':
        default:
          statusLabel = 'Under Review';
          statusColor = const Color(0xFF2563EB);
          statusIcon = Icons.schedule;
          statusDescription = 'Status: Pending employer review';
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetails(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: AppColors.peachBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.peachBorder, width: 1),
                      ),
                      child: const Icon(
                        Icons.business_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: AppColors.dark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            job.company,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!isApplied)
                      IconButton(
                        onPressed: () => _toggleSave(context),
                        icon: Icon(
                          job.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: job.saved ? AppColors.primary : AppColors.textSecondary,
                          size: 22,
                        ),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            job.location,
                            style: const TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_outlined, size: 15, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '₹${job.dailyPay}/day',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (job.skills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: job.skills.take(3).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (isApplied) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          statusDescription,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (status == 'pending' && (job.applicationId != null || job.id.isNotEmpty))
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: AppColors.peachBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.peachBorder,
                              width: 0.9,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _withdrawApplication(context),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                'Withdraw',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (job.reviewRemarks != null && job.reviewRemarks!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8.5),
                      decoration: BoxDecoration(
                        color: AppColors.peachBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.peachBorder, width: 0.9),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.comment_outlined, size: 15, color: AppColors.primary),
                          const SizedBox(width: 7),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Employer Note: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  TextSpan(
                                    text: job.reviewRemarks!.trim(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
