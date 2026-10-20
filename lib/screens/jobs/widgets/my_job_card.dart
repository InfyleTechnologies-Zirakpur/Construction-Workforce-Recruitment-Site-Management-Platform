import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../../features/bloc/worker_blocs.dart';
import '../../home/widgets/job_details_sheet.dart';
import '../my_jobs_screen.dart';

class _TradeTheme {
  final Color bg;
  final Color fg;
  final IconData icon;

  const _TradeTheme({
    required this.bg,
    required this.fg,
    required this.icon,
  });
}

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

  String _formatPay(int pay) {
    if (pay <= 0) return '0.00';
    return pay.toString();
  }

  String _formatWorkType(String type) {
    if (type.isEmpty) return 'Full time';
    final lower = type.toLowerCase();
    if (lower.contains('part')) return 'Part time';
    if (lower.contains('full')) return 'Full time';
    if (lower.contains('contract')) return 'Contract';
    return type;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr != null && dateStr.toString().trim().isNotEmpty) {
      try {
        final d = DateTime.parse(dateStr.toString().trim()).toLocal();
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final day = d.day.toString().padLeft(2, '0');
        final month = months[d.month - 1];
        return '$day $month ${d.year}';
      } catch (_) {}
    }
    return '';
  }

  _TradeTheme _getTradeTheme(String title) {
    final t = title.toLowerCase();
    if (t.contains('electr')) {
      return const _TradeTheme(
        bg: Color(0xFFFFF4ED),
        fg: Color(0xFFF95724),
        icon: Icons.bolt_rounded,
      );
    } else if (t.contains('helper') ||
        t.contains('labour') ||
        t.contains('loader') ||
        t.contains('worker') ||
        t.contains('hk')) {
      return const _TradeTheme(
        bg: Color(0xFFECFDF3),
        fg: Color(0xFF16A34A),
        icon: Icons.build_rounded,
      );
    } else if (t.contains('plumb')) {
      return const _TradeTheme(
        bg: Color(0xFFE0F2FE),
        fg: Color(0xFF0284C7),
        icon: Icons.plumbing_rounded,
      );
    } else if (t.contains('carpent')) {
      return const _TradeTheme(
        bg: Color(0xFFFEF3F2),
        fg: Color(0xFFD92D20),
        icon: Icons.carpenter_rounded,
      );
    } else if (t.contains('construct') ||
        t.contains('mason') ||
        t.contains('civil') ||
        t.contains('site')) {
      return const _TradeTheme(
        bg: Color(0xFFEFF8FF),
        fg: Color(0xFF007BFF),
        icon: Icons.apartment_rounded,
      );
    } else {
      return const _TradeTheme(
        bg: Color(0xFFF4F3FF),
        fg: Color(0xFF7C3AED),
        icon: Icons.engineering_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApplied = filter == MyJobsFilter.applied;

    final status = (job.applicationStatus ?? 'pending').toLowerCase();
    final Color statusColor;
    final Color statusBg;
    final String statusLabel;
    final IconData statusIcon;
    final String statusDescription;

    if (!isApplied) {
      statusLabel = 'Saved';
      statusColor = AppColors.primary;
      statusBg = AppColors.peachBackground;
      statusIcon = Icons.bookmark_added_outlined;
      statusDescription = 'Saved opportunity';
    } else {
      switch (status) {
        case 'accepted':
          statusLabel = 'Accepted';
          statusColor = const Color(0xFF16A34A);
          statusBg = const Color(0xFFECFDF3);
          statusIcon = Icons.check_circle_outline;
          statusDescription = 'Application accepted by employer';
          break;
        case 'rejected':
          statusLabel = 'Rejected';
          statusColor = const Color(0xFFDC2626);
          statusBg = const Color(0xFFFEF3F2);
          statusIcon = Icons.highlight_off;
          statusDescription = 'Application rejected';
          break;
        case 'shortlisted':
          statusLabel = 'Shortlisted';
          statusColor = const Color(0xFF7C3AED);
          statusBg = const Color(0xFFF4F3FF);
          statusIcon = Icons.star_border;
          statusDescription = 'Shortlisted for review';
          break;
        case 'withdrawn':
          statusLabel = 'Withdrawn';
          statusColor = AppColors.textMuted;
          statusBg = const Color(0xFFF2F4F7);
          statusIcon = Icons.remove_circle_outline;
          statusDescription = 'Application withdrawn';
          break;
        case 'pending':
        default:
          statusLabel = 'Under Review';
          statusColor = const Color(0xFF2563EB);
          statusBg = const Color(0xFFEFF8FF);
          statusIcon = Icons.schedule;
          statusDescription = 'Pending employer review';
          break;
      }
    }

    final payStr = _formatPay(job.dailyPay);
    final workTypeStr = _formatWorkType(job.projectType);
    final tradeTheme = _getTradeTheme(job.title);
    final dateText = _formatDate(job.createdAt);
    final headcount = job.workforceRequired;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                // Row 1: Trade Icon Box + Title & Company/Location + Status Badge or Bookmark
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Trade Icon Box
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: tradeTheme.bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(tradeTheme.icon, color: tradeTheme.fg, size: 24),
                    ),
                    const SizedBox(width: 12),

                    // Title & (Company • Location)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (job.company.isNotEmpty) ...[
                                Flexible(
                                  child: Text(
                                    job.company,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text('•', style: TextStyle(color: AppColors.textMuted)),
                                ),
                              ],
                              Icon(Icons.location_on_outlined, size: 14, color: tradeTheme.fg),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  job.location.isNotEmpty ? job.location : 'Site',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Top-right action: Bookmark button if Saved, or Status Badge if Applied
                    if (!isApplied)
                      InkWell(
                        onTap: () => _toggleSave(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: job.saved ? AppColors.peachBackground : const Color(0xFFF9FAFB),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: job.saved ? AppColors.peachBorder : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            job.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: job.saved ? AppColors.primary : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 2: Daily Pay (Worker Amber/Gold Flow)
                Text(
                  '₹ $payStr / day',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.peachText,
                  ),
                ),
                const SizedBox(height: 10),

                // Row 3: Skills Chips (from API)
                if (job.skills.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: job.skills.map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF344054),
                            ),
                          ),
                        )).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Row 4: Bottom Metadata or Applied Status Row
                if (!isApplied)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Metadata (Date, Headcount, Work Type)
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (dateText.isNotEmpty) ...[
                              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.dark),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  dateText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF344054),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            if (headcount != null && headcount > 0) ...[
                              const Icon(Icons.groups_outlined, size: 15, color: AppColors.dark),
                              const SizedBox(width: 4),
                              Text(
                                '$headcount Workers',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF344054),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ] else ...[
                              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.dark),
                              const SizedBox(width: 4),
                              Text(
                                workTypeStr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF344054),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Action Button (Apply Now / Applied)
                      if (job.applied)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 15, color: AppColors.success),
                              SizedBox(width: 5),
                              Text(
                                'Applied',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => _openDetails(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.peachBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_outlined, size: 15, color: AppColors.peachText),
                                SizedBox(width: 6),
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.peachText,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.peachText),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                else ...[
                  // Bottom section for Applied jobs
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
                      if (status == 'pending' &&
                          (job.applicationId != null || job.id.isNotEmpty))
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
                                  color: AppColors.peachText,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (job.reviewRemarks != null &&
                      job.reviewRemarks!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 8.5),
                      decoration: BoxDecoration(
                        color: AppColors.peachBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.peachBorder, width: 0.9),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.comment_outlined,
                              size: 15, color: AppColors.primary),
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
