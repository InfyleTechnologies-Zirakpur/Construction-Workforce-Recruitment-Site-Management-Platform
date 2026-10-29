import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import 'company_applicant_review_sheet.dart';
import 'company_candidate_card.dart';
import 'company_post_job_sheet.dart';

/// Company Hiring Screen / View
/// Replaces the legacy applications view with a high-fidelity replica
/// of the Job Openings & Candidate Management design.
class CompanyHiringView extends StatefulWidget {
  final List<Map<String, dynamic>> applications;
  final List<Map<String, dynamic>> companyJobs;
  final String statusFilter;
  final ValueChanged<String>? onStatusFilterChanged;
  final Set<String>? selectedAppIds;
  final bool? isBulkAction;
  final VoidCallback? onBulkShortlist;
  final void Function(String appId, String status, {String? remarks, Map<String, dynamic>? app}) onUpdateStatus;
  final Future<void> Function()? onRefresh;
  final Map<String, dynamic>? myProfile;
  final VoidCallback? onNewJob;
  final void Function(Map<String, dynamic> job)? onEditJob;

  const CompanyHiringView({
    super.key,
    required this.applications,
    this.companyJobs = const [],
    this.statusFilter = 'all',
    this.onStatusFilterChanged,
    this.selectedAppIds,
    this.isBulkAction,
    this.onBulkShortlist,
    required this.onUpdateStatus,
    this.onRefresh,
    this.myProfile,
    this.onNewJob,
    this.onEditJob,
  });

  @override
  State<CompanyHiringView> createState() => _CompanyHiringViewState();
}

class _CompanyHiringViewState extends State<CompanyHiringView> {
  // 'active' or 'closed' tab for Job Openings
  String _jobFilter = 'active';

  // Selected job for candidate view (null means showing Job Openings list)
  String? _selectedJobId;
  Map<String, dynamic>? _selectedJob;

  Map<String, dynamic>? get _effectiveSelectedJob {
    if (_selectedJobId == null && _selectedJob == null) return null;
    if (_selectedJobId != null) {
      final allJobs = _getAllJobs();
      for (final j in allJobs) {
        final id = (j['id'] ?? j['_id'] ?? j['jobId'])?.toString();
        if (id != null && id == _selectedJobId) {
          return j;
        }
      }
    }
    return _selectedJob;
  }

  // Filter inside Candidate View: 'all', 'applied', 'shortlisted', 'hired', 'rejected'
  String _candidateStatusFilter = 'all';

  // Search query in Candidate View
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to extract clean job list
  List<Map<String, dynamic>> _getAllJobs() {
    final List<Map<String, dynamic>> result = [];
    final Set<String> seenIds = {};

    for (final j in widget.companyJobs) {
      final id = (j['id'] ?? j['_id'] ?? j['jobId'])?.toString() ?? '';
      if (id.isNotEmpty) seenIds.add(id);
      result.add(Map<String, dynamic>.from(j));
    }

    // Extract synthetic jobs from applications if any apps don't belong to known jobs
    for (final app in widget.applications) {
      final rawJob = app['job'];
      final jobMap = rawJob is Map ? Map<String, dynamic>.from(rawJob) : <String, dynamic>{};
      final appIdJobId = (app['jobId'] ?? app['job_id'] ?? jobMap['id'] ?? jobMap['_id'])?.toString();
      if (appIdJobId != null && appIdJobId.isNotEmpty && !seenIds.contains(appIdJobId)) {
        seenIds.add(appIdJobId);
        result.add({
          'id': appIdJobId,
          '_id': appIdJobId,
          'title': (jobMap['title'] ?? app['jobTitle'] ?? 'Site Requirement').toString(),
          'location': (jobMap['location'] ?? app['location'] ?? 'Location not specified').toString(),
          'compensation': jobMap['compensation'] ?? jobMap['dailyPay'] ?? jobMap['salary'] ?? 0,
          'type': jobMap['projectType'] ?? jobMap['type'] ?? 'Full-time',
          'experience': jobMap['experienceLevel'] ?? jobMap['experience'] ?? 'Any',
          'status': jobMap['status'] ?? 'published',
          'createdAt': app['createdAt'] ?? DateTime.now().toIso8601String(),
        });
      }
    }

    return result;
  }

