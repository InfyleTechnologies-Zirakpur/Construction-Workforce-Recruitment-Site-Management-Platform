import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/sheets/report_job_sheet.dart';
import '../../../features/bloc/worker_blocs.dart';
import '../../../features/jobs/apply_job_screen.dart';

class JobDetailsSheet extends StatefulWidget {
  final Job job;
  const JobDetailsSheet({super.key, required this.job});

  @override
  State<JobDetailsSheet> createState() => _JobDetailsSheetState();
}

class _JobDetailsSheetState extends State<JobDetailsSheet> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.job.saved;
  }

  void _toggleSave() {
    setState(() => _isSaved = !_isSaved);
    if (_isSaved) {
      context.read<JobsCubit>().save(widget.job.id);
    } else {
      context.read<JobsCubit>().unsave(widget.job.id);
    }
  }

  Future<void> _reportJob(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportJobSheet(
        jobTitle: widget.job.title,
        company: widget.job.company,
      ),
    );

    if (result != null && result.trim().isNotEmpty && context.mounted) {
      try {
        await context.read<JobsCubit>().report(jobId: widget.job.id, reason: result);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.dark,
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Thank you. Your report has been submitted.')),
                ],
              ),
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit report. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.dark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.business_rounded, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(job.company, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFFF2F4F7), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        _buildHighlightCol('₹${job.dailyPay}/day', 'Daily Wage', AppColors.primary),
                        Container(width: 1, height: 38, color: AppColors.border),
                        _buildHighlightCol(job.location.isNotEmpty ? job.location : 'Site', 'Location', AppColors.textMuted),
                        Container(width: 1, height: 38, color: AppColors.border),
                        _buildHighlightCol(job.projectType.isNotEmpty ? job.projectType : 'Full time', 'Job Type', AppColors.textMuted),
                      ],
                    ),
                  ),
                  if (job.skills.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Required Skills', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.skills.map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.peachBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.peachBorder, width: 0.8),
                        ),
                        child: Text(e, style: const TextStyle(color: AppColors.peachText, fontWeight: FontWeight.w600, fontSize: 12)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Job Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
                  const SizedBox(height: 8),
                  Text(
                    job.description.isNotEmpty ? job.description : 'No additional description provided for this job listing.',
                    style: const TextStyle(fontSize: 14, height: 1.55, color: Color(0xFF475467)),
                  ),
                  if (job.requirements.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Requirements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
                    const SizedBox(height: 10),
                    ...job.requirements.map((req) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(req, style: const TextStyle(fontSize: 14, color: Color(0xFF475467), height: 1.4))),
                        ],
                      ),
                    )),
                  ],
                  if (job.experienceLevel.isNotEmpty && job.experienceLevel != 'Any') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Experience: ${job.experienceLevel}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475467))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _reportJob(context),
                      icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.primary),
                      label: const Text('Report this job'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  InkWell(
                    onTap: _toggleSave,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isSaved ? AppColors.peachBackground : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _isSaved ? AppColors.peachBorder : AppColors.border, width: 1.2),
                      ),
                      child: Icon(
                        _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: _isSaved ? AppColors.primary : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: job.applied ? AppColors.border : AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: job.applied
                            ? null
                            : () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ApplyJobScreen(job: job)),
                                );
                              },
                        child: Text(
                          job.applied ? 'Already Applied' : 'Apply Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: job.applied ? AppColors.textMuted : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCol(String val, String lbl, Color barCol) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(lbl, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 5),
          Container(width: 22, height: 2.5, decoration: BoxDecoration(color: barCol, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}
