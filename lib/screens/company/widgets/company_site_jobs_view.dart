import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/repositories/company_repository.dart';
import 'company_applicant_review_sheet.dart';

class CompanySiteJobsView extends StatefulWidget {
  final List<Map<String, dynamic>> companyJobs;
  final List<Map<String, dynamic>> applications;
  final VoidCallback onNewJob;
  final Function(String jobId) onPublishJob;
  final Function(String jobId) onCloseJob;
  final Function(String appId, String status, {String? remarks})? onUpdateStatus;
  final VoidCallback? onViewApplicants;

  const CompanySiteJobsView({
    super.key,
    required this.companyJobs,
    this.applications = const [],
    required this.onNewJob,
    required this.onPublishJob,
    required this.onCloseJob,
    this.onUpdateStatus,
    this.onViewApplicants,
  });

  @override
  State<CompanySiteJobsView> createState() => _CompanySiteJobsViewState();
}

class _CompanySiteJobsViewState extends State<CompanySiteJobsView> {
  String _activeFilter = 'all'; // 'all', 'draft', 'published', 'closed'

  int _countFor(String status) {
    if (status == 'all') return widget.companyJobs.length;
    return widget.companyJobs.where((job) {
      final st = (job['status'] ?? 'draft').toString().toLowerCase().trim();
      return st == status;
    }).length;
  }

  List<Map<String, dynamic>> _getFilteredJobs() {
    if (_activeFilter == 'all') {
      return widget.companyJobs;
    }
    return widget.companyJobs.where((job) {
      final st = (job['status'] ?? 'draft').toString().toLowerCase().trim();
      return st == _activeFilter;
    }).toList();
  }

  int _applicantCountForJob(Map<String, dynamic> job) {
    final jobId = (job['id'] ?? job['_id'] ?? job['jobId'])?.toString() ?? '';
    if (jobId.isEmpty) return 0;

    return widget.applications.where((app) {
      final rawJob = app['job'];
      final appJob = rawJob is Map ? rawJob as Map<String, dynamic> : <String, dynamic>{};
      final appJobId = (app['jobId'] ?? app['job_id'] ?? (rawJob is String ? rawJob : (appJob['id'] ?? appJob['_id'])))?.toString();
      return appJobId != null && appJobId == jobId;
    }).length;
  }

