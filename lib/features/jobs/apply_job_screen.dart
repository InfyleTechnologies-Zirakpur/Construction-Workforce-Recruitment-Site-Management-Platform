import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/notification_service.dart';
import '../../features/bloc/worker_blocs.dart';

/// Full application flow for a single job: employer requirements up top,
/// then a form branching on whether the worker has prior experience or is
/// a fresher, a short profile summary, a read-only view of the documents
/// that will be shared, then submit.
///
/// NOTE: this currently calls `JobsCubit.apply(job.id)` unchanged, which
/// only flips `applied = true` server-side. The extra fields collected here
/// (previous company, years of experience, summary, etc.) aren't sent yet —
/// `WorkerRepository.apply` needs a `details` payload param wired through to
/// `POST /jobs/:id/applications` for that. Happy to wire it fully once
/// `worker_repository.dart` is available.
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

      final details = <String, dynamic>{
        'coverNote': buffer.toString().trim(),
      };

      await context.read<JobsCubit>().apply(widget.job.id, details: details);

      // Trigger immediate heads-up popup notification banner on device
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
        SnackBar(content: Text('Application submitted to ${widget.job.company}')),
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
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reportJob(BuildContext context, String jobId) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this job?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Fraudulent listing, incorrect pay...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      try {
        await context.read<JobsCubit>().report(jobId: jobId, reason: result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job reported successfully.')));
        }
      } catch (e) {
        if (context.mounted) {
          String msg = 'Failed to report job.';
          if (e is DioException) msg = e.response?.data?['message']?.toString() ?? e.message ?? msg;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final job = widget.job;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for job'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'report') {
                _reportJob(context, job.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Report job'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            children: [
              _employerNeedsCard(context, job, textTheme),
              const SizedBox(height: 20),
              Text('Your experience', style: textTheme.titleMedium),
              const SizedBox(height: 10),
              _experienceToggle(textTheme),
              const SizedBox(height: 16),
              if (_hasExperience) _experienceFields(textTheme) else _fresherFields(textTheme),
              const SizedBox(height: 20),
              Text('Profile summary', style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'A short note the employer sees with your application.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _summaryController,
                maxLines: 5,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please add a short summary' : null,
                decoration: const InputDecoration(
                  hintText: 'Tell the employer why you\'re a good fit for this role',
                ),
              ),
              const SizedBox(height: 20),
              _documentsSection(context, textTheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Application'),
          ),
        ),
      ),
    );
  }

  Widget _employerNeedsCard(BuildContext context, Job job, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.title, style: textTheme.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 2),
          Text(job.company, style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _needRow(Icons.location_on_outlined, job.location),
              _needRow(Icons.payments_outlined, '₹${job.dailyPay}/day'),
              _needRow(Icons.work_outline, job.projectType),
              _needRow(Icons.military_tech_outlined, job.experienceLevel == 'Any' ? 'Any experience level' : '${job.experienceLevel} preferred'),
            ],
          ),
          if (job.skills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: job.skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _needRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
      ],
    );
  }

  Widget _experienceToggle(TextTheme textTheme) {
    Widget option(String label, bool value) {
      final isSelected = _hasExperience == value;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _hasExperience = value),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option('I have experience', true),
        const SizedBox(width: 10),
        option("I'm a fresher", false),
      ],
    );
  }

  Widget _experienceFields(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _companyController,
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your previous company' : null,
          decoration: const InputDecoration(labelText: 'Previous company name'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _roleController,
          decoration: const InputDecoration(labelText: 'Your role / trade there', hintText: 'e.g. Site Electrician'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _yearsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Years of experience'),
        ),
      ],
    );
  }

  Widget _fresherFields(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "No previous experience needed — mention any training or certificates below.",
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _trainingController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Training / certifications (optional)',
            hintText: 'e.g. ITI Electrician certificate, 3-month site safety course',
          ),
        ),
      ],
    );
  }

  Widget _documentsSection(BuildContext context, TextTheme textTheme) {
    return BlocBuilder<ProfileCubit, LoadState<WorkerProfile>>(
      builder: (context, state) {
        final documents = state is Loaded<WorkerProfile> ? state.data.documents : const <Map<String, dynamic>>[];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_shared_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Documents shared with employer', style: textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 8),
              if (documents.isEmpty)
                Text(
                  "You haven't uploaded any documents yet. Add them from your profile for a stronger application.",
                  style: textTheme.bodySmall,
                )
              else
                ...documents.map((doc) => _documentRow(textTheme, doc)),
            ],
          ),
        );
      },
    );
  }

  Widget _documentRow(TextTheme textTheme, Map<String, dynamic> doc) {
    final status = (doc['verificationStatus'] as String?) ?? 'pending';
    final color = switch (status) {
      'verified' => Colors.green,
      'rejected' => AppColors.error,
      _ => Colors.orange,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 18, color: AppColors.dark),
          const SizedBox(width: 8),
          Expanded(child: Text((doc['name'] as String?) ?? (doc['type'] as String?) ?? 'Document', style: textTheme.bodyMedium)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
