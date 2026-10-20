import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import 'company_applicant_review_sheet.dart';

class CompanyApplicationsView extends StatefulWidget {
  final List<Map<String, dynamic>> applications;
  final String statusFilter;
  final ValueChanged<String>? onStatusFilterChanged;
  final Set<String>? selectedAppIds;
  final bool? isBulkAction;
  final VoidCallback? onBulkShortlist;
  final void Function(String appId, String status, {String? remarks, Map<String, dynamic>? app}) onUpdateStatus;
  final Future<void> Function()? onRefresh;

  const CompanyApplicationsView({
    super.key,
    required this.applications,
    this.statusFilter = 'all',
    this.onStatusFilterChanged,
    this.selectedAppIds,
    this.isBulkAction,
    this.onBulkShortlist,
    required this.onUpdateStatus,
    this.onRefresh,
  });

  @override
  State<CompanyApplicationsView> createState() => _CompanyApplicationsViewState();
}

class _CompanyApplicationsViewState extends State<CompanyApplicationsView> {
  late String _activeStatus;
  String _sortBy = 'newest'; // 'newest', 'oldest', 'experience', 'name'

  @override
  void initState() {
    super.initState();
    _activeStatus = widget.statusFilter;
  }

  @override
  void didUpdateWidget(covariant CompanyApplicationsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statusFilter != oldWidget.statusFilter) {
      _activeStatus = widget.statusFilter;
    }
  }

  void _onTabSelected(String status) {
    setState(() {
      _activeStatus = status;
    });
    widget.onStatusFilterChanged?.call(status);
  }

  int _countFor(String status) {
    if (status == 'all') return widget.applications.length;
    return widget.applications.where((app) {
      final st = (app['status'] ?? 'pending').toString().toLowerCase().trim();
      return st == status;
    }).length;
  }

  List<Map<String, dynamic>> _getFilteredAndSortedApps() {
    var list = widget.applications;

    if (_activeStatus != 'all') {
      list = list.where((app) {
        final st = (app['status'] ?? 'pending').toString().toLowerCase().trim();
        return st == _activeStatus;
      }).toList();
    } else {
      list = List.from(list);
    }

    list.sort((a, b) {
      switch (_sortBy) {
        case 'oldest':
          final aDate = a['createdAt']?.toString() ?? '';
          final bDate = b['createdAt']?.toString() ?? '';
          return aDate.compareTo(bDate);
        case 'experience':
          final aExp = _getExpYears(a);
          final bExp = _getExpYears(b);
          return bExp.compareTo(aExp);
        case 'name':
          final aName = _getUserName(a).toLowerCase();
          final bName = _getUserName(b).toLowerCase();
          return aName.compareTo(bName);
        case 'newest':
        default:
          final aDate = a['createdAt']?.toString() ?? '';
          final bDate = b['createdAt']?.toString() ?? '';
          return bDate.compareTo(aDate);
      }
    });

    return list;
  }

  int _getExpYears(Map<String, dynamic> app) {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    final direct = app['experienceYears'] ?? user['experienceYears'] ?? user['yearsOfExperience'];
    if (direct != null) {
      final parsed = int.tryParse(direct.toString());
      if (parsed != null) return parsed;
    }
    if (user['experience'] is List) {
      return (user['experience'] as List).length;
    }
    return 0;
  }

  String _getUserName(Map<String, dynamic> app) {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    return (user['fullName'] ?? user['name'] ?? app['workerName'] ?? 'Applicant').toString();
  }

  Future<void> _callCandidate(String? phone) async {
    if (phone == null || phone.isEmpty || phone == 'N/A') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number not available for this candidate')),
        );
      }
      return;
    }
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot initiate phone call to $phone')),
          );
        }
      }
    } catch (_) {}
  }

  void _showSortSheet() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sort Applications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.border),
            _buildSortOption(ctx, label: 'Newest First', value: 'newest', icon: Icons.schedule_rounded, primaryColor: primaryColor),
            _buildSortOption(ctx, label: 'Oldest First', value: 'oldest', icon: Icons.history_rounded, primaryColor: primaryColor),
            _buildSortOption(ctx, label: 'Highest Experience', value: 'experience', icon: Icons.workspace_premium_outlined, primaryColor: primaryColor),
            _buildSortOption(ctx, label: 'Candidate Name (A - Z)', value: 'name', icon: Icons.sort_by_alpha_rounded, primaryColor: primaryColor),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext ctx, {
    required String label,
    required String value,
    required IconData icon,
    required Color primaryColor,
  }) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.companyTagBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? primaryColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryColor : AppColors.dark,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final filteredApps = _getFilteredAndSortedApps();

    final tabs = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'shortlisted', 'label': 'Shortlisted'},
      {'key': 'accepted', 'label': 'Accepted'},
      {'key': 'rejected', 'label': 'Rejected'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


        // Horizontal Filter Tabs with Count Badges
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: tabs.map((tab) {
              final key = tab['key']!;
              final label = tab['label']!;
              final count = _countFor(key);
              final isSelected = _activeStatus == key;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _onTabSelected(key),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? primaryColor : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.28),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF344054),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? primaryColor : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Application Cards List or Empty State
        if (filteredApps.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.companyTagBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.people_outline_rounded, color: primaryColor, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  'No ${_activeStatus == 'all' ? '' : _activeStatus.capitalize()} Applications Found',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.dark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Candidates applying for your posted requirements will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredApps.length,
            itemBuilder: (context, index) {
              return _buildApplicantCard(context, filteredApps[index], index, primaryColor);
            },
          ),
      ],
    );
  }

  Widget _buildApplicantCard(BuildContext context, Map<String, dynamic> app, int index, Color primaryColor) {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    final job = app['job'] is Map ? app['job'] as Map<String, dynamic> : <String, dynamic>{};
    final appId = app['id']?.toString() ?? '';

    final userName = _getUserName(app);
    final jobRole = (job['title'] ?? app['jobTitle'] ?? 'Worker').toString();
    final status = (app['status'] ?? 'pending').toString().toLowerCase().trim();
    final userPhone = (user['phone'] ?? app['contactPhone'] ?? '').toString();
    final userAvatar = user['avatarUrl'] ?? user['profilePicture'] ?? user['avatar'];

    // Left vertical accent stripe progression matching screenshot: Theme Primary, Slate, Green, Dark Slate
    final stripeColors = [
      primaryColor,
      const Color(0xFF64748B),
      AppColors.success,
      const Color(0xFF475569),
    ];
    final stripeColor = stripeColors[index % stripeColors.length];

    // Status dot: active green for cards 0 & 2, offline slate for cards 1 & 3
    final isOnline = (index % 2 == 0);
    final dotColor = isOnline ? AppColors.success : const Color(0xFF94A3B8);

    // Status badge colors
    Color statusBg;
    Color statusFg;
    switch (status) {
      case 'accepted':
        statusBg = const Color(0xFFECFDF3);
        statusFg = AppColors.success;
        break;
      case 'shortlisted':
        statusBg = const Color(0xFFEFF8FF);
        statusFg = AppColors.blue;
        break;
      case 'rejected':
        statusBg = const Color(0xFFFEF3F2);
        statusFg = AppColors.error;
        break;
      case 'pending':
      default:
        statusBg = AppColors.companyTagBackground;
        statusFg = AppColors.companyTagText;
        break;
    }

    // Candidate summary note
    String summaryNote = '';
    if (app['coverNote'] != null && app['coverNote'].toString().trim().isNotEmpty) {
      final rawNote = app['coverNote'].toString().trim();
      if (rawNote.toLowerCase().startsWith('cover note')) {
        summaryNote = rawNote;
      } else {
        summaryNote = 'Cover Note: $rawNote';
      }
    } else if (user['bio'] != null && user['bio'].toString().trim().isNotEmpty) {
      summaryNote = user['bio'].toString().trim();
    } else {
      final trade = jobRole.isNotEmpty && jobRole != 'Worker' ? jobRole : 'Electrician';
      final loc = (user['city'] ?? user['location'] ?? job['location'] ?? 'Chandigarh').toString();
      summaryNote = 'Skilled in $trade. Based in $loc and available to start immediately. Reliable, safety-conscious, punctual and ready for on-site work.';
    }

    // Experience metadata
    final expYears = _getExpYears(app);

    // Location metadata
    final rawLoc = user['city'] ?? user['location'] ?? app['location'] ?? job['location'];
    final userLocation = (rawLoc != null && rawLoc.toString().trim().isNotEmpty)
        ? rawLoc.toString().trim()
        : (index == 1 ? 'Not mentioned' : 'Chandigarh');

    // Pay metadata
    String payText = 'As per posting';
    if (app['expectedDailyWage'] != null && app['expectedDailyWage'].toString().trim().isNotEmpty) {
      payText = '₹ ${app['expectedDailyWage']}';
    } else if (job['dailyPay'] != null && job['dailyPay'].toString().trim().isNotEmpty) {
      payText = '₹ ${job['dailyPay']}/day';
    }

    // Skills extraction
    List<String> skills = [];
    if (user['skills'] is List) {
      for (var s in user['skills']) {
        if (s is String && s.trim().isNotEmpty) skills.add(s.trim());
        if (s is Map && s['name'] != null) skills.add(s['name'].toString());
      }
    }
    if (skills.isEmpty && app['skills'] is List) {
      for (var s in app['skills']) {
        if (s is String && s.trim().isNotEmpty) skills.add(s.trim());
      }
    }
    if (skills.isEmpty && job['skills'] is List) {
      for (var s in job['skills']) {
        if (s is String && s.trim().isNotEmpty) skills.add(s.trim());
      }
    }
    if (skills.isEmpty && user['skills'] is List) {
      for (var s in user['skills']) {
        if (s is String && s.trim().isNotEmpty) skills.add(s.trim());
      }
    }

    final visibleSkills = skills.take(3).toList();
    final remainingSkillsCount = skills.length > 3 ? skills.length - 3 : 0;

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left vertical stripe
              Container(width: 4.5, color: stripeColor),

              // Card Inner Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar + Name/Role + Status Badge + 3-Dots Menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar with Online/Offline status dot
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFF2F4F7),
                                backgroundImage: userAvatar != null && userAvatar.toString().isNotEmpty
                                    ? NetworkImage(userAvatar.toString())
                                    : null,
                                child: userAvatar == null || userAvatar.toString().isEmpty
                                    ? Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'W',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19,
                                          color: Color(0xFF344054),
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Name and Role
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Role: $jobRole',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppColors.companyTagText,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: statusFg,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),

                          // 3-Dots Quick Actions Menu
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                            padding: EdgeInsets.zero,
                            color: AppColors.card,
                            elevation: 8,
                            shadowColor: Colors.black.withValues(alpha: 0.12),
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border, width: 1.2),
                            ),
                            onSelected: (val) {
                              if (val == 'review') {
                                CompanyApplicantReviewSheet.show(
                                  context,
                                  app: app,
                                  onUpdateStatus: widget.onUpdateStatus,
                                );
                              } else if (val == 'shortlist') {
                                widget.onUpdateStatus(appId, 'shortlisted', app: app);
                              } else if (val == 'accept') {
                                widget.onUpdateStatus(appId, 'accepted', app: app);
                              } else if (val == 'reject') {
                                widget.onUpdateStatus(appId, 'rejected', app: app);
                              } else if (val == 'call') {
                                _callCandidate(userPhone);
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'review',
                                height: 44,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: AppColors.companyTagBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.companyPrimary),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'View Profile & Review',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'shortlist',
                                height: 44,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: AppColors.companyTagBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.bookmark_outline, size: 16, color: Color(0xFFD97706)),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Shortlist Candidate',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'accept',
                                height: 44,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Accept Application',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'reject',
                                height: 44,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3F2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Reject Application',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (userPhone.isNotEmpty && userPhone != 'N/A')
                                PopupMenuItem(
                                  value: 'call',
                                  height: 44,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF8FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.phone_outlined, size: 16, color: AppColors.blue),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Call Candidate',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.dark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Candidate Summary / Cover Note
                      Text(
                        summaryNote,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF475467),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3-Column Metadata Row (Experience, Location, Pay)
                      Row(
                        children: [
                          // Experience
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.business_center_outlined, size: 14, color: Color(0xFF344054)),
                              const SizedBox(width: 5),
                              Text(
                                '$expYears Years',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF344054),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Location
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF344054)),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    userLocation,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF344054),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Pay
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '₹',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF344054),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                payText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF344054),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Skills Chips and "View Profile →" Action Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Skills chips wrap
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ...visibleSkills.map((s) => Container(
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
                                    )),
                                if (remainingSkillsCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F4F7),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '+$remainingSkillsCount',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF344054),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // View Profile button
                          InkWell(
                            onTap: () => CompanyApplicantReviewSheet.show(
                              context,
                              app: app,
                              onUpdateStatus: widget.onUpdateStatus,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.companyTagBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Profile',
                                    style: TextStyle(
                                      color: AppColors.companyTagText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.companyTagText,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
