import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CompanyAnalyticsView extends StatelessWidget {
  final Map<String, dynamic>? reportsData;
  final int jobsCount;
  final int applicationsCount;
  final List<Map<String, dynamic>> companyJobs;
  final List<Map<String, dynamic>> applications;
  final VoidCallback? onNavigateToJobs;
  final ValueChanged<String>? onNavigateToApplications;

  const CompanyAnalyticsView({
    super.key,
    required this.reportsData,
    required this.jobsCount,
    required this.applicationsCount,
    this.companyJobs = const [],
    this.applications = const [],
    this.onNavigateToJobs,
    this.onNavigateToApplications,
  });

  int _countByStatus(String targetStatus) {
    if (applications.isNotEmpty) {
      return applications.where((a) {
        final st = (a['status'] ?? 'pending').toString().toLowerCase().trim();
        if (targetStatus == 'accepted') {
          return st == 'accepted' || st == 'hired';
        }
        return st == targetStatus;
      }).length;
    }
    // Fallback to reportsData if available
    var d = reportsData ?? {};
    if (d['data'] is Map) d = Map<String, dynamic>.from(d['data']);
    final funnel = d['funnel'] is Map ? Map<String, dynamic>.from(d['funnel']) : <String, dynamic>{};
    return (num.tryParse(funnel[targetStatus]?.toString() ?? '0') ?? 0).toInt();
  }

  Widget _statCard({
    required BuildContext context,
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (onTap != null)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF667085),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtext,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _interactiveFunnelTile({
    required BuildContext context,
    required String label,
    required String statusKey,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final percentage = total > 0 ? ((count / total) * 100).toStringAsFixed(0) : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigateToApplications?.call(statusKey),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppColors.dark,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$count',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                ' (${percentage}%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: Color(0xFF98A2B3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 7,
                              color: color,
                              backgroundColor: color.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTotalJobs = companyJobs.isNotEmpty ? companyJobs.length : jobsCount;
    final effectiveTotalApps = applications.isNotEmpty ? applications.length : applicationsCount;

    final pendingCount = _countByStatus('pending');
    final shortlistedCount = _countByStatus('shortlisted');
    final acceptedCount = _countByStatus('accepted');
    final rejectedCount = _countByStatus('rejected');

    final avgAppsPerJob = effectiveTotalJobs > 0
        ? (effectiveTotalApps / effectiveTotalJobs).toStringAsFixed(1)
        : '0.0';

    final hireRate = effectiveTotalApps > 0
        ? ((acceptedCount / effectiveTotalApps) * 100).toStringAsFixed(0)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Helper Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Hiring & Operations Analytics',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Live recruitment performance metrics',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 13, color: AppColors.success),
                  SizedBox(width: 3),
                  Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Responsive 2x2 Grid of Clickable Metric Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 320;
            final double cardWidth = isNarrow
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    context: context,
                    label: 'Total Requirements',
                    value: '$effectiveTotalJobs',
                    subtext: 'Site jobs posted',
                    icon: Icons.business_center_rounded,
                    color: AppColors.primary,
                    onTap: onNavigateToJobs,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    context: context,
                    label: 'Total Applications',
                    value: '$effectiveTotalApps',
                    subtext: 'Candidates applied',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF175CD3),
                    onTap: () => onNavigateToApplications?.call('all'),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    context: context,
                    label: 'Hiring Rate',
                    value: '$hireRate%',
                    subtext: 'Accepted candidates',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    onTap: () => onNavigateToApplications?.call('accepted'),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _statCard(
                    context: context,
                    label: 'Applications / Job',
                    value: avgAppsPerJob,
                    subtext: 'Candidate density',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFF7F56D9),
                    onTap: () => onNavigateToApplications?.call('all'),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 22),

        // Section Title: Interactive Recruitment Funnel
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Recruitment Funnel Breakdown',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            Text(
              'Tap stage to view',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 Clickable Funnel Stage Cards
        _interactiveFunnelTile(
          context: context,
          label: 'Pending Review',
          statusKey: 'pending',
          count: pendingCount,
          total: effectiveTotalApps,
          color: const Color(0xFFF79009),
          icon: Icons.hourglass_top_rounded,
        ),
        _interactiveFunnelTile(
          context: context,
          label: 'Shortlisted Candidates',
          statusKey: 'shortlisted',
          count: shortlistedCount,
          total: effectiveTotalApps,
          color: const Color(0xFF175CD3),
          icon: Icons.star_rounded,
        ),
        _interactiveFunnelTile(
          context: context,
          label: 'Accepted / Hired',
          statusKey: 'accepted',
          count: acceptedCount,
          total: effectiveTotalApps,
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        ),
        _interactiveFunnelTile(
          context: context,
          label: 'Rejected',
          statusKey: 'rejected',
          count: rejectedCount,
          total: effectiveTotalApps,
          color: AppColors.error,
          icon: Icons.cancel_rounded,
        ),
      ],
    );
  }
}
