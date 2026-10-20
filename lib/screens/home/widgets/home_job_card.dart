import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

class _TradeTheme {
  final Color bg;
  final Color fg;
  final IconData icon;

  const _TradeTheme({
    required this.bg,
    required this.fg,
    required this.icon,
  });
}

class HomeJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;
  final EdgeInsetsGeometry? margin;

  const HomeJobCard({
    super.key,
    required this.job,
    required this.onTap,
    required this.onSaveToggle,
    this.margin,
  });

  String _formatPay(int pay) {
    if (pay <= 0) return '0.00';
    return pay.toString();
  }

  String _formatWorkType(String type) {
    if (type.isEmpty) return 'Full time';
    final lower = type.toLowerCase();
    if (lower.contains('part')) return 'Part time';
    if (lower.contains('full')) return 'Full time';
    if (lower.contains('contract')) return 'Contract';
    return type;
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
    } else if (t.contains('helper') ||
        t.contains('labour') ||
        t.contains('loader') ||
        t.contains('worker') ||
        t.contains('hk')) {
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
    } else if (t.contains('construct') ||
        t.contains('mason') ||
        t.contains('civil') ||
        t.contains('site')) {
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

  @override
  Widget build(BuildContext context) {
    final payStr = _formatPay(job.dailyPay);
    final workTypeStr = _formatWorkType(job.projectType);
    final tradeTheme = _getTradeTheme(job.title);
    final dateText = _formatDate(job.createdAt);
    final headcount = job.workforceRequired;

    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Trade Icon Box + Title & Company/Location + Bookmark Action
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

                    // Title & (Company • Location)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (job.company.isNotEmpty) ...[
                                Flexible(
                                  child: Text(
                                    job.company,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Text('•', style: TextStyle(color: AppColors.textMuted)),
                                ),
                              ],
                              Icon(Icons.location_on_outlined, size: 14, color: tradeTheme.fg),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  job.location.isNotEmpty ? job.location : 'Site',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
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

                    // Bookmark Action with Job Seeker peach/yellow flow
                    InkWell(
                      onTap: onSaveToggle,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: job.saved ? AppColors.peachBackground : const Color(0xFFF9FAFB),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: job.saved ? AppColors.peachBorder : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          job.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: job.saved ? AppColors.primary : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 2: Daily Pay (Worker Amber/Gold Flow)
                Text(
                  '₹ $payStr / day',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.peachText,
                  ),
                ),
                const SizedBox(height: 10),

                // Row 3: Skills Chips (from API)
                if (job.skills.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: job.skills.map((s) => Container(
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
                        )).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Row 4: Bottom Metadata (Date / Work Type / Vacancies) + Action Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Metadata (Date, Headcount, Work Type)
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF344054),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (headcount != null && headcount > 0) ...[
                            const Icon(Icons.groups_outlined, size: 15, color: AppColors.dark),
                            const SizedBox(width: 4),
                            Text(
                              '$headcount Workers',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF344054),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ] else ...[
                            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.dark),
                            const SizedBox(width: 4),
                            Text(
                              workTypeStr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF344054),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Action Button (Apply Now / Applied)
                    if (job.applied)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 15, color: AppColors.success),
                            SizedBox(width: 5),
                            Text(
                              'Applied',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      InkWell(
                        onTap: onTap,
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
                              Icon(Icons.visibility_outlined, size: 15, color: AppColors.peachText),
                              SizedBox(width: 6),
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.peachText,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.peachText),
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
      ),
    );
  }
}
