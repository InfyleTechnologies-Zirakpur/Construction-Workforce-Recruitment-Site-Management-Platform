import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../features/bloc/worker_blocs.dart';
import '../../../features/resume/resume_storage_service.dart';

/// Documents section card for job application — allows the user to select
/// from their saved/uploaded resumes or upload a new one.
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
  List<ResumeModel> _savedResumes = [];
  bool _isLoadingSavedResumes = true;

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is Loaded<WorkerProfile>) {
      context.read<DocumentsCubit>().seedFromProfile(profileState.data);
    }
    context.read<DocumentsCubit>().load(silent: true);
    _loadSavedResumes();
  }

  Future<void> _loadSavedResumes() async {
    try {
      final list = await ResumeStorageService.loadResumes();
      if (mounted) {
        setState(() {
          _savedResumes = list;
          _isLoadingSavedResumes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSavedResumes = false);
    }
  }

  DocumentModel _resumeModelToDoc(ResumeModel r) {
    final title = r.title.isNotEmpty ? r.title : 'Resume';
    return DocumentModel(
      id: r.id,
      type: 'resume',
      fileName: title.toLowerCase().endsWith('.pdf') ? title : '$title.pdf',
      originalFilename: title,
      fileUrl: r.fileUrl,
      uploadedAt: r.updatedAt,
      createdAt: r.updatedAt,
      verificationStatus: 'verified',
    );
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
      try {
        context.read<ProfileCubit>().load();
      } catch (_) {}
      await _loadSavedResumes();
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

  void _showResumePickerSheet(BuildContext context, List<DocumentModel> resumes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Resume',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Text(
                  'Choose which resume to submit with this job application',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: resumes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = resumes[index];
                      final isSelected = item.id == _selectedResumeId;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedResumeId = item.id;
                          });
                          widget.onSelectResume?.call(item);
                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.dark,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              content: Text('Selected "${item.displayName}" for this application'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.peachBackground : const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.description_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.displayName,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: AppColors.dark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.uploadedAt != null
                                          ? 'Updated ${_formatDate(item.uploadedAt!)}'
                                          : (item.createdAt != null
                                              ? 'Updated ${_formatDate(item.createdAt!)}'
                                              : 'Ready to attach'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _uploadNewResume();
                  },
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text(
                    'Upload a Different Resume',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumeSelector(List<DocumentModel> resumes) {
    DocumentModel? activeResume;
    if (_selectedResumeId != null) {
      activeResume = resumes.where((r) => r.id == _selectedResumeId).firstOrNull;
    }
    activeResume ??= resumes.firstOrNull;

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
                        'Upload or select your resume to stand out to employers',
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
          // Resume is selected
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
                                  'Selected ✓',
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
                                ? 'Updated ${_formatDate(activeResume.uploadedAt!)} • Attached to this application'
                                : (activeResume.createdAt != null
                                    ? 'Updated ${_formatDate(activeResume.createdAt!)} • Attached to this application'
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

                    // Change / Choose Resume Button
                    InkWell(
                      onTap: resumes.length > 1
                          ? () => _showResumePickerSheet(context, resumes)
                          : (_isUploading ? null : _uploadNewResume),
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
                            Icon(
                              resumes.length > 1 ? Icons.swap_horiz_rounded : Icons.edit_outlined,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              resumes.length > 1 ? 'Choose' : 'Change',
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
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.peachBorder),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (activeResume.fileUrl != null && activeResume.fileUrl!.isNotEmpty)
                      InkWell(
                        onTap: () => _openResumeUrl(activeResume?.fileUrl),
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
                      )
                    else
                      const SizedBox.shrink(),
                    if (resumes.length > 1)
                      InkWell(
                        onTap: () => _showResumePickerSheet(context, resumes),
                        borderRadius: BorderRadius.circular(6),
                        child: Text(
                          '${resumes.length} resumes available • Tap to switch',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    else
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

        // 1. Merge saved resumes from ResumeStorageService (contains all uploaded and builder resumes)
        for (final r in _savedResumes) {
          final doc = _resumeModelToDoc(r);
          if (!documents.any((d) => d.id == doc.id || (doc.fileUrl != null && doc.fileUrl!.isNotEmpty && d.fileUrl == doc.fileUrl))) {
            documents.insert(0, doc);
          }
        }

        // 2. If documents has no resume, check ProfileCubit documents
        if (!documents.any((d) => d.isResume) && profile != null) {
          for (final pd in profile.documents) {
            final doc = DocumentModel.fromJson(pd);
            if (doc.isResume) {
              if (!documents.any((d) => d.id == doc.id)) {
                documents.insert(0, doc);
              }
              break;
            }
          }
        }

        // 3. If still no resume, check profile.resumeUrl
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

        // 4. If user just uploaded a resume in this session, ensure it's included
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
        final bool isLoading = (_isLoadingSavedResumes || docState is Loading<List<DocumentModel>>) && resumes.isEmpty;

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
                'Select which resume you want to attach to this job application',
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
              if (documents.isEmpty && docState is! Loading<List<DocumentModel>> && !_isLoadingSavedResumes)
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
