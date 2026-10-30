import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../../features/bloc/worker_blocs.dart';

/// Card displaying user's documents (Resume/CV, Skill Certificate, Experience Certificate, and others)
/// with full CRUD support: Upload, View/Download, Replace, and Delete.
class ProfileDocumentsCard extends StatefulWidget {
  final List<Map<String, dynamic>> documents;
  final bool isUploadingDocument;
  final ValueChanged<String> onUploadDocument;
  final VoidCallback? onRefresh;

  const ProfileDocumentsCard({
    super.key,
    required this.documents,
    required this.isUploadingDocument,
    required this.onUploadDocument,
    this.onRefresh,
  });

  @override
  State<ProfileDocumentsCard> createState() => _ProfileDocumentsCardState();
}

class _ProfileDocumentsCardState extends State<ProfileDocumentsCard> {
  String? _deletingDocId;

  static String _subtypeOf(String t, [Map<String, dynamic>? doc]) {
    final v = t.trim().toLowerCase();
    if (v == 'resume' || v == 'cv') return 'resume';
    if (doc != null) {
      final fn = (doc['fileName'] ?? doc['originalFilename'] ?? doc['name'] ?? '').toString().toLowerCase();
      final url = (doc['fileUrl'] ?? doc['url'] ?? '').toString().toLowerCase();
      if (fn.contains('resume') || fn.contains('cv') || url.contains('/resume/')) return 'resume';
    }
    if (v.startsWith('experience')) return 'experience';
    if (v.startsWith('skill')) return 'skill';
    return v;
  }

  Map<String, dynamic>? _findDoc(String type) {
    final want = _subtypeOf(type);
    for (final d in widget.documents) {
      if (_subtypeOf((d['type'] ?? '').toString(), d) == want) {
        return d;
      }
    }
    return null;
  }

  Future<void> _openDocumentUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Document URL is not available'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open document: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(String docId, String title) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Delete $title?',
      message: 'Are you sure you want to remove this document? This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
    );

    if (confirm != true || !mounted) return;

    setState(() => _deletingDocId = docId);
    try {
      final success = await context.read<DocumentsCubit>().delete(docId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title deleted successfully'),
              backgroundColor: AppColors.dark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          // Refresh profile and documents
          widget.onRefresh?.call();
          context.read<ProfileCubit>().load();
          context.read<DocumentsCubit>().load(silent: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete document'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _deletingDocId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    var resumeDoc = _findDoc('resume');
    if (resumeDoc == null) {
      final activeResume = context.watch<DocumentsCubit>().activeResume;
      if (activeResume != null) {
        resumeDoc = activeResume.toJson();
      }
    }
    final skillDoc = _findDoc('skill_certificate');
    final experienceDoc = _findDoc('experience_certificate');

    // Strict 3-document slots according to app flow:
    // 1. Single Resume/CV, 2. Skill Certificate, 3. Experience Certificate
    final int totalUploaded = [resumeDoc, skillDoc, experienceDoc]
        .where((d) => d != null)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.peachBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_shared_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Profile Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: totalUploaded > 0
                      ? const Color(0xFFDCFCE7)
                      : AppColors.peachBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: totalUploaded > 0
                        ? const Color(0xFF86EFAC)
                        : AppColors.peachBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$totalUploaded / 3 Uploaded',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: totalUploaded > 0
                        ? const Color(0xFF15803D)
                        : AppColors.peachText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep your single resume and trade certificates updated to stand out to employers and verify your profile.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // 1. Single Resume / CV Slot (Replace, View, Delete)
          _buildDocumentItem(
            title: 'Resume / CV',
            type: 'resume',
            description: 'PDF, DOC or DOCX format for job applications',
            doc: resumeDoc,
            icon: Icons.description_rounded,
            badgeLabel: 'Primary',
            badgeColor: const Color(0xFF3B82F6),
            isMandatory: false,
          ),

          const Divider(height: 20, color: AppColors.border),

          // 2. Skill Certificate (Mandatory)
          _buildDocumentItem(
            title: 'Skill Certificate',
            type: 'skill_certificate',
            description: 'Trade diploma, ITI certificate or license',
            doc: skillDoc,
            icon: Icons.workspace_premium_rounded,
            badgeLabel: 'Mandatory',
            badgeColor: const Color(0xFFDC2626),
            isMandatory: true,
          ),

          const Divider(height: 20, color: AppColors.border),

          // 3. Experience Certificate (Optional)
          _buildDocumentItem(
            title: 'Experience Certificate',
            type: 'experience_certificate',
            description: 'Work history & site proof (optional)',
            doc: experienceDoc,
            icon: Icons.badge_outlined,
            badgeLabel: 'Optional',
            badgeColor: AppColors.textSecondary,
            isMandatory: false,
          ),

          if (widget.isUploadingDocument) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.peachBackground,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Uploading document...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String type,
    required String description,
    required Map<String, dynamic>? doc,
    required IconData icon,
    required String badgeLabel,
    required Color badgeColor,
    bool isMandatory = false,
  }) {
    final bool isUploaded = doc != null;
    final docId = doc?['id']?.toString() ?? '';
    final uploadedName = doc?['originalFilename']?.toString() ??
        doc?['fileName']?.toString() ??
        doc?['name']?.toString();
    final fileUrl = doc?['fileUrl']?.toString() ??
        doc?['url']?.toString() ??
        doc?['path']?.toString();
    final isDeleting = _deletingDocId == docId && docId.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUploaded
                    ? const Color(0xFFDCFCE7)
                    : (isMandatory ? const Color(0xFFFEF2F2) : AppColors.peachBackground),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isUploaded ? Icons.verified_rounded : icon,
                color: isUploaded
                    ? const Color(0xFF16A34A)
                    : (isMandatory ? const Color(0xFFDC2626) : AppColors.primary),
                size: 22,
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
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isUploaded
                              ? const Color(0xFFDCFCE7)
                              : badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isUploaded
                                ? const Color(0xFF86EFAC)
                                : badgeColor.withValues(alpha: 0.3),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          isUploaded ? 'Verified ✓' : badgeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isUploaded ? const Color(0xFF15803D) : badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isUploaded
                        ? (uploadedName != null && uploadedName.isNotEmpty
                            ? uploadedName
                            : 'Document uploaded & verified')
                        : description,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isUploaded ? AppColors.dark : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Upload / Replace Button
            InkWell(
              onTap: widget.isUploadingDocument
                  ? null
                  : () => widget.onUploadDocument(type),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isUploaded ? AppColors.card : AppColors.peachBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isUploaded ? AppColors.border : AppColors.peachBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUploaded ? Icons.sync_rounded : Icons.file_upload_outlined,
                      size: 14,
                      color: isUploaded ? AppColors.dark : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUploaded ? 'Replace' : 'Upload',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isUploaded ? AppColors.dark : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // If uploaded, show actions row (View / Download, Delete)
        if (isUploaded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Row(
              children: [
                if (fileUrl != null && fileUrl.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _openDocumentUrl(fileUrl),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'View / Open',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                if (docId.isNotEmpty)
                  isDeleting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : InkWell(
                          onTap: () => _deleteDocument(docId, title),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.error),
                                SizedBox(width: 4),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
