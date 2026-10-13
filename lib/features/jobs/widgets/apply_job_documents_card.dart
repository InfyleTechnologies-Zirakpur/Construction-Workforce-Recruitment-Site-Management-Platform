import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../features/bloc/worker_blocs.dart';

/// Documents section card displaying profile attachments with verification badges.
class ApplyJobDocumentsCard extends StatelessWidget {
  const ApplyJobDocumentsCard({super.key});

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
              (doc['name'] as String?) ?? (doc['type'] as String?) ?? 'Document',
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, LoadState<WorkerProfile>>(
      builder: (context, state) {
        final documents = state is Loaded<WorkerProfile> ? state.data.documents : const <Map<String, dynamic>>[];

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
              const Row(
                children: [
                  Icon(Icons.folder_shared_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Shared Documents',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Documents attached automatically from your profile',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              if (documents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.textMuted),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No documents uploaded yet. Upload ID or certificates in your profile for higher selection rates.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...documents.map((doc) => _documentRow(doc)),
            ],
          ),
        );
      },
    );
  }
}
