import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TenderJobItem {
  final String id;
  final String companyName;
  final String? companyAvatar;
  final String timeAgo;
  final String title;
  final String description;
  final String location;
  final String budget;
  final String deadline;
  final String category;
  final int applicantsCount;
  final bool isApplied;
  final bool isSaved;

  const TenderJobItem({
    required this.id,
    required this.companyName,
    this.companyAvatar,
    required this.timeAgo,
    required this.title,
    required this.description,
    required this.location,
    required this.budget,
    required this.deadline,
    required this.category,
    this.applicantsCount = 0,
    this.isApplied = false,
    this.isSaved = false,
  });

  TenderJobItem copyWith({
    String? id,
    String? companyName,
    String? companyAvatar,
    String? timeAgo,
    String? title,
    String? description,
    String? location,
    String? budget,
    String? deadline,
    String? category,
    int? applicantsCount,
    bool? isApplied,
    bool? isSaved,
  }) {
    return TenderJobItem(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      companyAvatar: companyAvatar ?? this.companyAvatar,
      timeAgo: timeAgo ?? this.timeAgo,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      budget: budget ?? this.budget,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      isApplied: isApplied ?? this.isApplied,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class TenderFeedCard extends StatelessWidget {
  final TenderJobItem item;
  final VoidCallback onApply;
  final VoidCallback onBookmarkToggle;

  const TenderFeedCard({
    super.key,
    required this.item,
    required this.onApply,
    required this.onBookmarkToggle,
  });

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'CO';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : clean.length).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(item.companyName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Avatar + Company Name + Time + Green "Job" pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final hasValidAvatar = item.companyAvatar != null &&
                      item.companyAvatar!.trim().isNotEmpty &&
                      item.companyAvatar != 'null' &&
                      item.companyAvatar != 'undefined';

                  return CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.companyPrimary,
                    backgroundImage: hasValidAvatar
                        ? NetworkImage(item.companyAvatar!.trim())
                        : null,
                    onBackgroundImageError: hasValidAvatar ? (_, __) {} : null,
                    child: hasValidAvatar
                        ? null
                        : Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Job',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),

          // 3. Short Description
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 14),

         
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16.5,
                      color: AppColors.companyPrimaryDark,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.location,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee_rounded,
                      size: 16,
                      color: AppColors.companyPrimaryDark,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.budget,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          // Row 2: Deadline & Trade / Category
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16.5,
                      color: AppColors.companyPrimaryDark,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.deadline,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.business_center_outlined,
                      size: 16,
                      color: AppColors.companyPrimaryDark,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 5. Actions: Apply Now & Save/Bookmark
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: item.isApplied ? null : onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isApplied
                          ? const Color(0xFF16A34A)
                          : AppColors.companyPrimary,
                      disabledBackgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      item.isApplied ? 'Applied ✓' : 'Apply Now',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onBookmarkToggle,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.isSaved
                        ? AppColors.companyPrimaryLight
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.isSaved
                          ? AppColors.companyPrimary
                          : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    item.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 22,
                    color: item.isSaved
                        ? AppColors.companyPrimaryDark
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 6. Applicants count
          Text(
            '${item.applicantsCount} applicants',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

