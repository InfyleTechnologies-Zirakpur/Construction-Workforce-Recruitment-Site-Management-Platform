import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CompleteProfileDocumentsStudio extends StatelessWidget {
  final List<Map<String, dynamic>> documentSpecs;
  final Map<String, String?> uploadedDocs;
  final String? uploadingDocType;
  final void Function(String type, String title) onPickDocument;

  const CompleteProfileDocumentsStudio({
    super.key,
    required this.documentSpecs,
    required this.uploadedDocs,
    required this.uploadingDocType,
    required this.onPickDocument,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: documentSpecs.asMap().entries.map((entry) {
        final idx = entry.key;
        final doc = entry.value;
        final type = (doc['type'] ?? '').toString();
        final title = (doc['title'] ?? '').toString();
        final subtitle = (doc['subtitle'] ?? '').toString();
        final badge = (doc['badge'] ?? '').toString();
        final icon = doc['icon'] as IconData? ?? Icons.description_outlined;
        final isKey = doc['isKey'] == true;

        final uploadedFilename = uploadedDocs[type];
        final isUploaded = uploadedFilename != null;
        final isUploadingThis = uploadingDocType == type;

        return Column(
          children: [
            if (idx > 0) const Divider(height: 18, color: Color(0xFFF1F5F9)),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isUploaded ? const Color(0xFFDCFCE7) : AppColors.peachBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isUploaded ? Icons.verified_rounded : icon,
                    color: isUploaded ? const Color(0xFF16A34A) : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isKey ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isKey ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isKey ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUploaded ? 'Uploaded: $uploadedFilename' : subtitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          fontWeight: isUploaded ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isUploadingThis)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  InkWell(
                    onTap: uploadingDocType != null ? null : () => onPickDocument(type, title),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: isUploaded ? Colors.white : AppColors.peachBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isUploaded ? const Color(0xFFCBD5E1) : AppColors.peachBorder,
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
            ),
          ],
        );
      }).toList(),
    );
  }
}
