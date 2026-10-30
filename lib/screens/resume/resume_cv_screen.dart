import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/pdf_resume_generator.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/resume/resume_storage_service.dart';
import '../profile/skills_education_screen.dart';
import '../profile/widgets/edit_profile_sheet.dart';
import 'create_resume_screen.dart';

class ResumeCvScreen extends StatefulWidget {
  const ResumeCvScreen({super.key});

  @override
  State<ResumeCvScreen> createState() => _ResumeCvScreenState();
}

class _ResumeCvScreenState extends State<ResumeCvScreen> {
  List<ResumeModel> _resumes = [];
  bool _isLoadingResumes = true;
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    _loadResumes();
    context.read<ProfileCubit>().load();
    context.read<DocumentsCubit>().load(silent: true);
  }

  Future<void> _loadResumes() async {
    setState(() => _isLoadingResumes = true);

    final list = await ResumeStorageService.loadResumes();

    if (mounted) {
      setState(() {
        _resumes = list;
        _isLoadingResumes = false;
      });
    }
  }

  Future<void> _pickAndUploadResume({String? replaceResumeId}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
        withData: true,
      );

      final file = result?.files.single;
      if (file == null || !mounted) return;

      if (file.size > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File size exceeds 5MB limit. Please select a smaller file.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isUploadingFile = true);

      // Save a local copy of original bytes immediately to device storage
      String? savedLocalPath;
      try {
        final dir = await getApplicationDocumentsDirectory();
        final resumesDir = Directory('${dir.path}/resumes');
        if (!await resumesDir.exists()) {
          await resumesDir.create(recursive: true);
        }
        final safeName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
        final savedFile = File('${resumesDir.path}/$safeName');
        if (file.bytes != null) {
          await savedFile.writeAsBytes(file.bytes!, flush: true);
          savedLocalPath = savedFile.path;
        } else if (file.path != null && File(file.path!).existsSync()) {
          await File(file.path!).copy(savedFile.path);
          savedLocalPath = savedFile.path;
        }
      } catch (_) {
        savedLocalPath = file.path;
      }

      List<int>? uploadBytes = file.bytes;
      if (uploadBytes == null && file.path != null) {
        final f = File(file.path!);
        if (await f.exists()) {
          uploadBytes = await f.readAsBytes();
        }
      }

      DocumentModel? doc;
      if (uploadBytes != null) {
        try {
          doc = await context.read<DocumentsCubit>().upload(
            bytes: uploadBytes,
            filename: file.name,
            type: 'resume',
          );
        } catch (_) {}
      }

      if (mounted) {
        setState(() => _isUploadingFile = false);

        final profileState = context.read<ProfileCubit>().state;
        String userName = '';
        String userPhone = '';
        if (profileState is Loaded<WorkerProfile>) {
          userName = profileState.data.name;
          userPhone = profileState.data.phone;
        }

        final uploadedResume = ResumeModel(
          id: replaceResumeId ?? (doc?.id.isNotEmpty == true ? doc!.id : DateTime.now().millisecondsSinceEpoch.toString()),
          title: file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
          updatedAt: DateTime.now(),
          usedApplicationsCount: 0,
          fileUrl: doc?.fileUrl,
          localPath: savedLocalPath,
          isUploadedFile: true,
          fullName: userName.isNotEmpty ? userName : file.name,
          phone: userPhone,
        );

        await ResumeStorageService.addOrUpdateResume(uploadedResume);
        await _loadResumes();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(replaceResumeId != null
                ? 'Resume replaced successfully!'
                : 'Resume uploaded successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToCreate({ResumeModel? resume}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateResumeScreen(initialResume: resume),
      ),
    );
    if (result == true) {
      _loadResumes();
    }
  }

  void _navigateToSkillsEducation(WorkerProfile? profile) {
    if (profile == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkillsEducationScreen(initialProfile: profile),
      ),
    ).then((_) {
      if (mounted) {
        context.read<ProfileCubit>().load();
      }
    });
  }

  Future<void> _deleteResume(ResumeModel resume) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Delete Resume',
      message: 'Are you sure you want to delete "${resume.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
    );

    if (confirm) {
      await ResumeStorageService.deleteResume(resume.id);
      await _loadResumes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume deleted.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  /// Downloads or opens the resume:
  /// - Uploaded resumes: opens/shares the exact original file untouched (NO template regeneration).
  /// - Created resumes: compiles standard PDF using PdfResumeGenerator.
  Future<void> _downloadOrOpenResume(ResumeModel resume) async {
    // 1. If it's an uploaded file: NEVER alter or regenerate content!
    if (resume.isUploaded) {
      // Check if original file exists on local device
      if (resume.localPath != null && resume.localPath!.isNotEmpty) {
        final localFile = File(resume.localPath!);
        if (await localFile.exists()) {
          final ext = resume.localPath!.split('.').last.toLowerCase();
          final mimeType = ext == 'pdf'
              ? 'application/pdf'
              : (ext == 'doc' || ext == 'docx')
                  ? 'application/msword'
                  : null;
          await Share.shareXFiles(
            [XFile(localFile.path, mimeType: mimeType)],
            subject: resume.title,
            text: 'Original uploaded resume: ${resume.title}',
          );
          return;
        }
      }

      // If local file not present, download from remote URL
      if (resume.fileUrl != null && resume.fileUrl!.isNotEmpty) {
        final url = resume.fileUrl!;
        if (url.startsWith('http://') || url.startsWith('https://')) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening original uploaded resume...'),
                duration: Duration(milliseconds: 1200),
                backgroundColor: AppColors.primary,
              ),
            );

            final dio = ApiClient.instance.dio;
            final response = await dio.get<List<int>>(
              url,
              options: Options(
                responseType: ResponseType.bytes,
                sendTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

            if (response.data != null && response.data!.isNotEmpty) {
              final tempDir = await getTemporaryDirectory();
              final ext = url.split('.').last.split('?').first.toLowerCase();
              final safeExt = (ext == 'pdf' || ext == 'doc' || ext == 'docx') ? ext : 'pdf';
              final safeName = resume.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
              final tempFile = File('${tempDir.path}/$safeName.$safeExt');
              await tempFile.writeAsBytes(response.data!, flush: true);

              await Share.shareXFiles(
                [XFile(tempFile.path)],
                subject: resume.title,
                text: 'Original uploaded resume: ${resume.title}',
              );
              return;
            }
          } catch (_) {}

          final uri = Uri.tryParse(url);
          if (uri != null) {
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              return;
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploaded file not found locally. Please re-upload your resume.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // 2. Form Builder resumes: Download official PDF from backend (with offline compiler fallback)
    try {
      if (resume.fileUrl != null && resume.fileUrl!.isNotEmpty && resume.fileUrl!.contains('/resumes/')) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Downloading official PDF resume from server...'),
              duration: Duration(milliseconds: 1200),
              backgroundColor: AppColors.primary,
            ),
          );

          final dio = ApiClient.instance.dio;
          final response = await dio.get<List<int>>(
            resume.fileUrl!,
            options: Options(
              responseType: ResponseType.bytes,
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

          if (response.data != null && response.data!.isNotEmpty) {
            final tempDir = await getTemporaryDirectory();
            final safeName = resume.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
            final tempFile = File('${tempDir.path}/$safeName.pdf');
            await tempFile.writeAsBytes(response.data!, flush: true);

            await Share.shareXFiles(
              [XFile(tempFile.path, mimeType: 'application/pdf')],
              subject: '${resume.title}.pdf',
              text: 'Official Resume for ${resume.fullName}',
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Official PDF ready: ${resume.title}.pdf'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
            return;
          }
        } catch (_) {}
      }

      // Offline / immediate compiler
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compiling PDF resume...'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: AppColors.primary,
        ),
      );

      final pdfFile = await PdfResumeGenerator.generatePdf(resume);

      if (await pdfFile.exists()) {
        await Share.shareXFiles(
          [XFile(pdfFile.path, mimeType: 'application/pdf')],
          subject: '${resume.title}.pdf',
          text: 'Resume for ${resume.fullName}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF ready: ${resume.title}.pdf'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final isVeryCompact = screenWidth < 340;

    return BlocBuilder<ProfileCubit, LoadState<WorkerProfile>>(
      builder: (context, profileState) {
        final profile = profileState is Loaded<WorkerProfile> ? profileState.data : null;
        final experiences = (profile?.experience ?? [])
            .where((e) => e.role.trim().isNotEmpty || e.company.trim().isNotEmpty)
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await context.read<ProfileCubit>().load();
              await _loadResumes();
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 12 : 16,
                    16,
                    isCompact ? 12 : 16,
                    80,
                  ),
                  children: [
                    // Top Header
                    Text(
                      'Resume & CV',
                      style: TextStyle(
                        fontSize: isCompact ? 22 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your resumes and professional profile',
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Dashed Upload Box
                    _buildUploadBox(context),
                    const SizedBox(height: 24),

                    // "My Resumes" Section Header with [ + Create New ] button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'My Resumes',
                            style: TextStyle(
                              fontSize: isCompact ? 18 : 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToCreate(),
                          icon: const Icon(Icons.add, size: 17, color: Colors.white),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Create New',
                              style: TextStyle(
                                fontSize: isCompact ? 12.5 : 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 12 : 16,
                              vertical: isCompact ? 8 : 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Resume Cards List (Real data only, no dummy data)
                    if (_isLoadingResumes)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    else if (_resumes.isEmpty)
                      _buildEmptyState()
                    else
                      ..._resumes.map((resume) => _buildResumeCard(resume, context)),

                    const SizedBox(height: 24),

                    // Work Experience Section Header (Real data from profile)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Work Experience',
                            style: TextStyle(
                              fontSize: isCompact ? 18 : 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            if (profile != null) {
                              EditProfileSheet.show(
                                context,
                                profile: profile,
                                onSave: (data) => context.read<ProfileCubit>().update(data),
                              );
                            } else {
                              _navigateToCreate();
                            }
                          },
                          icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                          label: const Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Work Experience Cards (Real user experience only)
                    if (experiences.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            Icon(Icons.work_outline_rounded, size: 36, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text(
                              'No work experience added yet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap "+ Add" above to add your employment history.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ...experiences.map((exp) {
                        final roleText = exp.role.isNotEmpty ? exp.role : 'Work Experience';
                        final compText = (exp.company.isNotEmpty && exp.company != 'XYZ Constructions')
                            ? exp.company
                            : '';
                        final durationText = exp.startDate != null && exp.startDate!.isNotEmpty
                            ? '${exp.startDate} - ${exp.endDate?.isNotEmpty == true ? exp.endDate : (exp.isCurrentlyWorking ? "Present" : "")}'
                            : (exp.years > 0 ? '${exp.years} ${exp.years == 1 ? "Year" : "Years"} Exp' : '');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildExperienceCard(
                            title: roleText,
                            company: compText,
                            duration: durationText,
                            onEdit: () {
                              if (profile != null) {
                                EditProfileSheet.show(
                                  context,
                                  profile: profile,
                                  onSave: (data) => context.read<ProfileCubit>().update(data),
                                );
                              } else {
                                _navigateToCreate();
                              }
                            },
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 20),

                    // Bottom Quick Action Cards: Skills & Education (Responsive wrap for small devices)
                    if (isVeryCompact) ...[
                      _buildShortcutCard(
                        icon: Icons.layers_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'Skills',
                        subtitle: profile != null && profile.skills.isNotEmpty
                            ? '${profile.skills.length} skills added'
                            : 'View & add skills',
                        onTap: () => _navigateToSkillsEducation(profile),
                      ),
                      const SizedBox(height: 10),
                      _buildShortcutCard(
                        icon: Icons.school_rounded,
                        iconColor: const Color(0xFF6366F1),
                        title: 'Education',
                        subtitle: profile != null && profile.parsedEducation.isNotEmpty
                            ? '${profile.parsedEducation.length} records added'
                            : (profile != null && profile.education.isNotEmpty
                                ? '${profile.education.length} records added'
                                : 'View & add education'),
                        onTap: () => _navigateToSkillsEducation(profile),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildShortcutCard(
                              icon: Icons.layers_rounded,
                              iconColor: const Color(0xFF10B981),
                              title: 'Skills',
                              subtitle: profile != null && profile.skills.isNotEmpty
                                  ? '${profile.skills.length} skills added'
                                  : 'View & add skills',
                              onTap: () => _navigateToSkillsEducation(profile),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildShortcutCard(
                              icon: Icons.school_rounded,
                              iconColor: const Color(0xFF6366F1),
                              title: 'Education',
                              subtitle: profile != null && profile.parsedEducation.isNotEmpty
                                  ? '${profile.parsedEducation.length} records added'
                                  : (profile != null && profile.education.isNotEmpty
                                      ? '${profile.education.length} records added'
                                      : 'View & add education'),
                              onTap: () => _navigateToSkillsEducation(profile),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Sub-widgets ────────────────────────────────────────────────────────

  Widget _buildUploadBox(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;

    return GestureDetector(
      onTap: _isUploadingFile ? null : _pickAndUploadResume,
      child: Container(
        constraints: BoxConstraints(minHeight: isCompact ? 125 : 145),
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 16 : 20,
          horizontal: isCompact ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: _isUploadingFile
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'Uploading resume...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: isCompact ? 32 : 38,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload New Resume',
                    style: TextStyle(
                      fontSize: isCompact ? 15 : 16.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'PDF, DOC up to 5MB',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResumeCard(ResumeModel resume, BuildContext context) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final updatedText =
        'Last updated: ${months[resume.updatedAt.month - 1]} ${resume.updatedAt.day}, ${resume.updatedAt.year}';
    final isUploaded = resume.isUploaded;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 370;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  resume.title,
                  style: TextStyle(
                    fontSize: isCompact ? 15.5 : 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isUploaded) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_rounded, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Uploaded File',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            updatedText,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 280;

              if (isVeryNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _downloadOrOpenResume(resume),
                            icon: const Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Download',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 38,
                          width: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                            padding: EdgeInsets.zero,
                            onPressed: () => _deleteResume(resume),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isUploaded
                            ? () => _pickAndUploadResume(replaceResumeId: resume.id)
                            : () => _navigateToCreate(resume: resume),
                        icon: Icon(
                          isUploaded ? Icons.sync_rounded : Icons.edit_outlined,
                          size: 16,
                          color: const Color(0xFF0F172A),
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isUploaded ? 'Replace' : 'Edit',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadOrOpenResume(resume),
                      icon: const Icon(Icons.download_rounded, size: 17, color: AppColors.primary),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Download',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isUploaded
                          ? () => _pickAndUploadResume(replaceResumeId: resume.id)
                          : () => _navigateToCreate(resume: resume),
                      icon: Icon(
                        isUploaded ? Icons.sync_rounded : Icons.edit_outlined,
                        size: 17,
                        color: const Color(0xFF0F172A),
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isUploaded ? 'Replace' : 'Edit',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 40,
                    width: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 19, color: Color(0xFFEF4444)),
                      padding: EdgeInsets.zero,
                      onPressed: () => _deleteResume(resume),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard({
    required String title,
    required String company,
    required String duration,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (company.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    company,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (duration.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    duration,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0F172A)),
            onPressed: onEdit ?? () => _navigateToCreate(),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.description_outlined, size: 48, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'No resumes created yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap "+ Create New" or upload a PDF/DOC resume.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
