import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';
import '../feed/feed_screen.dart';
import '../jobs/my_jobs_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/worker_profile_screen.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_job_card.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/job_details_sheet.dart';
import 'widgets/jobs_stats_bar.dart';
import 'widgets/trade_filter_bar.dart';

class HomePage extends StatefulWidget {
  final int initialNavIndex;

  const HomePage({super.key, this.initialNavIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _navIndex;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedTrade;

  static const List<String> _tradeList = [
    'All',
    'Electrician',
    'Plumber',
    'Mason',
    'Carpenter',
    'Painter',
    'Welder',
    'Laborer',
  ];

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    context.read<JobsCubit>().load();
    context.read<NotificationsCubit>().load();
    context.read<ProfileCubit>().load();
    context.read<DashboardCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _tradeKey(String trade) => trade.toLowerCase().split(' ').first;

  bool _matchesTrade(Job job, String trade) {
    final key = _tradeKey(trade);
    return job.title.toLowerCase().contains(key) ||
        job.skills.any((s) => s.toLowerCase().contains(key)) ||
        job.description.toLowerCase().contains(key);
  }


  void _showJobDetails(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobDetailsSheet(job: job),
    );
  }

  Widget _buildJobsHeader(BuildContext context) {
    return BlocBuilder<JobsCubit, LoadState<List<Job>>>(
      builder: (context, state) {
        final total = state is Loaded<List<Job>> ? state.data.length : 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Open Opportunities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                  letterSpacing: -0.3,
                ),
              ),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.peachBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.peachBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '$total active',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.peachText,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobsTab(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<JobsCubit>().load(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 12),
            HomeSearchBar(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
            TradeFilterBar(
              tradeList: _tradeList,
              selectedTrade: _selectedTrade,
              onTradeSelected: (trade) =>
                  setState(() => _selectedTrade = trade),
            ),
            const JobsStatsBar(),
            _buildJobsHeader(context),
            BlocBuilder<JobsCubit, LoadState<List<Job>>>(
              builder: (context, state) {
                if (state is Idle<List<Job>> || state is Loading<List<Job>>) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SmartSkeleton.list(
                      itemCount: 4,
                      hasLeading: false,
                      titleWords: 2,
                      subtitleWords: 2,
                      hasMeta: true,
                      hasTags: true,
                      tagCount: 1,
                    ),
                  );
                }

                if (state is Failed<List<Job>>) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 32,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Text(
                            'Unable to load jobs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.read<JobsCubit>().load(),
                            child: const Text(
                              'Retry',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allJobs = (state as Loaded<List<Job>>).data;
                final query = _searchQuery.trim().toLowerCase();

                final jobs = allJobs.where((j) {
                  final matchesTrade =
                      _selectedTrade == null ||
                      _matchesTrade(j, _selectedTrade!);
                  final matchesSearch =
                      query.isEmpty ||
                      j.title.toLowerCase().contains(query) ||
                      j.company.toLowerCase().contains(query) ||
                      j.location.toLowerCase().contains(query) ||
                      j.skills.any((s) => s.toLowerCase().contains(query));
                  return matchesTrade && matchesSearch;
                }).toList();

                if (jobs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 36,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.work_off_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedTrade == null && query.isEmpty
                                ? 'No job postings yet'
                                : 'No matching jobs found',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF344054),
                            ),
                          ),
                          if (_selectedTrade != null || query.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedTrade = null;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              child: const Text(
                                'Clear filters',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: jobs
                      .map(
                        (j) => HomeJobCard(
                          job: j,
                          onTap: () => _showJobDetails(context, j),
                          onSaveToggle: () {
                            if (j.saved) {
                              context.read<JobsCubit>().unsave(j.id);
                            } else {
                              context.read<JobsCubit>().save(j.id);
                            }
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: HomeAppBar(navIndex: _navIndex),
        body: _navIndex == 4
            ? const WorkerProfileScreen()
            : _navIndex == 3
            ? MessagesScreen(onExploreJobs: () => setState(() => _navIndex = 1))
            : _navIndex == 2
            ? MyJobsScreen(onExploreJobs: () => setState(() => _navIndex = 1))
            : _navIndex == 0
            ? const FeedScreen(isCompany: false)
            : _buildJobsTab(context),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.card,
            indicatorColor: AppColors.peachBackground,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: AppColors.primary, size: 23);
              }
              return const IconThemeData(
                color: AppColors.textSecondary,
                size: 23,
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                );
              }
              return const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              );
            }),
          ),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _navIndex,
              onDestinationSelected: (i) => setState(() => _navIndex = i),
              height: 64,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.business_center_outlined),
                  selectedIcon: Icon(Icons.business_center_rounded),
                  label: 'Jobs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bookmark_border_rounded),
                  selectedIcon: Icon(Icons.bookmark_rounded),
                  label: 'My Jobs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Messages',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      );
  }
}
