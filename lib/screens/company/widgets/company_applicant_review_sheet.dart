import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/repositories/worker_repository.dart';

class CompanyApplicantReviewSheet extends StatefulWidget {
  final Map<String, dynamic> app;
  final void Function(String appId, String status, {String? remarks, Map<String, dynamic>? app}) onUpdateStatus;

  const CompanyApplicantReviewSheet({
    super.key,
    required this.app,
    required this.onUpdateStatus,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> app,
    required void Function(String appId, String status, {String? remarks, Map<String, dynamic>? app}) onUpdateStatus,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompanyApplicantReviewSheet(
        app: app,
        onUpdateStatus: onUpdateStatus,
      ),
    );
  }

  @override
  State<CompanyApplicantReviewSheet> createState() => _CompanyApplicantReviewSheetState();
}

class _CompanyApplicantReviewSheetState extends State<CompanyApplicantReviewSheet> {
  late final TextEditingController _remarksController;
  bool _isLoadingDocs = false;
  List<Map<String, dynamic>> _candidateDocs = [];

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController(text: widget.app['reviewRemarks']?.toString() ?? '');
    _loadCandidateDocuments();
  }

  Future<void> _loadCandidateDocuments() async {
    final app = widget.app;
    final user = app['user'] is Map ? app['user'] : <String, dynamic>{};
    final userId = user['id']?.toString() ?? app['userId']?.toString();

    final initialDocs = <Map<String, dynamic>>[];
    if (app['documents'] is List) {
      initialDocs.addAll((app['documents'] as List).whereType<Map<String, dynamic>>());
    } else if (user['documents'] is List) {
      initialDocs.addAll((user['documents'] as List).whereType<Map<String, dynamic>>());
    }

    final directResume = app['resumeUrl']?.toString() ??
        user['resumeUrl']?.toString() ??
        app['resume']?.toString() ??
        user['resume']?.toString();
    if (directResume != null && directResume.isNotEmpty) {
      final exists = initialDocs.any((d) => (d['fileUrl'] ?? d['url']) == directResume);
      if (!exists) {
        initialDocs.insert(0, {
          'type': 'resume',
          'originalFilename': 'Candidate Resume.pdf',
          'fileUrl': directResume,
        });
      }
    }

    if (mounted) {
      setState(() => _candidateDocs = initialDocs);
    }

    if (userId != null && userId.isNotEmpty) {
      if (initialDocs.isEmpty) setState(() => _isLoadingDocs = true);
      try {
        final docs = await WorkerRepository().fetchDocumentsForUser(userId);
        if (mounted && docs.isNotEmpty) {
          setState(() {
            _candidateDocs = docs;
          });
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isLoadingDocs = false);
      }
    }
  }

  Future<void> _openDocUrl(String? url) async {
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

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Widget _modalDetailRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dark))),
        ],
      ),
    );
  }

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
    final app = widget.app;
    final user = app['user'] is Map ? app['user'] : <String, dynamic>{};
    final job = app['job'] is Map ? app['job'] : <String, dynamic>{};
    final appId = app['id']?.toString() ?? '';
    final status = (app['status'] ?? 'pending').toString();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Candidate Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(height: 20),

              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.companyPrimary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['fullName'] ?? user['name'] ?? 'Worker Candidate', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                        Text('Applied for: ${job['title'] ?? 'Site Job'}', style: const TextStyle(color: AppColors.companyPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _modalDetailRow(Icons.phone, 'Contact Phone', user['phone'] ?? app['contactPhone'] ?? 'N/A'),
              _modalDetailRow(Icons.currency_rupee, 'Expected Daily Wage', '₹ ${app['expectedDailyWage'] ?? 'As per posting'}'),
              _modalDetailRow(Icons.history, 'Experience', '${app['experienceYears'] ?? 0} Years'),
              _modalDetailRow(Icons.calendar_month, 'Available From', app['availableFrom']?.toString() ?? 'Immediate'),

              if (app['coverNote'] != null && app['coverNote'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Cover Note:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.dark)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(app['coverNote'].toString(), style: const TextStyle(fontSize: 15, color: AppColors.dark)),
                ),
              ],

              // Candidate Documents / Resume Section
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Candidate Documents & Resume',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.dark),
                  ),
                  if (_isLoadingDocs)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (_candidateDocs.isEmpty && !_isLoadingDocs)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text(
                        'No documents attached to this profile',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _candidateDocs.map((doc) {
                    final type = (doc['type'] ?? 'document').toString().toLowerCase();
                    final isResume = type == 'resume' || type == 'cv';
                    final name = doc['originalFilename']?.toString() ??
                        doc['fileName']?.toString() ??
                        doc['name']?.toString() ??
                        (isResume ? 'Candidate Resume' : '${type.replaceAll('_', ' ').toUpperCase()} Document');
                    final fileUrl = doc['fileUrl']?.toString() ?? doc['url']?.toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isResume ? const Color(0xFFEFF6FF) : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isResume ? const Color(0xFFBFDBFE) : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isResume ? Icons.description_rounded : Icons.folder_shared_outlined,
                            size: 20,
                            color: isResume ? const Color(0xFF2563EB) : AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.dark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isResume ? 'Job Seeker Resume' : type.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isResume ? const Color(0xFF2563EB) : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (fileUrl != null && fileUrl.isNotEmpty)
                            InkWell(
                              onTap: () => _openDocUrl(fileUrl),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isResume ? const Color(0xFF2563EB) : AppColors.companyPrimary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_outlined, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 16),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Remark (sent as chat message)',
                  hintText: 'e.g. We\'d like to invite you for an interview on Monday at 10 AM.',
                  helperText: 'This will be sent as the first message in your conversation with the candidate.',
                  helperMaxLines: 2,
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Change Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.dark)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getStatusFgColor(status)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Reject Button
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onUpdateStatus(appId, 'rejected', remarks: _remarksController.text.trim(), app: widget.app);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: status == 'rejected' ? AppColors.error : AppColors.error.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.error)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Shortlist Button
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onUpdateStatus(appId, 'shortlisted', remarks: _remarksController.text.trim(), app: widget.app);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Shortlist', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFFD97706))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Accept Button
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onUpdateStatus(appId, 'accepted', remarks: _remarksController.text.trim(), app: widget.app);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