  bool _isJobClosed(Map<String, dynamic> job) {
    final st = (job['status'] ?? 'published').toString().toLowerCase().trim();
    return st == 'closed' || st == 'inactive' || st == 'expired';
  }

  List<Map<String, dynamic>> _getFilteredJobs() {
    final all = _getAllJobs();
    if (_jobFilter == 'closed') {
      return all.where(_isJobClosed).toList();
    }
    return all.where((j) => !_isJobClosed(j)).toList();
  }

  List<Map<String, dynamic>> _getApplicationsForJob(Map<String, dynamic> job) {
    final jobId = (job['id'] ?? job['_id'] ?? job['jobId'])?.toString().trim();
    final jobTitle = job['title']?.toString().toLowerCase().trim();

    return widget.applications.where((app) {
      final rawJob = app['job'];
      final appJob = rawJob is Map ? rawJob as Map<String, dynamic> : <String, dynamic>{};
      final appJobId = (app['jobId'] ?? app['job_id'] ?? (rawJob is String ? rawJob : (appJob['id'] ?? appJob['_id'])))?.toString().trim();

      if (jobId != null && jobId.isNotEmpty && appJobId != null && appJobId.isNotEmpty) {
        if (appJobId == jobId) return true;
      }

      final appTitle = (appJob['title'] ?? app['jobTitle'])?.toString().toLowerCase().trim();
      if (jobTitle != null && jobTitle.isNotEmpty && appTitle != null && appTitle.isNotEmpty) {
        if (jobTitle == appTitle) return true;
      }

      return false;
    }).toList();
  }

  int _countStatus(List<Map<String, dynamic>> apps, String category) {
    return apps.where((a) {
      final s = (a['status'] ?? 'pending').toString().toLowerCase().trim();
      switch (category) {
        case 'applied':
          return s == 'pending' || s == 'applied';
        case 'shortlisted':
          return s == 'shortlisted';
        case 'hired':
          return s == 'accepted' || s == 'hired';
        case 'rejected':
          return s == 'rejected';
        default:
          return true;
      }
    }).length;
  }

  String _formatTimeAgo(dynamic dateVal) {
    if (dateVal == null) return 'Recently';
    try {
      final dt = dateVal is DateTime ? dateVal : DateTime.parse(dateVal.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inDays >= 30) {
        final m = (diff.inDays / 30).floor();
        return 'Posted $m month${m > 1 ? 's' : ''} ago';
      } else if (diff.inDays >= 1) {
        return 'Posted ${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      } else if (diff.inHours >= 1) {
        return 'Posted ${diff.inHours} hr${diff.inHours > 1 ? 's' : ''} ago';
      } else {
        return 'Posted today';
      }
    } catch (_) {
      return 'Recently';
    }
  }

