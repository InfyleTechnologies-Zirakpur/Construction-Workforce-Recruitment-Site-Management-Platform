import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/sub_contractor_dummy_data.dart';

export '../../core/data/sub_contractor_dummy_data.dart' show WorkLeadItem;

class WorkLeadsScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const WorkLeadsScreen({super.key, this.onRefresh});

  @override
  State<WorkLeadsScreen> createState() => _WorkLeadsScreenState();
}

class _WorkLeadsScreenState extends State<WorkLeadsScreen> {
  // 0 = Active, 1 = Applied, 2 = Saved, 3 = Rejected
  int _selectedTabIndex = 0;

  // Filter criteria from Advanced Filters
  String _filterProjectName = '';
  String _filterCategory = 'All Categories';
  String _filterLocation = '';
  String _filterMinBudget = '';
  String _filterMaxBudget = '';

  late List<WorkLeadItem> _leads;

  @override
  void initState() {
    super.initState();
    _leads = SubContractorDummyData.getInitialWorkLeads();
  }

  bool get _hasActiveFilters {
    return _filterProjectName.trim().isNotEmpty ||
        _filterCategory != 'All Categories' ||
        _filterLocation.trim().isNotEmpty ||
        _filterMinBudget.trim().isNotEmpty ||
        _filterMaxBudget.trim().isNotEmpty;
  }

  List<WorkLeadItem> get _displayedLeads {
    return _leads.where((item) {
      // 1. Tab condition
      if (_selectedTabIndex == 0) {
        // Active
        if (item.isApplied || item.isRejected) return false;
      } else if (_selectedTabIndex == 1) {
        // Applied
        if (!item.isApplied || item.isRejected) return false;
      } else if (_selectedTabIndex == 2) {
        // Saved
        if (!item.isSaved) return false;
      } else if (_selectedTabIndex == 3) {
        // Rejected
        if (!item.isRejected) return false;
      }

      // 2. Project Name or Client Name filter
      if (_filterProjectName.trim().isNotEmpty) {
        final query = _filterProjectName.trim().toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchClient = item.clientName.toLowerCase().contains(query);
        if (!matchTitle && !matchClient) return false;
      }

      // 3. Category filter
      if (_filterCategory != 'All Categories') {
        if (!item.category.toLowerCase().contains(_filterCategory.toLowerCase())) {
          return false;
        }
      }

      // 4. Location filter
      if (_filterLocation.trim().isNotEmpty) {
        final locQuery = _filterLocation.trim().toLowerCase();
        if (!item.location.toLowerCase().contains(locQuery)) return false;
      }

      return true;
    }).toList();
  }

  int get _activeCount => _leads.where((l) => !l.isApplied && !l.isRejected).length;
  int get _appliedCount => _leads.where((l) => l.isApplied && !l.isRejected).length;
  int get _savedCount => _leads.where((l) => l.isSaved).length;
  int get _rejectedCount => _leads.where((l) => l.isRejected).length;

