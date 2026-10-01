import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';

enum MyJobsFilter { saved, applied, archived }

class MyJobsScreen extends StatefulWidget {
  final MyJobsFilter initialFilter;
  const MyJobsScreen({super.key, this.initialFilter = MyJobsFilter.saved});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  late MyJobsFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    context.read<JobsCubit>().load();
  }

  List<Job> _filter(List<Job> jobs) {
    List<Job> result;
    switch (_selectedFilter) {
      case MyJobsFilter.saved:
        result = jobs.where((job) => job.saved).toList();
        // ignore: avoid_print
        print('💾 [MY JOBS - SAVED TAB] Total jobs in memory: ${jobs.length} | Saved count: ${result.length}');
        for (var j in result) {
          // ignore: avoid_print
          print('   -> Saved Job: "${j.title}" at "${j.company}" (ID: ${j.id})');
        }
        return result;
      case MyJobsFilter.applied:
        result = jobs.where((job) => job.applied).toList();
        // ignore: avoid_print
        print('📝 [MY JOBS - APPLIED TAB] Total jobs in memory: ${jobs.length} | Applied count: ${result.length}');
        for (var j in result) {
          // ignore: avoid_print
          print('   -> Applied Job: "${j.title}" at "${j.company}" (ID: ${j.id}, AppID: ${j.applicationId})');
        }
        return result;
      case MyJobsFilter.archived:
        // ignore: avoid_print
        print('📦 [MY JOBS - ARCHIVED TAB] Archived count: 0 (No archived jobs API connected)');
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final content = BlocBuilder<JobsCubit, LoadState<List<Job>>>(
      builder: (context, state) {
        if (state is Idle<List<Job>> || state is Loading<List<Job>>) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: SmartSkeleton.list(
              itemCount: 3,
              hasLeading: true,
              leadingSize: 48,
              titleWords: 3,
              subtitleWords: 2,
              hasMeta: true,
              hasTags: true,
            ),
          );
        }

        if (state is Failed<List<Job>>) {
          return Center(
            child: Text('Unable to load your jobs', style: textTheme.titleMedium),
          );
        }

        final allJobs = (state as Loaded<List<Job>>).data;
        final jobs = _filter(allJobs);
        return RefreshIndicator(
          onRefresh: () => context.read<JobsCubit>().load(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.w(20),
                  context.h(18),
                  context.w(20),
                  context.h(32),
                ),
                children: [
                  Text('My jobs', style: textTheme.headlineSmall?.copyWith(color: AppColors.dark)),
                  SizedBox(height: context.h(4)),
                  Text(
                    'Track saved roles and every application in one place.',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: context.h(18)),
                  _filters(context, allJobs),
                  SizedBox(height: context.h(18)),
                  _summary(context, allJobs),
                  SizedBox(height: context.h(20)),
                  Text(_sectionTitle, style: textTheme.titleMedium),
                  SizedBox(height: context.h(10)),
                  if (jobs.isEmpty) _emptyState(context) else ...jobs.map((job) => _JobStatusCard(job: job, filter: _selectedFilter)),
                ],
              ),
            ),
          ),
        );
      },
    );

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (canPop) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _selectedFilter == MyJobsFilter.applied
                ? 'My Applications'
                : _selectedFilter == MyJobsFilter.saved
                    ? 'Saved Opportunities'
                    : 'My Jobs',
          ),
        ),
        body: SafeArea(child: content),
      );
    }

    return Material(
      color: Colors.transparent,
      child: content,
    );
  }

  String get _sectionTitle {
    switch (_selectedFilter) {
      case MyJobsFilter.saved:
        return 'Saved opportunities';
      case MyJobsFilter.applied:
        return 'Your applications';
      case MyJobsFilter.archived:
        return 'Archived jobs';
    }
  }

  Widget _filters(BuildContext context, List<Job> jobs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(context, MyJobsFilter.saved, 'Saved', jobs.where((job) => job.saved).length),
          const SizedBox(width: 8),
          _filterChip(context, MyJobsFilter.applied, 'Applied', jobs.where((job) => job.applied).length),
          const SizedBox(width: 8),
          _filterChip(context, MyJobsFilter.archived, 'Archived', 0),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, MyJobsFilter filter, String label, int count) {
    final selected = _selectedFilter == filter;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _selectedFilter = filter),
      label: Text('$label  $count'),
      selectedColor: AppColors.primary.withValues(alpha: 0.16),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: selected ? AppColors.primary : AppColors.dark,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    );
  }

  Widget _summary(BuildContext context, List<Job> jobs) {
    final applied = jobs.where((job) => job.applied).length;
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_outlined, color: AppColors.primary, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              applied == 0
                  ? 'Start applying to jobs that match your skills.'
                  : 'You have $applied active application${applied == 1 ? '' : 's'}.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = _selectedFilter == MyJobsFilter.archived
        ? 'Jobs you archive will appear here.'
        : _selectedFilter == MyJobsFilter.saved
        ? 'Save jobs you want to apply for later.'
        : 'Your submitted applications will appear here.';
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.h(36), horizontal: context.w(22)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.work_outline, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text('Nothing here yet', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _JobStatusCard extends StatelessWidget {
  const _JobStatusCard({required this.job, required this.filter});
  final Job job;
  final MyJobsFilter filter;

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
          statusColor = Colors.grey;
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(context.w(15)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: context.w(46),
                width: context.w(46),
                decoration: BoxDecoration(color: AppColors.dark.withValues(alpha: .08), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.business_outlined, color: AppColors.dark),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(job.title, style: textTheme.titleSmall), const SizedBox(height: 2), Text(job.company, style: textTheme.bodySmall)])),
              _statusChip(context, statusLabel, statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 14, runSpacing: 7, children: [
            _info(Icons.location_on_outlined, job.location),
            _info(Icons.payments_outlined, '₹${job.dailyPay}/day'),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: job.skills.map((skill) => Chip(label: Text(skill, style: textTheme.bodySmall), visualDensity: VisualDensity.compact)).toList()),
          if (isApplied) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusDescription,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.black45), const SizedBox(width: 4), Text(text)]);
  Widget _statusChip(BuildContext context, String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold)));
}
