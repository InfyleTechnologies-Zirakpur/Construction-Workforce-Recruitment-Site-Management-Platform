import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

class HomeJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;
  final VoidCallback? onApply;
  final EdgeInsetsGeometry? margin;

  const HomeJobCard({
    super.key,
    required this.job,
    required this.onTap,
    required this.onSaveToggle,
    this.onApply,
    this.margin,
  });

  String _formatSalary(Job job) {
    if (job.dailyPay <= 0) return 'Competitive Pay';
    // CTC / Annual package
    if (job.dailyPay >= 100000) {
      final lpa = (job.dailyPay / 100000);
      final upper = lpa + (lpa >= 5 ? 2 : 1.5);
      final lpaStr = lpa.toStringAsFixed(lpa.truncateToDouble() == lpa ? 0 : 1);
      final upperStr = upper.toStringAsFixed(upper.truncateToDouble() == upper ? 0 : 1);
      return '₹$lpaStr-$upperStr LPA';
    }
    // Monthly salary
    if (job.dailyPay >= 8000) {
      final minPay = job.dailyPay;
      final maxPay = (minPay * 1.33).round();
      final minStr = minPay.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      final maxStr = maxPay.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '₹$minStr-$maxStr/month';
    }
    // Daily wage
    return '₹${job.dailyPay}/day';
  }

  @override
  Widget build(BuildContext context) {
    final status = (job.applicationStatus ?? '').toLowerCase().trim();
    final isHired = status == 'hired' || status == 'accepted';
    final isRejected = status == 'rejected';
    final isApplied = job.applied || status == 'applied' || status == 'pending' || status == 'shortlisted';

    // Tags: Skills first, then experience / project type
    final tags = <String>[];
    for (final s in job.skills) {
      if (s.trim().isNotEmpty && !tags.contains(s.trim())) {
        tags.add(s.trim());
      }
      if (tags.length >= 3) break;
    }
    if (tags.length < 3 && job.experienceLevel.isNotEmpty && job.experienceLevel != 'Any') {
      tags.add(job.experienceLevel.contains('Year') ? job.experienceLevel : '${job.experienceLevel} Exp');
    }
    if (tags.length < 3 && job.projectType.isNotEmpty && job.projectType != 'Full-time') {
      tags.add(job.projectType);
    }
    if (tags.isEmpty) {
      tags.add('Full-time');
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title + Status Badge + Bookmark Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (isHired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Hired ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                  Icon(Icons.check_rounded, size: 14, color: Color(0xFF16A34A)),
                                ],
                              ),
                            )
                          else if (isRejected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Rejected',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            )
                          else if (isApplied)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Applied',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bookmark icon (Blue when saved, dark outlined when not)
                    GestureDetector(
                      onTap: onSaveToggle,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          job.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          size: 24,
                          color: job.saved ? AppColors.primary : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 2. Company Name
                Text(
                  job.company.isNotEmpty ? job.company : 'Verified Contractor',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.location.isNotEmpty ? job.location : 'Site Location',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // 4. Requirement / Skill Chips
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        )).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // 5. Bottom Salary & Action Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _formatSalary(job),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (isHired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Hired',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else if (isRejected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Rejected',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else if (isApplied)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF475569), // Dark slate grey as in screenshot
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Applied',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: onApply ?? onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A), // Black as in screenshot
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Apply Now',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