  String _formatSalary(Map<String, dynamic> job) {
    final comp = job['compensation'] ?? job['salary'] ?? job['pay'] ?? job['wage'] ?? job['dailyPay'];
    if (comp == null || comp.toString().trim().isEmpty) {
      return 'Salary Negotiable';
    }
    final s = comp.toString().trim();
    if (s == '0' || s == '₹0') {
      return 'Salary Negotiable';
    }
    if (s.startsWith('₹') || s.toLowerCase().contains('lpa') || s.contains('/')) {
      return s;
    }
    final numVal = num.tryParse(s);
    if (numVal != null) {
      if (numVal == 0) return 'Salary Negotiable';
      if (numVal >= 100000) {
        final inLakhs = numVal / 100000;
        final formatted = inLakhs % 1 == 0 ? inLakhs.toStringAsFixed(0) : inLakhs.toStringAsFixed(1);
        return '₹$formatted LPA';
      }
      return '₹$numVal/day';
    }
    return '₹$s';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'AP';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _getUserName(Map<String, dynamic> app) {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    return (user['fullName'] ?? user['name'] ?? app['workerName'] ?? 'Candidate').toString();
  }

  String _getCandidateCompany(Map<String, dynamic> app) {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    final userExp = user['experience'];
    if (userExp is List && userExp.isNotEmpty) {
      final first = userExp.first;
      if (first is Map) {
        final c = first['company'] ?? first['employer'] ?? first['title'] ?? first['role'];
        if (c != null && c.toString().trim().isNotEmpty) {
          return c.toString().trim();
        }
      } else if (first != null && first.toString().trim().isNotEmpty) {
        return first.toString().trim();
      }
    }
    final comp = user['currentCompany'] ??
        user['company'] ??
        user['currentEmployer'] ??
        user['previousCompany'] ??
        user['trade'] ??
        user['role'] ??
        app['trade'] ??
        app['currentCompany'];
    if (comp != null && comp.toString().trim().isNotEmpty) {
      return comp.toString().trim();
    }
    final skills = user['skills'];
    if (skills is List && skills.isNotEmpty && skills[0] != null) {
      return '${skills[0]} Specialist';
    }
    return 'Candidate';
  }

  String _getCandidateEmail(Map<String, dynamic> app) {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    final email = user['email'] ?? app['email'] ?? app['workerEmail'];
    if (email != null && email.toString().trim().isNotEmpty) {
      return email.toString().trim();
    }
    return '';
  }

  String _getCandidatePhone(Map<String, dynamic> app) {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    final phone = user['phone'] ?? app['phone'] ?? app['contactPhone'];
    if (phone != null && phone.toString().trim().isNotEmpty) {
      return phone.toString().trim();
    }
    return '';
  }

  String _getCandidateLocation(Map<String, dynamic> app, Map<String, dynamic>? job) {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    final city = user['city']?.toString().trim();
    final state = user['state']?.toString().trim();
    if (city != null && city.isNotEmpty && state != null && state.isNotEmpty) {
      return '$city, $state';
    }
    if (city != null && city.isNotEmpty) return city;
    final loc = user['location'] ?? user['address'] ?? app['location'];
    if (loc != null && loc.toString().trim().isNotEmpty) {
      return loc.toString().trim();
    }
    final jobLoc = job?['location']?.toString().trim();
    if (jobLoc != null && jobLoc.isNotEmpty) return jobLoc;
    return 'Location not specified';
  }

  String _getCandidateExperience(Map<String, dynamic> app) {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    final exp = app['experience'] ??
        app['experienceYears'] ??
        user['experienceYears'] ??
        user['yearsOfExperience'] ??
        user['experience'];
    if (exp != null) {
      if (exp is List) {
        if (exp.isEmpty) return 'Experience not specified';
        return '${exp.length} year${exp.length > 1 ? 's' : ''} recorded';
      }
      final p = int.tryParse(exp.toString());
      if (p != null) return '$p years experience';
      final s = exp.toString().trim();
      if (s.isNotEmpty) {
        if (s.toLowerCase().contains('year')) return s;
        return '$s experience';
      }
    }
    return 'Experience not specified';
  }

  Future<void> _callPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _viewResume(Map<String, dynamic> app) async {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    final resumeUrl = app['resumeUrl']?.toString() ??
        user['resumeUrl']?.toString() ??
        app['resume']?.toString() ??
        user['resume']?.toString();

    if (resumeUrl != null && resumeUrl.trim().isNotEmpty) {
      final uri = Uri.tryParse(resumeUrl.trim());
      if (uri != null) {
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        } catch (_) {}
      }
    }
    // Fallback to comprehensive applicant review sheet
    if (mounted) {
      CompanyApplicantReviewSheet.show(
        context,
        app: app,
        onUpdateStatus: widget.onUpdateStatus,
      );
    }
  }

