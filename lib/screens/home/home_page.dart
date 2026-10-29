import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/jobs/apply_job_screen.dart';
import '../feed/feed_screen.dart';
import '../jobs/my_jobs_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/complete_profile_screen.dart';
import '../profile/worker_profile_screen.dart';
import '../search/search_screen.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_job_card.dart';
import 'widgets/job_details_sheet.dart';

class HomePage extends StatefulWidget {
  final int initialNavIndex;

  const HomePage({super.key, this.initialNavIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _navIndex;

  // Filter States
  String _primaryTabFilter = 'all'; // 'all', 'saved', 'applied'
  String _selectedRole = 'All Jobs';
  String _filterExperience = 'Any';
  String _filterProjectType = 'All';
  String _filterLocation = '';

  static const List<String> _roleList = [
    'All Jobs',
    'Engineers',
    'Operators',
    'Drivers',
    'Masons',
    'Electricians',
    'Plumbers',
    'Supervisors',
    'Laborers',
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
    super.dispose();
  }

  bool _matchesRoleCategory(Job j, String role) {
    if (role == 'All Jobs') return true;
    final r = role.toLowerCase();
    final title = j.title.toLowerCase();
    final skills = j.skills.map((s) => s.toLowerCase()).toList();
    final desc = j.description.toLowerCase();

    bool hasAny(List<String> keywords) {
      return keywords.any((k) =>
          title.contains(k) ||
          skills.any((s) => s.contains(k)) ||
          desc.contains(k));
    }

    if (r.contains('engineer')) {
      return hasAny(['engineer', 'civil', 'site eng', 'project eng', 'architect', 'b.tech', 'be ', 'cad', 'structural']);
    } else if (r.contains('operator')) {
      return hasAny(['operator', 'crane', 'jcb', 'excavator', 'loader', 'forklift', 'plant', 'machine']);
    } else if (r.contains('driver')) {
      return hasAny(['driver', 'truck', 'dumper', 'transit', 'vehicle']);
    } else if (r.contains('mason')) {
      return hasAny(['mason', 'brick', 'stone', 'plaster', 'tile', 'rajmistri']);
    } else if (r.contains('electrician')) {
      return hasAny(['electr', 'wire', 'lineman', 'power']);
    } else if (r.contains('plumber')) {
      return hasAny(['plumb', 'pipe', 'sanitary', 'fitter']);
    } else if (r.contains('supervisor')) {
      return hasAny(['supervisor', 'foreman', 'manager', 'coordinator', 'incharge', 'in-charge']);
    } else if (r.contains('laborer')) {
      return hasAny(['labor', 'labour', 'helper', 'beldar', 'unskilled', 'worker']);
    }
    return hasAny([r]);
  }

  void _showJobDetails(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobDetailsSheet(job: job),
    );
  }

  Widget _buildPrimaryTab(String label, String key) {
    final isSelected = _primaryTabFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _primaryTabFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          role,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        String tempExp = _filterExperience;
        String tempType = _filterProjectType;
        final locCtrl = TextEditingController(text: _filterLocation);

        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildSheetChip({
              required String label,
              required bool isSelected,
              required VoidCallback onTap,
            }) {
              return GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              );
            }

            return Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Jobs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 14),
                  const Text(
                    'Experience Level',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Any', 'Fresher', '1-3 Years', '3-5 Years', '5+ Years'].map((exp) {
                      final sel = tempExp == exp;
                      return buildSheetChip(
                        label: exp,
                        isSelected: sel,
                        onTap: () => setModalState(() => tempExp = exp),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Job Type',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Full-time', 'Contract', 'Daily Wage'].map((type) {
                      final sel = tempType == type;
                      return buildSheetChip(
                        label: type,
                        isSelected: sel,
                        onTap: () => setModalState(() => tempType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locCtrl,
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'City, state, or area...',
                      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filterExperience = 'Any';
                              _filterProjectType = 'All';
                              _filterLocation = '';
                            });
                            Navigator.pop(modalCtx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterExperience = tempExp;
                              _filterProjectType = tempType;
                              _filterLocation = locCtrl.text.trim();
                            });
                            Navigator.pop(modalCtx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildJobsTab(BuildContext context) {
    return BlocBuilder<JobsCubit, LoadState<List<Job>>>(
      builder: (context, state) {
        if (state is Idle<List<Job>> || state is Loading<List<Job>>) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SmartSkeleton.list(
                itemCount: 4,
                hasLeading: false,
                titleWords: 2,
                subtitleWords: 2,
                hasMeta: true,
                hasTags: true,
                tagCount: 3,
              ),
            ),
          );
        }

        if (state is Failed<List<Job>>) {
          return SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Unable to load jobs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
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
        final savedCount = allJobs.where((j) => j.saved).length;
        final appliedCount = allJobs.where((j) {
          final st = (j.applicationStatus ?? '').toLowerCase().trim();
          return j.applied || st == 'applied' || st == 'pending' || st == 'shortlisted';
        }).length;
        final hiredCount = allJobs.where((j) {
          final st = (j.applicationStatus ?? '').toLowerCase().trim();
          return st == 'hired' || st == 'accepted';
        }).length;
        final rejectedCount = allJobs.where((j) {
          final st = (j.applicationStatus ?? '').toLowerCase().trim();
          return st == 'rejected';
        }).length;

        // 1. Primary Filter Tab (All / Saved / Applied / Hired / Rejected)
        List<Job> filtered = allJobs;
        if (_primaryTabFilter == 'saved') {
          filtered = filtered.where((j) => j.saved).toList();
        } else if (_primaryTabFilter == 'applied') {
          filtered = filtered.where((j) {
            final st = (j.applicationStatus ?? '').toLowerCase().trim();
            return j.applied || st == 'applied' || st == 'pending' || st == 'shortlisted';
          }).toList();
        } else if (_primaryTabFilter == 'hired') {
          filtered = filtered.where((j) {
            final st = (j.applicationStatus ?? '').toLowerCase().trim();
            return st == 'hired' || st == 'accepted';
          }).toList();
        } else if (_primaryTabFilter == 'rejected') {
          filtered = filtered.where((j) {
            final st = (j.applicationStatus ?? '').toLowerCase().trim();
            return st == 'rejected';
          }).toList();
        }

        // 2. Role Category Filter
        if (_selectedRole != 'All Jobs') {
          filtered = filtered.where((j) => _matchesRoleCategory(j, _selectedRole)).toList();
        }

        // 3. Experience Filter
        if (_filterExperience != 'Any') {
          filtered = filtered.where((j) =>
              j.experienceLevel.toLowerCase().contains(_filterExperience.toLowerCase()) ||
              j.description.toLowerCase().contains(_filterExperience.toLowerCase())).toList();
        }

        // 4. Project Type Filter
        if (_filterProjectType != 'All') {
          filtered = filtered.where((j) =>
              j.projectType.toLowerCase().contains(_filterProjectType.toLowerCase())).toList();
        }

        // 5. Location Filter
        if (_filterLocation.isNotEmpty) {
          filtered = filtered.where((j) =>
              j.location.toLowerCase().contains(_filterLocation.toLowerCase())).toList();
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<JobsCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
       
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Construction Jobs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    InkWell(
                      onTap: () => _openFilterSheet(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF0F172A)),
                            SizedBox(width: 6),
                            Text(
                              'Filters',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

                // Primary Filter Tabs Row: All Jobs | Saved | Applied | Hired | Rejected
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildPrimaryTab('All Jobs (${allJobs.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildPrimaryTab('Saved ($savedCount)', 'saved'),
                      const SizedBox(width: 8),
                      _buildPrimaryTab('Applied ($appliedCount)', 'applied'),
                      const SizedBox(width: 8),
                      _buildPrimaryTab('Hired ($hiredCount)', 'hired'),
                      const SizedBox(width: 8),
                      _buildPrimaryTab('Rejected ($rejectedCount)', 'rejected'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Role Category Filter Pills: All Jobs | Engineers | Operators | Drivers | ...
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _roleList.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildRoleChip(r),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Job Cards List
                if (filtered.isEmpty)
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.work_off_outlined, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text(
                          'No jobs matching your filter',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try switching to another category or reset your filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _primaryTabFilter = 'all';
                              _selectedRole = 'All Jobs';
                              _filterExperience = 'Any';
                              _filterProjectType = 'All';
                              _filterLocation = '';
                            });
                          },
                          child: const Text('Reset All Filters', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map((j) {
                    return HomeJobCard(
                      job: j,
                      onTap: () => _showJobDetails(context, j),
                      onSaveToggle: () {
                        if (j.saved) {
                          context.read<JobsCubit>().unsave(j.id);
                        } else {
                          context.read<JobsCubit>().save(j.id);
                        }
                      },
                      onApply: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ApplyJobScreen(job: j)),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<JobsCubit>().load();
                          }
                        });
                      },
                    );
                  }),
              ],
            ),
          );
        },
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
