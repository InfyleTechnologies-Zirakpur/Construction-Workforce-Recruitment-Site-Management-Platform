import 'package:construction_workforce_recruitment_site_management_platform/features/jobs/apply_job_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../core/widgets/search/hero_search_bar.dart';
import '../../features/bloc/worker_blocs.dart';
import '../search/search_screen.dart';
import '../profile/worker_profile_screen.dart';
import '../jobs/my_jobs_screen.dart';
import '../messages/messages_screen.dart';
import '../notifications/notifications_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  // Which trade chip is active. null = "All". Defaults to whatever matches
  // the worker's own profile skills once that loads (see _applyDefaultTrade).
  _Trade? _selectedTrade;
  bool _defaultTradeApplied = false;

  @override
  void initState() {
    super.initState();
    // Assumes JobsCubit, NotificationsCubit and ProfileCubit are provided
    // above this widget in the tree, same as ProfileCubit is for
    // WorkerProfileScreen.
    context.read<JobsCubit>().load();
    context.read<NotificationsCubit>().load();
    context.read<ProfileCubit>().load();
    context.read<DashboardCubit>().load();
  }

  final List<_Trade> _trades = const [
    _Trade('Electrician', Icons.electrical_services),
    _Trade('Plumber', Icons.plumbing),
    _Trade('Mason', Icons.foundation),
    _Trade('Carpenter', Icons.carpenter),
    _Trade('Welder', Icons.local_fire_department),
    _Trade('Crane Op.', Icons.precision_manufacturing),
    _Trade('Painter', Icons.format_paint),
    _Trade('Laborer', Icons.engineering),
  ];

  // Very rough keyword match between a trade name and a job's title/skills.
  // TODO: once the backend supports a real `/jobs?trade=...` query, replace
  // this client-side matching with a proper server-side filter.
  String _tradeKey(_Trade trade) => trade.name.toLowerCase().split(' ').first;

  bool _matchesTrade(Job job, _Trade trade) {
    final key = _tradeKey(trade);
    return job.title.toLowerCase().contains(key) ||
        job.skills.any((s) => s.toLowerCase().contains(key));
  }

  // Picks the trade chip that best matches the worker's own profile skills,
  // e.g. a worker with skill "Mason" gets the Mason chip pre-selected.
  void _applyDefaultTrade(WorkerProfile profile) {
    if (_defaultTradeApplied) return;
    _Trade? match;
    for (final trade in _trades) {
      final key = _tradeKey(trade);
      if (profile.skills.any((s) => s.toLowerCase().contains(key))) {
        match = trade;
        break;
      }
    }
    setState(() {
      _selectedTrade = match;
      _defaultTradeApplied = true;
    });
  }

  void _showJobDetails(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobDetailsSheet(job: job),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<ProfileCubit, LoadState<WorkerProfile>>(
      listener: (context, state) {
        if (state is Loaded<WorkerProfile>) _applyDefaultTrade(state.data);
      },
      child: Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.foundation, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'BuildHire',
              style: textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ],
        ),
        actions: [
          BlocBuilder<NotificationsCubit, LoadState<List<WorkerNotification>>>(
            builder: (context, state) {
              final unread = state is Loaded<List<WorkerNotification>>
                  ? state.data.where((n) => !n.isRead).length
                  : 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _navIndex == 3
          ? const WorkerProfileScreen()
          : _navIndex == 1
          ? const MyJobsScreen()
          : _navIndex == 2
          ? const MessagesScreen()
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<JobsCubit>().load(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHero(context),
              _buildTradesRow(context),
              _buildStatsBar(context),
              _buildJobsHeader(context),
              BlocBuilder<JobsCubit, LoadState<List<Job>>>(
                builder: (context, state) {
                  if (state is Idle<List<Job>> || state is Loading<List<Job>>) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SmartSkeleton.list(
                        itemCount: 4,
                        hasLeading: true,
                        leadingSize: 44,
                        titleWords: 3,
                        subtitleWords: 2,
                        hasMeta: true,
                        hasTags: true,
                        tagCount: 3,
                      ),
                    );
                  }

                  if (state is Failed<List<Job>>) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Text('Unable to load jobs', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.read<JobsCubit>().load(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allJobs = (state as Loaded<List<Job>>).data;
                  final jobs = _selectedTrade == null
                      ? allJobs
                      : allJobs.where((j) => _matchesTrade(j, _selectedTrade!)).toList();

                  // ignore: avoid_print
                  print('🏠 [HOME SCREEN] Total Loaded: ${allJobs.length} | Trade Filter: "${_selectedTrade?.name ?? 'All'}" | Displayed: ${jobs.length}');

                  if (jobs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Center(
                        child: Text(
                          _selectedTrade == null
                              ? 'No job postings yet'
                              : 'No ${_selectedTrade!.name} jobs right now',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: jobs
                        .map((j) => _JobCard(
                              job: j,
                              onTap: () => _showJobDetails(context, j),
                              onSaveToggle: () => context.read<JobsCubit>().save(j.id),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_outlined),
            label: 'My Jobs',
            selectedIcon: Icon(Icons.bookmark,color: AppColors.primary),
          ),
          NavigationDestination(
            icon: Icon(Icons.messenger_outline),
            selectedIcon: Icon(Icons.message, color: AppColors.primary),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: HeroSearchBar(
        readOnly: true,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
        },
      ),
    );
  }

  Widget _buildTradesRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // null represents the "All" chip.
    final chips = <_Trade?>[null, ..._trades];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Browse by Trade', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            _selectedTrade == null
                ? 'Showing all jobs'
                : 'Showing jobs matched to your ${_selectedTrade!.name} skill',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final t = chips[i];
                final isSelected = t == _selectedTrade;

                return InkWell(
                  onTap: () => setState(() => _selectedTrade = t),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 84,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.black12,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          t?.icon ?? Icons.apps,
                          color: isSelected ? Colors.white : AppColors.primary,
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t?.name ?? 'All',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget stat(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 18,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        ),
      );
    }

    return BlocBuilder<JobsCubit, LoadState<List<Job>>>(
      builder: (context, jobsState) {
        final jobs = jobsState is Loaded<List<Job>> ? jobsState.data : <Job>[];
        final openJobs = jobs.length;
        final hiringCompanies = jobs.map((j) => j.company).toSet().length;

        return BlocBuilder<DashboardCubit, LoadState<Map<String, dynamic>>>(
          builder: (context, dashState) {
            final dashData = dashState is Loaded<Map<String, dynamic>> ? dashState.data : <String, dynamic>{};
            final appliedCount = dashData['appliedJobs'] ?? jobs.where((j) => j.applied).length;
            final sitesCount = dashData['activeProjects'] ?? hiringCompanies;

            return Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  stat('$openJobs', 'Open Jobs'),
                  stat('$sitesCount', 'Active Sites'),
                  stat('$appliedCount', 'Applied Jobs'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildJobsHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = _selectedTrade == null ? 'Latest Job Postings' : '${_selectedTrade!.name} Jobs';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: textTheme.titleMedium),
          InkWell(
            onTap: () {
              if (_selectedTrade != null) {
                setState(() => _selectedTrade = null);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              }
            },
            child: Text(
              _selectedTrade == null ? 'See all' : 'Clear filter',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Trade {
  final String name;
  final IconData icon;
  const _Trade(this.name, this.icon);
}

class _JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;
  const _JobCard({required this.job, required this.onTap, required this.onSaveToggle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (job.applied)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Applied',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.backgroundBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                InkWell(
                  onTap: onSaveToggle,
                  child: Icon(
                    job.saved ? Icons.bookmark : Icons.bookmark_border_outlined,
                    size: 23,
                    color: job.saved ? AppColors.primary : Colors.black45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.dark.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business, color: AppColors.dark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        job.company,
                        style: textTheme.bodySmall?.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: textTheme.bodySmall?.copyWith(fontSize: 12.5),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.payments_outlined,
                  size: 15,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  '₹${job.dailyPay}/day',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
            if (job.skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: job.skills
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 10.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JobDetailsSheet extends StatelessWidget {
  final Job job;

  const _JobDetailsSheet({required this.job});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: MediaQuery.of(context).size.height * .8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(job.company),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 8),
                Text(job.location),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.payments_outlined),
                const SizedBox(width: 8),
                Text('₹${job.dailyPay}/day'),
              ],
            ),
            const SizedBox(height: 20),
            Text('Job Description', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(job.description),
            if (job.requirements.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Requirements', style: textTheme.titleMedium),
              const SizedBox(height: 10),
              ...job.requirements.map(
                (requirement) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('\u2022  '),
                      Expanded(child: Text(requirement)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (job.skills.isNotEmpty)
              Wrap(
                spacing: 8,
                children: job.skills.map((e) => Chip(label: Text(e))).toList(),
              ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: job.applied
                    ? null
                    : () {
                        Navigator.pop(context); // close this bottom sheet first
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ApplyJobScreen(job: job)),
                        );
                      },
                child: Text(job.applied ? 'Already Applied' : 'Apply Now'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => _reportJob(context),
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Report this job'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportJob(BuildContext context) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this job?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Fraudulent listing, incorrect pay...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      await context.read<JobsCubit>().report(jobId: job.id, reason: result);
      if (context.mounted) {
        Navigator.pop(context); // close sheet
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job reported successfully.')));
      }
    }
  }
}