  void _onToggleSave(WorkLeadItem lead) {
    setState(() {
      final index = _leads.indexWhere((l) => l.id == lead.id);
      if (index != -1) {
        final updated = _leads[index].copyWith(
          isSaved: !_leads[index].isSaved,
          savedAgo: !_leads[index].isSaved ? 'Saved: Just now' : null,
        );
        _leads[index] = updated;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lead.isSaved
              ? 'Removed "${lead.title}" from saved leads'
              : 'Saved "${lead.title}" successfully!',
        ),
        backgroundColor: AppColors.companyPrimaryDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openProposalSheet(WorkLeadItem lead) {
    final quoteController = TextEditingController();
    final timelineController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.companyPrimaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.companyPrimaryDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Submit Proposal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'To ${lead.clientName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Budget: ${lead.budget}  •  ${lead.location}',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Quoted Price (₹) *',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: quoteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 7,50,000',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Estimated Completion Timeline *',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: timelineController,
                decoration: InputDecoration(
                  hintText: 'e.g. 25 days / 4 weeks',
                  prefixIcon: const Icon(Icons.schedule_rounded, size: 20, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Cover Note / Team Capabilities',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Mention your team size, certifications, and similar completed projects...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final quote = quoteController.text.trim();
                    if (quote.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter your quoted price')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() {
                      final idx = _leads.indexWhere((l) => l.id == lead.id);
                      if (idx != -1) {
                        _leads[idx] = _leads[idx].copyWith(
                          isApplied: true,
                          proposalQuote: quote,
                          proposalTimeline: timelineController.text.trim(),
                          proposalNotes: notesController.text.trim(),
                        );
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Proposal successfully submitted to ${lead.clientName}!'),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.companyPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Submit Proposal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAdvancedFiltersSheet() {
    final nameController = TextEditingController(text: _filterProjectName);
    final locationController = TextEditingController(text: _filterLocation);
    final minBudgetController = TextEditingController(text: _filterMinBudget);
    final maxBudgetController = TextEditingController(text: _filterMaxBudget);
    String selectedCategory = _filterCategory;

    final categories = [
      'All Categories',
      'HVAC',
      'Electrical',
      'Plumbing',
      'Civil Construction',
      'Carpentry',
      'Masonry',
      'Painting',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header matching Screenshot 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.companyPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.filter_alt_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advanced Filters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Refine your search',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            nameController.clear();
                            locationController.clear();
                            minBudgetController.clear();
                            maxBudgetController.clear();
                            selectedCategory = 'All Categories';
                          });
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.companyPrimaryDark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 22),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 1. Project Name Field
                  Row(
                    children: const [
                      Icon(Icons.search, size: 16, color: AppColors.companyPrimaryDark),
                      SizedBox(width: 6),
                      Text(
                        'Project Name',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Search by project or company...',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Category Field
                  Row(
                    children: const [
                      Icon(Icons.business_center_outlined, size: 16, color: AppColors.companyPrimaryDark),
                      SizedBox(width: 6),
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(
                              cat,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedCategory = val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Location Field
                  Row(
                    children: const [
                      Icon(Icons.location_on_outlined, size: 16, color: AppColors.companyPrimaryDark),
                      SizedBox(width: 6),
                      Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      hintText: 'Delhi, Mumbai, Bengaluru...',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Budget Range Field
                  Row(
                    children: const [
                      Icon(Icons.currency_rupee_rounded, size: 16, color: AppColors.companyPrimaryDark),
                      SizedBox(width: 6),
                      Text(
                        'Budget Range (₹)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minBudgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Minimum',
                            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxBudgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Maximum',
                            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.companyPrimary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Apply Filters Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _filterProjectName = nameController.text;
                          _filterLocation = locationController.text;
                          _filterMinBudget = minBudgetController.text;
                          _filterMaxBudget = maxBudgetController.text;
                          _filterCategory = selectedCategory;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.companyPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _displayedLeads;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. Top Header Area (Work Leads, opportunities available, Filter icon)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Work Leads',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${displayed.length} ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.companyPrimaryDark,
                            ),
                          ),
                          const TextSpan(
                            text: 'opportunities available',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Filter Button matching Screenshot 1 top right
                InkWell(
                  onTap: _openAdvancedFiltersSheet,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hasActiveFilters
                            ? AppColors.companyPrimaryDark
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.filter_alt_outlined,
                          color: AppColors.companyPrimaryDark,
                          size: 24,
                        ),
                        if (_hasActiveFilters)
                          Positioned(
                            top: 9,
                            right: 9,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.companyPrimaryDark,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Tab Bar: Active (3) | Applied (2) | Saved (1) | Rejected (1)
          // Notice: Smooth horizontal scroll, larger text, NO bottom line/track
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildPillTab(
                      index: 0,
                      label: 'Active',
                      count: _activeCount,
                    ),
                    const SizedBox(width: 4),
                    _buildPillTab(
                      index: 1,
                      label: 'Applied',
                      count: _appliedCount,
                    ),
                    const SizedBox(width: 4),
                    _buildPillTab(
                      index: 2,
                      label: 'Saved',
                      count: _savedCount,
                    ),
                    const SizedBox(width: 4),
                    _buildPillTab(
                      index: 3,
                      label: 'Rejected',
                      count: _rejectedCount,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Scrollable list of Work Leads cards
          Expanded(
            child: displayed.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedTabIndex == 1
                              ? Icons.assignment_outlined
                              : _selectedTabIndex == 2
                                  ? Icons.bookmark_border_rounded
                                  : _selectedTabIndex == 3
                                      ? Icons.cancel_outlined
                                      : Icons.work_outline_rounded,
                          size: 52,
                          color: const Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedTabIndex == 1
                              ? 'No applied leads yet'
                              : _selectedTabIndex == 2
                                  ? 'No saved leads'
                                  : _selectedTabIndex == 3
                                      ? 'No rejected leads'
                                      : 'No leads matching current filters',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try clearing filters or check back later.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: displayed.length,
                    itemBuilder: (context, index) {
                      final lead = displayed[index];
                      return _buildLeadCard(lead);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required int index,
    required String label,
    required int count,
  }) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.companyPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF475569),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadCard(WorkLeadItem lead) {
    final isSavedView = _selectedTabIndex == 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
          // Top accent gradient bar (exact replica)
          Container(
            height: 3.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: lead.isRejected
                    ? const [Color(0xFFEF4444), Color(0xFFDC2626)]
                    : (isSavedView
                        ? const [Color(0xFFA855F7), Color(0xFF7C3AED)]
                        : const [Color(0xFFF59E0B), Color(0xFFD97706)]),
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title + Status Pill Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        lead.title,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: lead.isRejected
                              ? const Color(0xFF0F172A)
                              : (isSavedView
                                  ? const Color(0xFF0F172A)
                                  : AppColors.companyPrimaryDark),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: lead.isRejected
                            ? const Color(0xFFEF4444)
                            : (isSavedView
                                ? const Color(0xFFA855F7)
                                : AppColors.companyPrimary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lead.status,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 2. Client / Company Name
                Text(
                  lead.clientName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Description container box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lead.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 4. 2x2 Details Grid
                Row(
                  children: [
                    // Pill 1: Location
                    Expanded(
                      child: _buildDetailPill(
                        icon: Icons.location_on_outlined,
                        iconColor: isSavedView
                            ? const Color(0xFF2563EB)
                            : AppColors.companyPrimaryDark,
                        bgColor: const Color(0xFFEFF6FF),
                        text: lead.location,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pill 2: Budget
                    Expanded(
                      child: _buildDetailPill(
                        icon: Icons.currency_rupee_rounded,
                        iconColor: const Color(0xFF059669),
                        bgColor: const Color(0xFFECFDF5),
                        text: lead.budget,
                        isBold: true,
                        textColor: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Pill 3: Deadline
                    Expanded(
                      child: _buildDetailPill(
                        icon: Icons.calendar_today_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFFF5F3FF),
                        text: lead.deadline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Pill 4: Category
                    Expanded(
                      child: _buildDetailPill(
                        icon: Icons.business_center_outlined,
                        iconColor: const Color(0xFF9333EA),
                        bgColor: const Color(0xFFFAF5FF),
                        text: lead.category,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. Posted / Saved time chip (exact replica container)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSavedView
                        ? const Color(0xFFFAF5FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSavedView
                          ? const Color(0xFFF3E8FF)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSavedView
                              ? const Color(0xFFA855F7)
                              : (lead.isRejected
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF22C55E)),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSavedView
                            ? (lead.savedAgo ?? 'Saved: 3 days ago')
                            : lead.postedAgo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSavedView
                              ? const Color(0xFF9333EA)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if (!isSavedView && lead.proposalQuote != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          '• Quote: ${lead.proposalQuote}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: lead.isRejected
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (lead.isRejected && lead.rejectionReason != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lead.rejectionReason!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 6. Action buttons: Apply Now & Remove / Save (exact replica matching screenshots)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: (lead.isApplied || lead.isRejected)
                              ? null
                              : () => _openProposalSheet(lead),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lead.isRejected
                                ? const Color(0xFFE2E8F0)
                                : lead.isApplied
                                    ? const Color(0xFF16A34A)
                                    : AppColors.companyPrimary,
                            disabledBackgroundColor: lead.isRejected
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF16A34A),
                            foregroundColor: lead.isRejected
                                ? const Color(0xFF64748B)
                                : Colors.white,
                            disabledForegroundColor: lead.isRejected
                                ? const Color(0xFF64748B)
                                : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            lead.isRejected
                                ? 'Proposal Declined'
                                : lead.isApplied
                                    ? 'Applied ✓'
                                    : 'Apply Now',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: lead.isRejected
                                  ? const Color(0xFF64748B)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => _onToggleSave(lead),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSavedView
                                  ? const Color(0xFFEF4444)
                                  : (lead.isSaved
                                      ? AppColors.companyPrimaryDark
                                      : AppColors.companyPrimary),
                              width: 1.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isSavedView
                                ? 'Remove'
                                : (lead.isSaved ? 'Saved' : 'Save'),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: isSavedView
                                  ? const Color(0xFFDC2626)
                                  : (lead.isSaved
                                      ? AppColors.companyPrimaryDark
                                      : AppColors.companyPrimaryDark),
                            ),
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
    );
  }

  Widget _buildDetailPill({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String text,
    bool isBold = false,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: textColor ?? const Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
