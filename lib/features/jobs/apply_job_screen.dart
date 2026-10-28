import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/sheets/report_job_sheet.dart';
import '../../features/bloc/worker_blocs.dart';
import 'widgets/apply_job_documents_card.dart';
import 'widgets/apply_job_experience_card.dart';
import 'widgets/apply_job_header_card.dart';


class ApplyJobScreen extends StatefulWidget {
  const ApplyJobScreen({super.key, required this.job});
  final Job job;

  @override
  State<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends State<ApplyJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _yearsController = TextEditingController();
  final _trainingController = TextEditingController();
  final _summaryController = TextEditingController();

  bool _hasExperience = true;
  bool _isSubmitting = false;
  DocumentModel? _selectedResume;

  @override
  void initState() {
    super.initState();
    _hasExperience = widget.job.experienceLevel != 'Fresher';

    final profileState = context.read<ProfileCubit>().state;
    if (profileState is Loaded<WorkerProfile>) {
      final profile = profileState.data;
      final skillsText = profile.skills.isEmpty ? widget.job.skills.join(', ') : profile.skills.join(', ');
      _summaryController.text =
          'Skilled in $skillsText. Based in ${profile.city} and available to start immediately. '
          'Reliable, safety-conscious, and comfortable working as part of a site crew.';
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _yearsController.dispose();
    _trainingController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final profileState = context.read<ProfileCubit>().state;
      String? phone;
      if (profileState is Loaded<WorkerProfile>) {
        phone = profileState.data.phone;
      }
      final years = int.tryParse(_yearsController.text.trim());
      final company = _companyController.text.trim();
      final role = _roleController.text.trim();
      final training = _trainingController.text.trim();
      final baseNote = _summaryController.text.trim();

      final buffer = StringBuffer(baseNote);
      if (_hasExperience && (years != null || company.isNotEmpty || role.isNotEmpty)) {
        buffer.write('\n\n[Experience Details]');
        if (years != null && years > 0) buffer.write('\n• Years of Experience: $years');
        if (role.isNotEmpty) buffer.write('\n• Previous Role: $role');
        if (company.isNotEmpty) buffer.write('\n• Previous Company: $company');
      } else if (!_hasExperience && training.isNotEmpty) {
        buffer.write('\n\n[Training/Background]\n• $training');
      }
      if (phone != null && phone.isNotEmpty) {
        buffer.write('\n\n• Contact Phone: $phone');
      }
      if (_selectedResume != null) {
        buffer.write('\n\n[Resume Document]\n• File: ${_selectedResume!.displayName}');
        if (_selectedResume!.fileUrl != null && _selectedResume!.fileUrl!.isNotEmpty) {
          buffer.write('\n• URL: ${_selectedResume!.fileUrl}');
        }
      }

      final details = <String, dynamic>{
        'coverNote': buffer.toString().trim(),
        if (_selectedResume?.fileUrl != null && _selectedResume!.fileUrl!.isNotEmpty)
          'resumeUrl': _selectedResume!.fileUrl,
      };

      await context.read<JobsCubit>().apply(widget.job.id, details: details);

      NotificationService.instance.showLocalNotification(
        title: 'Application Submitted! 🎉',
        body: 'Your application for "${widget.job.title}" was submitted to ${widget.job.company}.',
        payload: '{"type": "application", "jobId": "${widget.job.id}"}',
      );

      if (!mounted) return;
      try {
        context.read<NotificationsCubit>().load();
      } catch (_) {}

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.dark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Application submitted to ${widget.job.company}')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String msg = 'Failed to submit application.';
      if (e is DioException) {
        msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
      } else {
        msg = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reportJob(BuildContext context, String jobId) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportJobSheet(
        jobTitle: widget.job.title,
        company: widget.job.company,
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      try {
        await context.read<JobsCubit>().report(jobId: jobId, reason: result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.dark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Thank you. Your report has been submitted.')),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          String msg = 'Failed to report job.';
          if (e is DioException) {
            msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Apply for Job',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Report Job',
            icon: const Icon(Icons.flag_outlined, size: 20, color: AppColors.primary),
            onPressed: () => _reportJob(context, job.id),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              ApplyJobHeaderCard(job: job),
              const SizedBox(height: 16),
              ApplyJobExperienceCard(
                hasExperience: _hasExperience,
                onExperienceChanged: (val) => setState(() => _hasExperience = val),
                companyController: _companyController,
                roleController: _roleController,
                yearsController: _yearsController,
                trainingController: _trainingController,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Profile Summary',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'A short cover note the employer sees with your application',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _summaryController,
                      maxLines: 4,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Please add a short summary' : null,
                      decoration: InputDecoration(
                        hintText: 'Tell the contractor why you are a good fit for this role...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ApplyJobDocumentsCard(
                onSelectResume: (doc) => setState(() => _selectedResume = doc),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Submit Application',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                            ],
                          ),
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