  String _formatPay(dynamic pay) {
    if (pay == null) return '0.00';
    if (pay is num) return pay.toStringAsFixed(2);
    final parsed = double.tryParse(pay.toString());
    if (parsed != null) return parsed.toStringAsFixed(2);
    return pay.toString();
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
    } else if (t.contains('helper') || t.contains('labour') || t.contains('loader') || t.contains('worker') || t.contains('hk')) {
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
    } else if (t.contains('construct') || t.contains('mason') || t.contains('civil') || t.contains('site')) {
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

  void _showJobDetails(BuildContext context, Map<String, dynamic> job) {
    final title = job['title']?.toString() ?? 'Requirement Details';
    final location = job['location']?.toString() ?? 'Location N/A';
    final pay = _formatPay(job['compensation'] ?? job['dailyPay']);
    final status = (job['status'] ?? 'draft').toString().toUpperCase();
    final headcount = job['workforceRequired'] ?? job['workersRequired'] ?? 1;
    final description = job['description']?.toString() ?? 'No additional description provided.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.border),
            const SizedBox(height: 6),
            _detailRow(Icons.location_on_outlined, 'Location', location),
            _detailRow(Icons.currency_rupee, 'Daily Compensation', '₹ $pay / day'),
            _detailRow(Icons.groups_outlined, 'Required Headcount', '$headcount Workers'),
            _detailRow(Icons.verified_outlined, 'Current Status', status),
            const SizedBox(height: 12),
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.dark)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showJobApplicantsSheet(BuildContext context, Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _JobApplicantsSheetContent(
        job: job,
        initialApplications: widget.applications,
        onUpdateStatus: widget.onUpdateStatus,
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final filteredJobs = _getFilteredJobs();

    final tabs = [
      {'key': 'all', 'label': 'All'},
      {'key': 'draft', 'label': 'Draft'},
      {'key': 'published', 'label': 'Published'},
      {'key': 'closed', 'label': 'Closed'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Filter Tabs with Badges
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: tabs.map((tab) {
              final key = tab['key']!;
              final label = tab['label']!;
              final count = _countFor(key);
              final isSelected = _activeFilter == key;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _activeFilter = key),
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
                            fontSize: 13,
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
                              fontSize: 11,
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

        // Job Cards List or Empty State
        if (filteredJobs.isEmpty)
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
                    color: AppColors.peachBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.work_outline_rounded, color: primaryColor, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  'No ${_activeFilter == 'all' ? '' : _activeFilter.capitalize()} Jobs Found',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.dark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Post a job requirement to start hiring site workforce.',
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
            itemCount: filteredJobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(context, filteredJobs[index], index, primaryColor);
            },
          ),
      ],
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job, int index, Color primaryColor) {
    final jobId = (job['id'] ?? job['_id'] ?? job['jobId'])?.toString() ?? '';
    final title = job['title']?.toString() ?? 'Job Requirement';
    final location = job['location']?.toString() ?? 'Location N/A';
    final pay = _formatPay(job['compensation'] ?? job['dailyPay']);
    final status = (job['status'] ?? 'draft').toString().toLowerCase().trim();
    final headcount = job['workforceRequired'] ?? job['workersRequired'] ?? job['headcount'] ?? job['vacancies'] ?? job['openings'];
    final rawDate = job['createdAt'] ?? job['postedAt'] ?? job['created_at'] ?? job['date'] ?? job['updatedAt'];
    final dateText = _formatDate(rawDate);

    final tradeTheme = _getTradeTheme(title);

    // Status Badge colors
    Color statusBg;
    Color statusFg;
    switch (status) {
      case 'published':
        statusBg = const Color(0xFFECFDF3);
        statusFg = AppColors.success;
        break;
      case 'closed':
        statusBg = const Color(0xFFFEF3F2);
        statusFg = AppColors.error;
        break;
      case 'draft':
      default:
        statusBg = AppColors.peachBackground;
        statusFg = AppColors.peachText;
        break;
    }

    // Skills extraction purely from API data
    final List<String> skills = [];
    if (job['skillsRequired'] is List) {
      for (var s in job['skillsRequired']) {
        if (s is String && s.trim().isNotEmpty) skills.add(s.trim());
      }
    }
    if (skills.isEmpty && job['skills'] is List) {
      for (var s in job['skills']) {
        if (s is String && s.trim().isNotEmpty) skills.add(s.trim());
      }
    }
    if (skills.isEmpty && job['tags'] is List) {
      for (var s in job['tags']) {
        if (s is String && s.trim().isNotEmpty) skills.add(s.trim());
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Trade Icon + Title & Location + Status Badge + 3-Dots Menu
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

              // Title and Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: tradeTheme.fg),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // 3-Dots Menu
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
                  if (val == 'details') {
                    _showJobDetails(context, job);
                  } else if (val == 'publish') {
                    widget.onPublishJob(jobId);
                  } else if (val == 'close') {
                    widget.onCloseJob(jobId);
                  } else if (val == 'applicants') {
                    _showJobApplicantsSheet(context, job);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'details',
                    height: 44,
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF344054)),
                        ),
                        const SizedBox(width: 10),
                        const Text('View Requirement Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                      ],
                    ),
                  ),
                  if (status == 'draft')
                    PopupMenuItem(
                      value: 'publish',
                      height: 44,
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.peachBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.near_me_rounded, size: 16, color: AppColors.peachText),
                          ),
                          const SizedBox(width: 10),
                          const Text('Publish Requirement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                        ],
                      ),
                    ),
                  if (status == 'published') ...[
                    PopupMenuItem(
                      value: 'applicants',
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
                            child: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.success),
                          ),
                          const SizedBox(width: 10),
                          const Text('View Candidates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'close',
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
                          const Text('Close Requirement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Daily Pay (Orange bold)
          Text(
            '₹ $pay / day',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.peachText,
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: Skills Chips (only if present in API)
          if (skills.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: skills.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF344054),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 14),
          ],

        
          // Row 4: Bottom Metadata (Date, Headcount) + Action Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Metadata (Date, Headcount)
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
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF344054)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (headcount != null && headcount.toString().isNotEmpty) ...[
                      const Icon(Icons.groups_outlined, size: 15, color: AppColors.dark),
                      const SizedBox(width: 4),
                      Text(
                        '$headcount Workers',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF344054)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

      
              if (status == 'draft')
                InkWell(
                  onTap: () => widget.onPublishJob(jobId),
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
                        Icon(Icons.near_me_rounded, size: 15, color: AppColors.peachText),
                        SizedBox(width: 6),
                        Text(
                          'Publish Job',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.peachText,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.peachText),
                      ],
                    ),
                  ),
                )
              else if (status == 'published')
                InkWell(
                  onTap: () => _showJobApplicantsSheet(context, job),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined, size: 15, color: AppColors.success),
                        SizedBox(width: 6),
                        Text(
                          'View Applicants',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.success),
                      ],
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () => _showJobDetails(context, job),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFF344054)),
                        SizedBox(width: 6),
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF344054),
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF344054)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TradeTheme {
  final Color bg;
  final Color fg;
  final IconData icon;

  const _TradeTheme({required this.bg, required this.fg, required this.icon});
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class _JobApplicantsSheetContent extends StatefulWidget {
  final Map<String, dynamic> job;
  final List<Map<String, dynamic>> initialApplications;
  final Function(String appId, String status, {String? remarks})? onUpdateStatus;

  const _JobApplicantsSheetContent({
    required this.job,
    required this.initialApplications,
    this.onUpdateStatus,
  });

  @override
  State<_JobApplicantsSheetContent> createState() => _JobApplicantsSheetContentState();
}

class _JobApplicantsSheetContentState extends State<_JobApplicantsSheetContent> {
  late List<Map<String, dynamic>> _apps;
  bool _isLoadingLive = false;
  final _repo = CompanyRepository();

  @override
  void initState() {
    super.initState();
    _apps = _filterMatching(widget.initialApplications);
    _fetchLiveFromApi();
  }

  String get _jobId => (widget.job['id'] ?? widget.job['_id'] ?? widget.job['jobId'])?.toString() ?? '';
  String get _title => (widget.job['title'] ?? 'Job Requirement').toString();

  List<Map<String, dynamic>> _filterMatching(List<Map<String, dynamic>> source) {
    final cleanJobId = _jobId.trim();
    if (cleanJobId.isEmpty) return [];

    return source.where((app) {
      final rawJob = app['job'];
      final appJob = rawJob is Map ? rawJob as Map<String, dynamic> : <String, dynamic>{};
      final appJobId = (app['jobId'] ?? app['job_id'] ?? (rawJob is String ? rawJob : (appJob['id'] ?? appJob['_id'])))?.toString().trim();
      return appJobId != null && appJobId == cleanJobId;
    }).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _fetchLiveFromApi() async {
    if (!mounted) return;
    setState(() => _isLoadingLive = true);
    try {
      final live = await _repo.getCompanyApplications(jobId: _jobId);
      if (mounted) {
        final filtered = _filterMatching(live);
        setState(() {
          _apps = filtered;
          _isLoadingLive = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLive = false);
    }
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'hired':
        return const Color(0xFFECFDF3);
      case 'rejected':
        return const Color(0xFFFEF3F2);
      case 'shortlisted':
        return const Color(0xFFEFF8FF);
      case 'pending':
      default:
        return const Color(0xFFFFF4ED);
    }
  }

  Color _getStatusFg(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'hired':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'shortlisted':
        return const Color(0xFF175CD3);
      case 'pending':
      default:
        return AppColors.peachText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Applicants for $_title',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _isLoadingLive && _apps.isEmpty
                                ? 'Connecting to API...'
                                : '${_apps.length} candidate(s) applied',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_isLoadingLive) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.border),
            Expanded(
              child: _isLoadingLive && _apps.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 12),
                          Text('Fetching applicants from server...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    )
                  : _apps.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECFDF3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_outline_rounded, color: AppColors.success, size: 30),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No Applicants for "$_title" Yet',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Applications submitted by workers for this requirement will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchLiveFromApi,
                          color: AppColors.primary,
                          child: ListView.builder(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _apps.length,
                            itemBuilder: (context, idx) {
                              final app = _apps[idx];
                              final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
                              final userName = (user['fullName'] ?? user['name'] ?? app['workerName'] ?? 'Candidate').toString();
                              final status = (app['status'] ?? 'pending').toString().toUpperCase();
                              final exp = app['experienceYears'] ?? user['experienceYears'] ?? 0;
                              final wage = app['expectedDailyWage'] != null ? '₹ ${app['expectedDailyWage']}' : 'As per posting';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(0xFFF2F4F7),
                                      child: Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'W',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  userName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppColors.dark,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _getStatusBg(status),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getStatusFg(status),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(Icons.work_outline_rounded, size: 13, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$exp Yrs Exp',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('•', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  wage,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    InkWell(
                                      onTap: () {
                                        if (widget.onUpdateStatus != null) {
                                          CompanyApplicantReviewSheet.show(
                                            context,
                                            app: app,
                                            onUpdateStatus: (id, newStatus, {remarks}) {
                                              setState(() {
                                                app['status'] = newStatus;
                                                if (remarks != null) app['reviewRemarks'] = remarks;
                                              });
                                              widget.onUpdateStatus!(id, newStatus, remarks: remarks);
                                            },
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: AppColors.peachBackground,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.peachBorder.withValues(alpha: 0.6),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          'Review',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.peachText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

