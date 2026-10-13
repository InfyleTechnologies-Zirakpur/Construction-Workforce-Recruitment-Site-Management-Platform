import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../features/bloc/worker_blocs.dart';
import 'widgets/my_job_card.dart';
import 'widgets/my_jobs_stats_bar.dart';

enum MyJobsFilter { saved, applied, archived }

class MyJobsScreen extends StatefulWidget {
  final MyJobsFilter initialFilter;
  final VoidCallback? onExploreJobs;

  const MyJobsScreen({
    super.key,
    this.initialFilter = MyJobsFilter.saved,
    this.onExploreJobs,
  });

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  late MyJobsFilter _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<JobsCubit>().load();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Job> _filter(List<Job> jobs) {
    List<Job> result;
    switch (_selectedFilter) {
      case MyJobsFilter.saved:
        result = jobs.where((job) => job.saved).toList();
        break;
      case MyJobsFilter.applied:
        result = jobs.where((job) => job.applied).toList();
        break;
      case MyJobsFilter.archived:
        result = const [];
        break;
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((job) {
        final title = job.title.toLowerCase();
        final company = job.company.toLowerCase();
        final loc = job.location.toLowerCase();
        final skills = job.skills.join(' ').toLowerCase();
        return title.contains(_searchQuery) ||
            company.contains(_searchQuery) ||
            loc.contains(_searchQuery) ||
            skills.contains(_searchQuery);
      }).toList();
    }

    return result;
  }

  Widget _buildFilterChip(String label, MyJobsFilter filter, int count) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.peachBackground : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No jobs here',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No jobs found matching "$_searchQuery"'
                  : (_selectedFilter == MyJobsFilter.saved
                      ? 'You haven\'t saved any jobs yet'
                      : _selectedFilter == MyJobsFilter.applied
                          ? 'You haven\'t applied to any jobs yet'
                          : 'Jobs you archive will appear here'),
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onExploreJobs != null) {
                  widget.onExploreJobs!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Explore Jobs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final content = RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => context.read<JobsCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Jobs',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track saved roles and every application in one place',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Bar matching Feed Screen & Jobs Screen
          Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search saved or applied jobs...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),

          // Summary Stats Bar
          BlocBuilder<JobsCubit, LoadState<List<Job>>>(
            builder: (context, state) {
              final allJobs = state is Loaded<List<Job>> ? state.data : <Job>[];
              return MyJobsStatsBar(allJobs: allJobs);
            },
          ),

          // Filter Segment Bar
          BlocBuilder<JobsCubit, LoadState<List<Job>>>(
            builder: (context, state) {
              final allJobs = state is Loaded<List<Job>> ? state.data : <Job>[];
              final savedCount = allJobs.where((j) => j.saved).length;
              final appliedCount = allJobs.where((j) => j.applied).length;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Saved', MyJobsFilter.saved, savedCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Applied', MyJobsFilter.applied, appliedCount),
                    const SizedBox(width: 8),
                    _buildFilterChip('Archived', MyJobsFilter.archived, 0),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Section Header matching Jobs Header
          BlocBuilder<JobsCubit, LoadState<List<Job>>>(
            builder: (context, state) {
              final allJobs = state is Loaded<List<Job>> ? state.data : <Job>[];
              final count = _selectedFilter == MyJobsFilter.applied
                  ? allJobs.where((j) => j.applied).length
                  : _selectedFilter == MyJobsFilter.saved
                      ? allJobs.where((j) => j.saved).length
                      : 0;

              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedFilter == MyJobsFilter.applied
                          ? 'Your Applications'
                          : _selectedFilter == MyJobsFilter.saved
                              ? 'Saved Opportunities'
                              : 'Archived Jobs',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.peachBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.peachBorder, width: 0.8),
                        ),
                        child: Text(
                          '$count ${_selectedFilter == MyJobsFilter.applied ? 'applied' : 'saved'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.peachText,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // Jobs List Section
          BlocBuilder<JobsCubit, LoadState<List<Job>>>(
            builder: (context, state) {
              if (state is Idle<List<Job>> || state is Loading<List<Job>>) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3.5,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading jobs...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is Failed<List<Job>>) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Unable to load your jobs', style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.read<JobsCubit>().load(),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final allJobs = (state as Loaded<List<Job>>).data;
              final jobs = _filter(allJobs);

              if (jobs.isEmpty) {
                return _buildEmptyState(context, textTheme);
              }

              return Column(
                children: jobs.map((job) {
                  return MyJobCard(
                    job: job,
                    filter: _selectedFilter,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (canPop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            _selectedFilter == MyJobsFilter.applied
                ? 'My Applications'
                : _selectedFilter == MyJobsFilter.saved
                    ? 'Saved Opportunities'
                    : 'My Jobs',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          backgroundColor: AppColors.card,
          elevation: 0,
        ),
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: content),
    );
  }
}
