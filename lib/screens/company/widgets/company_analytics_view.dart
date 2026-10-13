import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CompanyAnalyticsView extends StatelessWidget {
  final Map<String, dynamic>? reportsData;
  final int jobsCount;
  final int applicationsCount;

  const CompanyAnalyticsView({
    super.key,
    required this.reportsData,
    required this.jobsCount,
    required this.applicationsCount,
  });

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _funnelBar(String label, dynamic countVal, dynamic totalVal, Color color) {
    final count = num.tryParse(countVal.toString()) ?? 0;
    final total = num.tryParse(totalVal.toString()) ?? 1;
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.dark)),
              Text('$count Candidate(s)', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio.toDouble(),
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var d = reportsData ?? {};
    if (d['data'] is Map) {
      d = Map<String, dynamic>.from(d['data']);
    }
    final totalJobs = d['totalJobs'] ?? jobsCount;
    final totalApps = d['totalApplications'] ?? applicationsCount;
    final avgApps = d['averageApplicationsPerJob'] ?? 0;
    final funnel = d['funnel'] is Map ? Map<String, dynamic>.from(d['funnel']) : <String, dynamic>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hiring Overview & Funnel Analytics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statTile('Total Jobs', '$totalJobs', Icons.work_outline, AppColors.primary),
            const SizedBox(width: 10),
            _statTile('Applications', '$totalApps', Icons.people_outline, Colors.blue),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _statTile('Avg Applicants/Job', '$avgApps', Icons.analytics_outlined, Colors.purple),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Recruitment Funnel Stage Stats',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark),
        ),
        const SizedBox(height: 10),
        _funnelBar('Pending Review', funnel['pending'] ?? 0, totalApps, Colors.orange),
        _funnelBar('Shortlisted', funnel['shortlisted'] ?? 0, totalApps, Colors.blue),
        _funnelBar('Accepted / Hired', funnel['accepted'] ?? 0, totalApps, Colors.green),
        _funnelBar('Rejected', funnel['rejected'] ?? 0, totalApps, AppColors.error),
      ],
    );
  }
}
