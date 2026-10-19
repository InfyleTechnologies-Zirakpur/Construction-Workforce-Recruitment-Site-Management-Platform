import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileDocumentsCard extends StatelessWidget {
  final List<Map<String, dynamic>> documents;
  final bool isUploadingDocument;
  final ValueChanged<String> onUploadDocument;

  const ProfileDocumentsCard({
    super.key,
    required this.documents,
    required this.isUploadingDocument,
    required this.onUploadDocument,
  });

  static String _subtypeOf(String t) {
    final v = t.trim().toLowerCase();
    if (v == 'aadhaar') return 'aadhaar';
    if (v.startsWith('experience')) return 'experience';
    if (v.startsWith('skill')) return 'skill';
    return v;
  }

  Map<String, dynamic>? _findDoc(String type) {
    final want = _subtypeOf(type);
    for (final d in documents) {
      if (_subtypeOf((d['type'] ?? '').toString()) == want) {
        return d;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final aadhaarDoc = _findDoc('aadhaar');
    final experienceDoc = _findDoc('experience_certificate');
    final skillDoc = _findDoc('skill_certificate');

    final int verifiedCount = [aadhaarDoc, experienceDoc, skillDoc]
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
                    'Verification Documents',
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
                  color: verifiedCount == 3
                      ? const Color(0xFFDCFCE7)
                      : AppColors.peachBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: verifiedCount == 3
                        ? const Color(0xFF86EFAC)
                        : AppColors.peachBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$verifiedCount/3 Uploaded',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: verifiedCount == 3
                        ? const Color(0xFF15803D)
                        : AppColors.peachText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload documents to verify your profile and increase hiring chances.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          _buildDocumentItem(
            title: 'Aadhaar Card',
            type: 'aadhaar',
            description: 'Identity & address verification',
            doc: aadhaarDoc,
          ),
          const Divider(height: 16, color: AppColors.border),
          _buildDocumentItem(
            title: 'Experience Certificate',
            type: 'experience_certificate',
            description: 'Work history & past site proof',
            doc: experienceDoc,
          ),
          const Divider(height: 16, color: AppColors.border),
          _buildDocumentItem(
            title: 'Skill Certificate',
            type: 'skill_certificate',
            description: 'Trade diploma or ITI certificate',
            doc: skillDoc,
          ),
          if (isUploadingDocument) ...[
            const SizedBox(height: 12),
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
                'Uploading document for verification...',
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
  }) {
    final bool isUploaded = doc != null;
    final uploadedName =
        doc?['name']?.toString() ?? doc?['originalFilename']?.toString();

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isUploaded
                ? const Color(0xFFDCFCE7)
                : AppColors.peachBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isUploaded ? Icons.verified_rounded : Icons.description_outlined,
            color: isUploaded ? const Color(0xFF16A34A) : AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isUploaded
                    ? (uploadedName != null && uploadedName.isNotEmpty
                        ? 'Uploaded: $uploadedName'
                        : 'Document verified ✓')
                    : description,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isUploaded
                      ? const Color(0xFF16A34A)
                      : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: isUploadingDocument ? null : () => onUploadDocument(type),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isUploaded ? AppColors.card : AppColors.peachBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUploaded ? AppColors.border : AppColors.peachBorder,
                width: 1,
              ),
            ),
            child: Text(
              isUploaded ? 'Replace' : 'Upload',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isUploaded ? AppColors.dark : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
