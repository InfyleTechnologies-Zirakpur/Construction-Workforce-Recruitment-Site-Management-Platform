import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../features/bloc/worker_blocs.dart';

/// Documents section card for job application — shows profile documents
/// and allows the user to select/change their resume for this application.
class ApplyJobDocumentsCard extends StatefulWidget {
  final ValueChanged<DocumentModel?>? onSelectResume;

  const ApplyJobDocumentsCard({
    super.key,
    this.onSelectResume,
  });

  @override
  State<ApplyJobDocumentsCard> createState() => _ApplyJobDocumentsCardState();
}

class _ApplyJobDocumentsCardState extends State<ApplyJobDocumentsCard> {
  bool _isUploading = false;
  String? _selectedResumeId;
  DocumentModel? _uploadedResume;

  @override
  void initState() {
    super.initState();
    // Pre-seed from ProfileCubit if profile already exists
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is Loaded<WorkerProfile>) {
      context.read<DocumentsCubit>().seedFromProfile(profileState.data);
    }
    // Load documents when card appears
    context.read<DocumentsCubit>().load(silent: true);
  }

  Future<void> _uploadNewResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null || !mounted) return;

    setState(() => _isUploading = true);
    final doc = await context.read<DocumentsCubit>().upload(
      bytes: file!.bytes!,
      filename: file.name,
      type: 'resume',
    );
    if (!mounted) return;
    setState(() {
      _isUploading = false;
      if (doc != null) {
        _uploadedResume = doc;
        _selectedResumeId = doc.id;
        widget.onSelectResume?.call(doc);
      }
    });

    if (doc != null) {
      // Keep profile in sync
      try {
        context.read<ProfileCubit>().load();
      } catch (_) {}
    }

    if (doc != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.dark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Resume "${file.name}" attached successfully')),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _openResumeUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Widget _buildResumeSelector(List<DocumentModel> resumes) {
    final activeResume = resumes.firstOrNull;

    if (activeResume != null && _selectedResumeId != activeResume.id) {
      _selectedResumeId = activeResume.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSelectResume?.call(activeResume);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activeResume == null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 22, color: Color(0xFFDC2626)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No resume uploaded',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Upload your resume to stand out and improve your chance of getting hired',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: const Color(0xFFDC2626).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isUploading ? null : _uploadNewResume,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(
                _isUploading ? 'Uploading Resume...' : 'Upload Resume (PDF, DOC)',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ] else ...[
          // Resume is uploaded: Show resume details + Edit/Change option
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.peachBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  activeResume.displayName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                                ),
                                child: const Text(
                                  'Attached ✓',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            activeResume.uploadedAt != null
                                ? 'Uploaded ${_formatDate(activeResume.uploadedAt!)} • Will be submitted with application'
                                : (activeResume.createdAt != null
                                    ? 'Uploaded ${_formatDate(activeResume.createdAt!)} • Will be submitted with application'
                                    : 'Attached resume ready for submission'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Edit / Change Button
                    InkWell(
                      onTap: _isUploading ? null : _uploadNewResume,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isUploading)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            else
                              const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              _isUploading ? 'Updating...' : 'Change',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Preview Link row
                if (activeResume.fileUrl != null && activeResume.fileUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.peachBorder),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _openResumeUrl(activeResume.fileUrl),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_outlined, size: 15, color: AppColors.primary),
                              SizedBox(width: 5),
                              Text(
                                'Preview Resume',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _isUploading ? null : _uploadNewResume,
                        borderRadius: BorderRadius.circular(6),
                        child: const Text(
                          'Upload a different file',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _documentRow(Map<String, dynamic> doc) {
    final status = (doc['verificationStatus'] as String?) ?? 'pending';
    final isVerified = status == 'verified';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 18, color: AppColors.dark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              (doc['name'] as String?) ?? (doc['originalFilename'] as String?) ?? (doc['type'] as String?) ?? 'Document',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.dark),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isVerified ? AppColors.peachBackground : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isVerified ? AppColors.peachBorder : AppColors.border,
                width: 0.8,
              ),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(
                color: isVerified ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentsCubit, LoadState<List<DocumentModel>>>(
      builder: (context, docState) {
        final profileState = context.watch<ProfileCubit>().state;
        WorkerProfile? profile;
        if (profileState is Loaded<WorkerProfile>) {
          profile = profileState.data;
        }

        final documents = docState is Loaded<List<DocumentModel>>
            ? List<DocumentModel>.from(docState.data)
            : <DocumentModel>[];

        // 1. If documents has no resume, check ProfileCubit documents
        if (!documents.any((d) => d.isResume) && profile != null) {
          for (final pd in profile.documents) {
            final doc = DocumentModel.fromJson(pd);
            if (doc.isResume) {
              documents.insert(0, doc);
              break;
            }
          }
        }

        // 2. If still no resume, check profile.resumeUrl
        if (!documents.any((d) => d.isResume) &&
            profile != null &&
            profile.resumeUrl != null &&
            profile.resumeUrl!.isNotEmpty) {
          documents.insert(
            0,
            DocumentModel(
              id: 'profile_resume',
              type: 'resume',
              fileName: 'Resume.pdf',
              fileUrl: profile.resumeUrl,
              verificationStatus: 'verified',
            ),
          );
        }

        // 3. If user just uploaded a resume in this session, ensure it's included
        if (_uploadedResume != null) {
          if (!documents.any((d) => d.isResume)) {
            documents.insert(0, _uploadedResume!);
          } else {
            final idx = documents.indexWhere((d) => d.isResume);
            if (idx != -1 && documents[idx].id != _uploadedResume!.id) {
              documents[idx] = _uploadedResume!;
            }
          }
        }

        final resumes = documents.where((d) => d.isResume).toList();
        final certificates = documents.where((d) => !d.isResume).toList();
        final bool isLoading = docState is Loading<List<DocumentModel>> && resumes.isEmpty;

        return Container(
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
              // Resume Section
              const Row(
                children: [
                  Icon(Icons.description_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Resume',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Select or upload the resume you want to attach to this application',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              else
                _buildResumeSelector(resumes),

              // Certificates Section
              if (certificates.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.folder_shared_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Shared Certificates',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'These certificates from your profile will be visible to the employer',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                ...certificates.map((doc) => _documentRow(doc.toJson())),
              ],

              // Fallback: show profile documents if no DocumentsCubit docs
              if (documents.isEmpty && docState is! Loading<List<DocumentModel>>)
                BlocBuilder<ProfileCubit, LoadState<WorkerProfile>>(
                  builder: (context, profileState) {
                    final profileDocs = profileState is Loaded<WorkerProfile>
                        ? profileState.data.documents
                        : const <Map<String, dynamic>>[];

                    if (profileDocs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.folder_shared_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Profile Documents',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...profileDocs.map((doc) => _documentRow(doc)),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
