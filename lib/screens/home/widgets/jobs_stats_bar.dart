import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../features/bloc/worker_blocs.dart';

class JobsStatsBar extends StatelessWidget {
  const JobsStatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobsCubit, LoadState<List<Job>>>(
      builder: (context, jobsState) {
        final jobs = jobsState is Loaded<List<Job>> ? jobsState.data : <Job>[];
        final openJobs = jobs.length;
        final hiringCompanies = jobs
            .map((j) => j.company)
            .where((c) => c.isNotEmpty)
            .toSet()
            .length;

        return BlocBuilder<DashboardCubit, LoadState<Map<String, dynamic>>>(
          builder: (context, dashState) {
            final dashData = dashState is Loaded<Map<String, dynamic>>
                ? dashState.data
                : <String, dynamic>{};
            final appliedCount =
                dashData['appliedJobs'] ?? jobs.where((j) => j.applied).length;
            final sitesCount = dashData['activeProjects'] ?? hiringCompanies;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                    count: '$openJobs',
                    label: 'Open Jobs',
                    barColor: AppColors.primary,
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: AppColors.border,
                  ),
                  _buildStatColumn(
                    count: '$sitesCount',
                    label: 'Active Sites',
                    barColor: AppColors.textMuted,
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: AppColors.border,
                  ),
                  _buildStatColumn(
                    count: '$appliedCount',
                    label: 'Applied Jobs',
                    barColor: AppColors.textMuted,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn({
    required String count,
    required String label,
    required Color barColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