  void _openEditJob(Map<String, dynamic> job) {
    if (widget.onEditJob != null) {
      widget.onEditJob!(job);
    } else {
      CompanyPostJobSheet.show(
        context,
        myProfile: widget.myProfile,
        existingJob: job,
        onJobPosted: () {
          widget.onRefresh?.call();
        },
      );
    }
  }

  void _openNewJob() {
    if (widget.onNewJob != null) {
      widget.onNewJob!();
    } else {
      CompanyPostJobSheet.show(
        context,
        myProfile: widget.myProfile,
        onJobPosted: () {
          widget.onRefresh?.call();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeJob = _effectiveSelectedJob;
    if (activeJob != null) {
      return _buildManageApplicantsView(context, activeJob);
    }
    return _buildJobOpeningsView(context);
  }

  // =========================================================================
  // VIEW 1: Job Openings List Screen (Exact Replica of Image 1 & Image 2)
  // =========================================================================
  Widget _buildJobOpeningsView(BuildContext context) {
    final allJobs = _getAllJobs();
    final activeCount = allJobs.where((j) => !_isJobClosed(j)).length;
    final closedCount = allJobs.where(_isJobClosed).length;
    final displayJobs = _getFilteredJobs();

    const warmAmber = Color(0xFFF5A623); // Primary theme warm amber

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Header Row: Title + Count Subtitle & Yellow "+" Action Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Openings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeCount active • $closedCount closed',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            // Yellow action button (+ Post Job)
            GestureDetector(
              onTap: _openNewJob,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                decoration: BoxDecoration(
                  color: warmAmber,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: warmAmber.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: Color(0xFF0F172A),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Post Job',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
        const SizedBox(height: 20),

        // 2. Segmented Pill Switch: Active (X) vs Closed (Y)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Active Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _jobFilter = 'active');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _jobFilter == 'active' ? warmAmber : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _jobFilter == 'active'
                          ? [
                              BoxShadow(
                                color: warmAmber.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Active ($activeCount)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _jobFilter == 'active' ? FontWeight.w700 : FontWeight.w600,
                        color: _jobFilter == 'active' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Closed Tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _jobFilter = 'closed');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _jobFilter == 'closed' ? warmAmber : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _jobFilter == 'closed'
                          ? [
                              BoxShadow(
                                color: warmAmber.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Closed ($closedCount)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _jobFilter == 'closed' ? FontWeight.w700 : FontWeight.w600,
                        color: _jobFilter == 'closed' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. Job Openings Cards List
        if (displayJobs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business_center_outlined, color: warmAmber, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  _jobFilter == 'active' ? 'No Active Job Openings' : 'No Closed Job Openings',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Post a job requirement to start receiving candidate applications.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _openNewJob,
                  icon: const Icon(Icons.add, size: 20, color: Color(0xFF0F172A)),
                  label: const Text(
                    'Post Job Requirement',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warmAmber,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayJobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              return _buildJobCard(context, displayJobs[index]);
            },
          ),
      ],
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    const warmAmber = Color(0xFFF5A623);
    final isClosed = _isJobClosed(job);
    final title = (job['title'] ?? 'Senior Civil Engineer').toString();
    final location = (job['location'] ?? 'Mumbai, Maharashtra').toString();
    final salary = _formatSalary(job);
    final jobType = (job['type'] ?? job['employmentType'] ?? 'Full-time').toString();
    final exp = (job['experience'] ?? job['experienceRequired'] ?? '5-8 years').toString();
    final posted = _formatTimeAgo(job['createdAt']);

    final jobApps = _getApplicationsForJob(job);
    final totalApplicants = jobApps.length;
    final appliedCount = _countStatus(jobApps, 'applied');
    final shortlistedCount = _countStatus(jobApps, 'shortlisted');
    final hiredCount = _countStatus(jobApps, 'hired');
    final rejectedCount = _countStatus(jobApps, 'rejected');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section: Title with pencil edit icon + Status Badge
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 18, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Edit pencil icon
                      GestureDetector(
                        onTap: () => _openEditJob(job),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 19,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Active / Closed Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isClosed ? const Color(0xFFF3F4F6) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isClosed ? 'Closed' : 'Active',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isClosed ? const Color(0xFF6B7280) : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Location Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: Color(0xFF4B5563),
                ),
                const SizedBox(width: 6),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),

          // Details Row: Salary • Full-time • 5-8 years
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                Text(
                  salary,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669), // Green salary text
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('•', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                ),
                Text(
                  jobType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('•', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16)),
                ),
                Text(
                  exp,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),

          // Posted Time
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
            child: Text(
              posted,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),

          // Divider
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),

          // Total Applicants Row
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 14, bottom: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  size: 22,
                  color: Color(0xFF1E293B),
                ),
                const SizedBox(width: 8),
                Text(
                  '$totalApplicants Total Applicants',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          // 4 Status Metric Boxes (Applied, Shortlisted, Hired, Rejected)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                // 1. Applied (Light Blue)
                Expanded(
                  child: _buildMetricBox(
                    icon: Icons.access_time_rounded,
                    iconColor: const Color(0xFF2563EB),
                    count: appliedCount,
                    countColor: const Color(0xFF1D4ED8),
                    label: 'Applied',
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Shortlisted (Light Yellow)
                Expanded(
                  child: _buildMetricBox(
                    icon: Icons.visibility_outlined,
                    iconColor: const Color(0xFFD97706),
                    count: shortlistedCount,
                    countColor: const Color(0xFFB45309),
                    label: 'Shortlisted',
                    bgColor: const Color(0xFFFEFCE8),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Hired (Light Green)
                Expanded(
                  child: _buildMetricBox(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF16A34A),
                    count: hiredCount,
                    countColor: const Color(0xFF15803D),
                    label: 'Hired',
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                ),
                const SizedBox(width: 8),

                // 4. Rejected (Light Red)
                Expanded(
                  child: _buildMetricBox(
                    icon: Icons.cancel_outlined,
                    iconColor: const Color(0xFFDC2626),
                    count: rejectedCount,
                    countColor: const Color(0xFFB91C1C),
                    label: 'Rejected',
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Buttons Row: [ Manage Applicants ] & [ Edit Job ]
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 18),
            child: Row(
              children: [
                // Primary Yellow "Manage Applicants" button
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedJobId = (job['id'] ?? job['_id'] ?? job['jobId'])?.toString();
                        _selectedJob = job;
                        _candidateStatusFilter = 'all';
                        _searchController.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: warmAmber,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Manage Applicants',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Outlined "Edit Job" button
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () => _openEditJob(job),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Edit Job',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required Color iconColor,
    required int count,
    required Color countColor,
    required String label,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: countColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 2: Candidate View / Inside Job Card (Exact Replica of Image 3 & 4)
  // =========================================================================
  Widget _buildManageApplicantsView(BuildContext context, Map<String, dynamic> job) {
    final title = (job['title'] ?? 'Senior Civil Engineer').toString();
    final location = (job['location'] ?? 'Mumbai, Maharashtra').toString();

    final allJobApps = _getApplicationsForJob(job);
    final appliedCount = _countStatus(allJobApps, 'applied');
    final shortlistedCount = _countStatus(allJobApps, 'shortlisted');
    final hiredCount = _countStatus(allJobApps, 'hired');
    final rejectedCount = _countStatus(allJobApps, 'rejected');

    // Filter by candidate status
    List<Map<String, dynamic>> filtered = allJobApps;
    if (_candidateStatusFilter != 'all') {
      filtered = filtered.where((a) {
        final s = (a['status'] ?? 'pending').toString().toLowerCase().trim();
        switch (_candidateStatusFilter) {
          case 'applied':
            return s == 'pending' || s == 'applied';
          case 'shortlisted':
            return s == 'shortlisted';
          case 'hired':
            return s == 'accepted' || s == 'hired';
          case 'rejected':
            return s == 'rejected';
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        final name = _getUserName(a).toLowerCase();
        final company = _getCandidateCompany(a).toLowerCase();
        final email = _getCandidateEmail(a).toLowerCase();
        final phone = _getCandidatePhone(a).toLowerCase();
        return name.contains(_searchQuery) ||
            company.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            phone.contains(_searchQuery);
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Section: Title with pencil icon & Red Close Button (Image 3)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _openEditJob(job),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Red Close Button: [ ✕ Close ]
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedJobId = null;
                  _selectedJob = null;
                });
              },
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              label: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626), // Vibrant red
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Search applicants textfield
        TextField(
          controller: _searchController,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            hintText: 'Search applicants...',
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 15,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFF5A623), width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Filter Metric Cards Row (Applied, Shortlisted, Hired, Rejected) (Image 3)
        Row(
          children: [
            Expanded(
              child: _buildCandidateFilterCard(
                category: 'applied',
                count: appliedCount,
                countColor: const Color(0xFF2563EB),
                label: 'Applied',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCandidateFilterCard(
                category: 'shortlisted',
                count: shortlistedCount,
                countColor: const Color(0xFFD97706),
                label: 'Shortlisted',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCandidateFilterCard(
                category: 'hired',
                count: hiredCount,
                countColor: const Color(0xFF16A34A),
                label: 'Hired',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCandidateFilterCard(
                category: 'rejected',
                count: rejectedCount,
                countColor: const Color(0xFFDC2626),
                label: 'Rejected',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4. Candidate Cards List (Image 3 & Image 4)
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Icon(Icons.person_search_outlined, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No applicants matching "$_searchQuery"'
                      : (_candidateStatusFilter != 'all'
                          ? 'No ${_candidateStatusFilter.toUpperCase()} Applicants'
                          : 'No Applicants Found'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Applicants for this role will appear here with full contact info & credentials.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return CompanyCandidateCard(
                app: filtered[index],
                job: job,
                onUpdateStatus: widget.onUpdateStatus,
              );
            },
          ),
      ],
    );
  }

  Widget _buildCandidateFilterCard({
    required String category,
    required int count,
    required Color countColor,
    required String label,
  }) {
    final isSelected = _candidateStatusFilter == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_candidateStatusFilter == category) {
            _candidateStatusFilter = 'all';
          } else {
            _candidateStatusFilter = category;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? countColor : const Color(0xFFE5E7EB),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? countColor.withOpacity(0.12) : Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: countColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(
    BuildContext context,
    Map<String, dynamic> app,
    Map<String, dynamic> job,
  ) {
    final appId = (app['id'] ?? app['_id'])?.toString() ?? '';
    final name = _getUserName(app);
    final initials = _getInitials(name);
    final company = _getCandidateCompany(app);
    final appliedTime = _formatTimeAgo(app['createdAt']).replaceFirst('Posted', 'Applied');
    final email = _getCandidateEmail(app);
    final phone = _getCandidatePhone(app);
    final loc = _getCandidateLocation(app, job);
    final exp = _getCandidateExperience(app);

    final rawStatus = (app['status'] ?? 'pending').toString().toLowerCase().trim();
    final isShortlisted = rawStatus == 'shortlisted';
    final isHired = rawStatus == 'accepted' || rawStatus == 'hired';
    final isRejected = rawStatus == 'rejected';

    // Status rules:
    // 1. Shortlist -> disable Shortlist
    // 2. Hire -> disable Shortlist & Reject
    // 3. Reject -> disable all
    final bool canShortlist = !isShortlisted && !isHired && !isRejected;
    final bool canHire = !isHired && !isRejected;
    final bool canReject = !isHired && !isRejected;

    String displayStatus = 'Applied';
    Color statusBg = const Color(0xFFEFF6FF);
    Color statusFg = const Color(0xFF2563EB);

    if (isShortlisted) {
      displayStatus = 'Shortlisted';
      statusBg = const Color(0xFFFEF9C3);
      statusFg = const Color(0xFFB45309);
    } else if (isHired) {
      displayStatus = 'Hired';
      statusBg = const Color(0xFFDCFCE7);
      statusFg = const Color(0xFF15803D);
    } else if (isRejected) {
      displayStatus = 'Rejected';
      statusBg = const Color(0xFFFEE2E2);
      statusFg = const Color(0xFFB91C1C);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Row: Avatar with Initials + Name/Company/Time + Status Badge (Image 3 & 4)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle Avatar with Initials
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE), // Light blue circle
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8), // Deep blue initials
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Candidate Name, Company, Applied Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appliedTime,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge Pill on Right
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Contact & Profile Info Rows (Mail, Phone, Location, Experience)
          if (email.isNotEmpty) ...[
            _buildInfoRow(Icons.mail_outline_rounded, email, null),
            const SizedBox(height: 6),
          ],
          if (phone.isNotEmpty) ...[
            _buildInfoRow(Icons.phone_outlined, phone, () => _callPhone(phone)),
            const SizedBox(height: 6),
          ],
          _buildInfoRow(Icons.location_on_outlined, loc, null),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.business_center_outlined, exp, null),
          const SizedBox(height: 16),

          // 3. Full-width "View Resume" button (Image 4)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _viewResume(app),
              icon: const Icon(
                Icons.description_outlined,
                size: 20,
                color: Color(0xFF0F172A),
              ),
              label: const Text(
                'View Resume',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Action Buttons Row: [ Shortlist ] [ Hire ] [ Reject ] (Image 4)
          Row(
            children: [
              // Shortlist (Amber)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canShortlist
                      ? () {
                          widget.onUpdateStatus(appId, 'shortlisted', app: app);
                        }
                      : null,
                  icon: Icon(
                    isShortlisted ? Icons.check_circle_outline_rounded : Icons.visibility_outlined,
                    size: 16,
                    color: canShortlist
                        ? Colors.white
                        : (isShortlisted ? const Color(0xFFB45309) : const Color(0xFF94A3B8)),
                  ),
                  label: Text(
                    isShortlisted ? 'Shortlisted' : 'Shortlist',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: canShortlist
                          ? Colors.white
                          : (isShortlisted ? const Color(0xFFB45309) : const Color(0xFF94A3B8)),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canShortlist
                        ? const Color(0xFFD97706) // Golden Amber
                        : (isShortlisted ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                    disabledBackgroundColor:
                        isShortlisted ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Hire (Green)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canHire
                      ? () {
                          widget.onUpdateStatus(appId, 'accepted', app: app);
                        }
                      : null,
                  icon: Icon(
                    isHired ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: canHire
                        ? Colors.white
                        : (isHired ? const Color(0xFF15803D) : const Color(0xFF94A3B8)),
                  ),
                  label: Text(
                    isHired ? 'Hired' : 'Hire',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: canHire
                          ? Colors.white
                          : (isHired ? const Color(0xFF15803D) : const Color(0xFF94A3B8)),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canHire
                        ? const Color(0xFF059669) // Emerald Green
                        : (isHired ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
                    disabledBackgroundColor:
                        isHired ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Reject (Red)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canReject
                      ? () {
                          widget.onUpdateStatus(appId, 'rejected', app: app);
                        }
                      : null,
                  icon: Icon(
                    isRejected ? Icons.cancel_rounded : Icons.cancel_outlined,
                    size: 16,
                    color: canReject
                        ? Colors.white
                        : (isRejected ? const Color(0xFFB91C1C) : const Color(0xFF94A3B8)),
                  ),
                  label: Text(
                    isRejected ? 'Rejected' : 'Reject',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: canReject
                          ? Colors.white
                          : (isRejected ? const Color(0xFFB91C1C) : const Color(0xFF94A3B8)),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canReject
                        ? const Color(0xFFDC2626) // Vibrant Red
                        : (isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9)),
                    disabledBackgroundColor:
                        isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF4B5563),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: onTap != null ? const Color(0xFF1E293B) : const Color(0xFF334155),
                decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
                decorationColor: const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias so existing usages compile without breaking
typedef CompanyApplicationsView = CompanyHiringView;

