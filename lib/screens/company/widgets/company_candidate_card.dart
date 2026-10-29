import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'company_applicant_review_sheet.dart';

class CompanyCandidateCard extends StatelessWidget {
  final Map<String, dynamic> app;
  final Map<String, dynamic>? job;
  final void Function(String appId, String status, {String? remarks, Map<String, dynamic>? app}) onUpdateStatus;
  final bool isReadOnly;

  const CompanyCandidateCard({
    super.key,
    required this.app,
    this.job,
    required this.onUpdateStatus,
    this.isReadOnly = false,
  });

  String _getUserName(Map<String, dynamic> app) {
    final user = app['user'] is Map ? app['user'] as Map<String, dynamic> : <String, dynamic>{};
    return (user['fullName'] ?? user['name'] ?? app['workerName'] ?? 'Candidate').toString();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'NA';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
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

  String _formatTimeAgo(dynamic dateVal) {
    if (dateVal == null) return 'Posted recently';
    DateTime? dt;
    if (dateVal is DateTime) {
      dt = dateVal;
    } else {
      dt = DateTime.tryParse(dateVal.toString());
    }
    if (dt == null) return 'Posted recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return 'Posted $months ${months == 1 ? 'month' : 'months'} ago';
    } else if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return 'Posted $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (diff.inDays >= 1) {
      return 'Posted ${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    } else if (diff.inHours >= 1) {
      return 'Posted ${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return 'Posted recently';
    }
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

  Future<void> _viewResume(BuildContext context, Map<String, dynamic> app) async {
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

    if (context.mounted) {
      CompanyApplicantReviewSheet.show(
        context,
        app: app,
        onUpdateStatus: onUpdateStatus,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final bool canShortlist = !isShortlisted && !isHired && !isRejected && !isReadOnly;
    final bool canHire = !isHired && !isRejected && !isReadOnly;
    final bool canReject = !isHired && !isRejected && !isReadOnly;

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
          // 1. Top Row: Avatar with Initials + Name/Company/Time + Status Badge
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

          // 3. Full-width "View Resume" button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _viewResume(context, app),
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
          if (!isReadOnly) ...[
            const SizedBox(height: 12),

            // 4. Action Buttons Row: [ Shortlist ] [ Hire ] [ Reject ]
            Row(
              children: [
                // Shortlist (Amber)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canShortlist
                        ? () {
                            onUpdateStatus(appId, 'shortlisted', app: app);
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

           
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canHire
                        ? () {
                            onUpdateStatus(appId, 'accepted', app: app);
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
                            onUpdateStatus(appId, 'rejected', app: app);
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

