import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'company_applicant_review_sheet.dart';

class CompanyApplicationsView extends StatelessWidget {
  final List<Map<String, dynamic>> applications;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChanged;
  final Set<String> selectedAppIds;
  final bool isBulkAction;
  final VoidCallback onBulkShortlist;
  final Function(String appId, String status, {String? remarks}) onUpdateStatus;

  const CompanyApplicationsView({
    super.key,
    required this.applications,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.selectedAppIds,
    required this.isBulkAction,
    required this.onBulkShortlist,
    required this.onUpdateStatus,
  });

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
      case 'accepted':
        return Colors.green.withValues(alpha: 0.12);
      case 'shortlisted':
        return Colors.blue.withValues(alpha: 0.12);
      case 'closed':
      case 'rejected':
        return AppColors.error.withValues(alpha: 0.12);
      case 'draft':
      case 'pending':
      default:
        return Colors.orange.withValues(alpha: 0.12);
    }
  }

  Color _getStatusFgColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
      case 'accepted':
        return Colors.green;
      case 'shortlisted':
        return Colors.blue;
      case 'closed':
      case 'rejected':
        return AppColors.error;
      case 'draft':
      case 'pending':
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Applications (${applications.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark)),
            if (selectedAppIds.isNotEmpty)
              ElevatedButton.icon(
                onPressed: isBulkAction ? null : onBulkShortlist,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                icon: const Icon(Icons.done_all, size: 16),
                label: Text('Shortlist (${selectedAppIds.length})', style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['all', 'pending', 'shortlisted', 'accepted', 'rejected'].map((st) {
              final isSel = statusFilter == st;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(st.toUpperCase(), style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.dark, fontWeight: FontWeight.bold)),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  onSelected: (val) {
                    if (val) onStatusFilterChanged(st);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        if (applications.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.inbox_outlined, size: 44, color: AppColors.primary),
                SizedBox(height: 10),
                Text('No Applications Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark)),
                SizedBox(height: 4),
                Text('Post a job requirement or change filter to view candidates.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          )
        else
          ...applications.map((app) {
            final user = app['user'] is Map ? app['user'] : <String, dynamic>{};
            final job = app['job'] is Map ? app['job'] : <String, dynamic>{};
            final userName = user['fullName'] ?? user['name'] ?? 'Worker Candidate';
            final userPhone = user['phone'] ?? app['contactPhone'] ?? 'N/A';
            final jobTitle = job['title'] ?? 'Construction Role';
            final status = (app['status'] ?? 'pending').toString();

            return InkWell(
              onTap: () => CompanyApplicantReviewSheet.show(
                context,
                app: app,
                onUpdateStatus: onUpdateStatus,
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFF2F4F7),
                          child: Icon(Icons.person, color: AppColors.dark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.dark)),
                              Text('Role: $jobTitle', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusFgColor(status))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (app['coverNote'] != null && app['coverNote'].toString().isNotEmpty) ...[
                      Text('Cover Note: ${app['coverNote']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(userPhone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                        const Text('Tap to review candidate →', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
