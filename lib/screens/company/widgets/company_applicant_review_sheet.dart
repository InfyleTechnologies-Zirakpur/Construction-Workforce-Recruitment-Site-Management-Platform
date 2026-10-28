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
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark))),
        ],
      ),
    );
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
      case 'accepted':
      case 'hired':
        return const Color(0xFFDCFCE7);
      case 'shortlisted':
        return const Color(0xFFFEF9C3);
      case 'closed':
      case 'rejected':
        return const Color(0xFFFEE2E2);
      case 'draft':
      case 'pending':
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _getStatusFgColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
      case 'accepted':
      case 'hired':
        return const Color(0xFF15803D);
      case 'shortlisted':
        return const Color(0xFFB45309);
      case 'closed':
      case 'rejected':
        return const Color(0xFFB91C1C);
      case 'draft':
      case 'pending':
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final user = app['user'] is Map ? app['user'] : <String, dynamic>{};
    final job = app['job'] is Map ? app['job'] : <String, dynamic>{};
    final appId = app['id']?.toString() ?? '';

    // Status logic matching company_hiring_view
    final rawStatus = (app['status'] ?? 'pending').toString().toLowerCase().trim();
    final isShortlisted = rawStatus == 'shortlisted';
    final isHired = rawStatus == 'accepted' || rawStatus == 'hired';
    final isRejected = rawStatus == 'rejected';

    // Status rules:
    // 1. Shortlist -> disable Shortlist
    // 2. Hire/Accept -> disable Shortlist & Reject (and Accept)
    // 3. Reject -> disable all
    final bool canShortlist = !isShortlisted && !isHired && !isRejected;
    final bool canHire = !isHired && !isRejected;
    final bool canReject = !isHired && !isRejected;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Fixed Header (Drag Handle + Title + Close Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Candidate Review',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                ],
              ),
            ),

            // 2. Scrollable Body Content (Details, Documents, Remarks)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Candidate Info Row
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.companyPrimary,
                          child: Icon(Icons.person, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['fullName'] ?? user['name'] ?? 'Worker Candidate',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                ),
                              ),
                              Text(
                                'Applied for: ${job['title'] ?? 'Site Job'}',
                                style: const TextStyle(
                                  color: AppColors.companyPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    _modalDetailRow(Icons.phone, 'Contact Phone', user['phone'] ?? app['contactPhone'] ?? 'N/A'),
                    _modalDetailRow(Icons.currency_rupee, 'Expected Daily Wage', '₹ ${app['expectedDailyWage'] ?? 'As per posting'}'),
                    _modalDetailRow(Icons.history, 'Experience', '${app['experienceYears'] ?? 0} Years'),
                    _modalDetailRow(Icons.calendar_month, 'Available From', app['availableFrom']?.toString() ?? 'Immediate'),

                    if (app['coverNote'] != null && app['coverNote'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Cover Note:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.dark),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          app['coverNote'].toString(),
                          style: const TextStyle(fontSize: 13.5, color: AppColors.dark),
                        ),
                      ),
                    ],

                    // Candidate Documents / Resume Section
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Candidate Documents & Resume',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.dark),
                        ),
                        if (_isLoadingDocs)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.8),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (_candidateDocs.isEmpty && !_isLoadingDocs)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              'No documents attached to this profile',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
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
                            margin: const EdgeInsets.only(bottom: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isResume ? const Color(0xFFEFF6FF) : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isResume ? const Color(0xFFBFDBFE) : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isResume ? Icons.description_rounded : Icons.folder_shared_outlined,
                                  size: 18,
                                  color: isResume ? const Color(0xFF2563EB) : AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.dark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        isResume ? 'Job Seeker Resume' : type.replaceAll('_', ' ').toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11.5,
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
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                                      decoration: BoxDecoration(
                                        color: isResume ? const Color(0xFF2563EB) : AppColors.companyPrimary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.visibility_outlined, size: 13, color: Colors.white),
                                          SizedBox(width: 3),
                                          Text(
                                            'View',
                                            style: TextStyle(
                                              fontSize: 11.5,
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

                    const SizedBox(height: 10),
                    TextField(
                      controller: _remarksController,
                      maxLines: 2,
                      minLines: 1,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        labelText: 'Remark (sent as chat message)',
                        hintText: 'e.g. We\'d like to invite you for an interview on Monday.',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Sticky Frozen Action Buttons (Cannot be scrolled down)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Row Indicator
                  Row(
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.dark),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(rawStatus),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rawStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _getStatusFgColor(rawStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Action Buttons: [ Reject ] [ Shortlist ] [ Accept ]
                  Row(
                    children: [
                      // Reject Button
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: canReject
                                ? () {
                                    Navigator.pop(context);
                                    widget.onUpdateStatus(
                                      appId,
                                      'rejected',
                                      remarks: _remarksController.text.trim(),
                                      app: widget.app,
                                    );
                                  }
                                : null,
                            icon: Icon(
                              isRejected ? Icons.cancel_rounded : Icons.cancel_outlined,
                              size: 16,
                              color: canReject
                                  ? Colors.white
                                  : (isRejected ? const Color(0xFFB91C1C) : const Color(0xFF94A3B8)),
                            ),
                            label: Text(
                              isRejected ? 'Rejected' : 'Reject',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: canReject
                                    ? Colors.white
                                    : (isRejected ? const Color(0xFFB91C1C) : const Color(0xFF94A3B8)),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canReject ? const Color(0xFFDC2626) : const Color(0xFFFEE2E2),
                              disabledBackgroundColor: isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Shortlist Button
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: canShortlist
                                ? () {
                                    Navigator.pop(context);
                                    widget.onUpdateStatus(
                                      appId,
                                      'shortlisted',
                                      remarks: _remarksController.text.trim(),
                                      app: widget.app,
                                    );
                                  }
                                : null,
                            icon: Icon(
                              isShortlisted ? Icons.check_circle_outline_rounded : Icons.visibility_outlined,
                              size: 16,
                              color: canShortlist
                                  ? Colors.white
                                  : (isShortlisted ? const Color(0xFFB45309) : const Color(0xFF94A3B8)),
                            ),
                            label: Text(
                              isShortlisted ? 'Shortlisted' : 'Shortlist',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: canShortlist
                                    ? Colors.white
                                    : (isShortlisted ? const Color(0xFFB45309) : const Color(0xFF94A3B8)),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canShortlist ? const Color(0xFFD97706) : const Color(0xFFFEF3C7),
                              disabledBackgroundColor: isShortlisted ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Accept / Hire Button
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: canHire
                                ? () {
                                    Navigator.pop(context);
                                    widget.onUpdateStatus(
                                      appId,
                                      'accepted',
                                      remarks: _remarksController.text.trim(),
                                      app: widget.app,
                                    );
                                  }
                                : null,
                            icon: Icon(
                              isHired ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                              size: 16,
                              color: canHire
                                  ? Colors.white
                                  : (isHired ? const Color(0xFF15803D) : const Color(0xFF94A3B8)),
                            ),
                            label: Text(
                              isHired ? 'Accepted' : 'Accept',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: canHire
                                    ? Colors.white
                                    : (isHired ? const Color(0xFF15803D) : const Color(0xFF94A3B8)),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canHire ? const Color(0xFF059669) : const Color(0xFFDCFCE7),
                              disabledBackgroundColor: isHired ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
