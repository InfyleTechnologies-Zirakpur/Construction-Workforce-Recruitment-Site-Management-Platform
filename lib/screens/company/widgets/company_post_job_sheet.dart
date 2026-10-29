import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../../features/repositories/company_repository.dart';
import '../company_profile_form_screen.dart';

class CompanyPostJobSheet extends StatefulWidget {
  final Map<String, dynamic>? myProfile;
  final Map<String, dynamic>? existingJob;
  final VoidCallback onJobPosted;

  const CompanyPostJobSheet({
    super.key,
    this.myProfile,
    this.existingJob,
    required this.onJobPosted,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic>? myProfile,
    Map<String, dynamic>? existingJob,
    required VoidCallback onJobPosted,
  }) async {
    if (myProfile == null) {
      final shouldSetup = await AppConfirmDialog.show(
        context,
        title: 'Company Profile Required',
        message:
            'You must register your company profile credentials before posting job requirements on the platform.',
        confirmLabel: 'Setup Profile',
        cancelLabel: 'Cancel',
        icon: Icons.business_rounded,
        isDestructive: false,
      );

      if (shouldSetup && context.mounted) {
        final created = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const CompanyProfileFormScreen()),
        );
        if (created == true && context.mounted) {
          onJobPosted();
          try {
            final profiles = await CompanyRepository().getMyProfiles();
            final updatedProfile = profiles.isNotEmpty ? profiles.first : null;
            if (updatedProfile != null && context.mounted) {
              CompanyPostJobSheet.show(
                context,
                myProfile: updatedProfile,
                existingJob: existingJob,
                onJobPosted: onJobPosted,
              );
            }
          } catch (_) {}
        }
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompanyPostJobSheet(
        myProfile: myProfile,
        existingJob: existingJob,
        onJobPosted: onJobPosted,
      ),
    );
  }

  @override
  State<CompanyPostJobSheet> createState() => _CompanyPostJobSheetState();
}

class _CompanyPostJobSheetState extends State<CompanyPostJobSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedJobType;

  final _titleFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  final _salaryFocusNode = FocusNode();
  final _experienceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  final _repo = CompanyRepository();
  bool _isSubmitting = false;

  static const List<String> _categoryOptions = [
    'Civil Engineering',
    'Site Management',
    'Construction Engineering',
    'Electrical & Wiring',
    'Plumbing & Sanitation',
    'Masonry & Concrete',
    'Carpentry & Woodwork',
    'Welding & Fabrication',
    'Painting & Finishing',
    'Heavy Machinery Operation',
    'Safety & Quality Inspection',
    'General Workforce & Labor',
    'Architecture & Planning',
  ];

  static const List<String> _jobTypeOptions = [
    'Full-time',
    'Part-time',
    'Contract',
    'Temporary',
    'Internship',
    'Freelance',
  ];

  @override
  void initState() {
    super.initState();
    _titleFocusNode.addListener(() => setState(() {}));
    _locationFocusNode.addListener(() => setState(() {}));
    _salaryFocusNode.addListener(() => setState(() {}));
    _experienceFocusNode.addListener(() => setState(() {}));
    _descriptionFocusNode.addListener(() => setState(() {}));

    if (widget.existingJob != null) {
      final job = widget.existingJob!;
      _titleController.text = (job['title'] ?? '').toString();
      _locationController.text = (job['location'] ?? job['address'] ?? '').toString();

      final sal = job['salary'] ?? job['compensation'] ?? job['pay'] ?? job['wage'];
      if (sal != null) _salaryController.text = sal.toString();

      final exp = job['experience'] ?? job['experienceRequired'] ?? job['yearsOfExperience'];
      if (exp != null) _experienceController.text = exp.toString();

      _descriptionController.text = (job['description'] ?? '').toString();

      final cat = job['category'] ?? (job['skills'] is List && (job['skills'] as List).isNotEmpty ? job['skills'][0] : null);
      if (cat != null && cat.toString().isNotEmpty) {
        _selectedCategory = cat.toString();
      }

      final type = job['jobType'] ?? job['type'] ?? job['employmentType'];
      if (type != null && type.toString().isNotEmpty) {
        _selectedJobType = type.toString();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();

    _titleFocusNode.dispose();
    _locationFocusNode.dispose();
    _salaryFocusNode.dispose();
    _experienceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 22),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2E8F0)),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _categoryOptions.length,
                itemBuilder: (context, idx) {
                  final cat = _categoryOptions[idx];
                  final isSel = _selectedCategory == cat;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFFEF3C7) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? const Color(0xFFD97706) : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (isSel)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFFD97706), size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJobTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Job Type',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 22),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2E8F0)),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _jobTypeOptions.length,
              itemBuilder: (context, idx) {
                final type = _jobTypeOptions[idx];
                final isSel = _selectedJobType == type;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedJobType = type);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFFEF3C7) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? const Color(0xFFD97706) : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (isSel)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFFD97706), size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Job Title.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Location.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final salaryText = _salaryController.text.trim();
      final numSalary = num.tryParse(salaryText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      final expText = _experienceController.text.trim();

      final payload = <String, dynamic>{
        'title': title,
        'location': location,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : '$title required at $location.',
        'compensation': numSalary,
        'workforceRequired': 1,
        'projectType': _selectedJobType ?? 'Full-time',
        'experienceLevel': expText.isNotEmpty ? expText : 'Any',
        'status': 'published',
        'skills': [
          if (_selectedCategory != null && _selectedCategory!.isNotEmpty) _selectedCategory!,
          title,
        ],
      };

      final existingId = widget.existingJob != null
          ? (widget.existingJob!['id'] ?? widget.existingJob!['_id'] ?? widget.existingJob!['jobId'])?.toString()
          : null;

      if (existingId != null && existingId.isNotEmpty) {
        await _repo.updateJob(existingId, payload);
      } else {
        await _repo.createJob(payload);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingId != null
                ? 'Job opening updated successfully!'
                : 'Job opening posted successfully!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onJobPosted();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final errStr = e.toString();
      if (errStr.contains('Company profile not found')) {
        Navigator.pop(context);
        final shouldSetup = await AppConfirmDialog.show(
          context,
          title: 'Company Profile Required',
          message:
              'Please complete your company profile details before posting job requirements.',
          confirmLabel: 'Setup Profile',
          cancelLabel: 'Cancel',
          icon: Icons.business_rounded,
          isDestructive: false,
        );
        if (shouldSetup && context.mounted) {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CompanyProfileFormScreen()),
          );
          if (created == true && context.mounted) {
            widget.onJobPosted();
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Posting failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const warmAmber = Color(0xFFF5A623); // Exact amber from screenshots
    final isEditing = widget.existingJob != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag bar indicator
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header & Subtitle (Exact Replica of Image 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Job Opening' : 'Create Job Opening',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEditing
                          ? 'Update the form below to modify this job opening.'
                          : 'Fill out the form below to create a new job opening.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Job Title
                      _buildFieldLabel('Job Title'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        hint: 'e.g., Senior Civil Engineer',
                        warmAmber: warmAmber,
                      ),
                      const SizedBox(height: 18),

                      // 2. Category Dropdown
                      _buildFieldLabel('Category'),
                      const SizedBox(height: 8),
                      _buildDropdownSelector(
                        value: _selectedCategory,
                        placeholder: 'Select Category',
                        onTap: _showCategoryPicker,
                      ),
                      const SizedBox(height: 18),

                      // 3. Location
                      _buildFieldLabel('Location'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _locationController,
                        focusNode: _locationFocusNode,
                        hint: 'e.g., Mumbai, Maharashtra',
                        warmAmber: warmAmber,
                      ),
                      const SizedBox(height: 18),

                      // 4. Salary
                      _buildFieldLabel('Salary'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _salaryController,
                        focusNode: _salaryFocusNode,
                        hint: 'e.g., ₹8-12 LPA or ₹25,000-35,000/month',
                        warmAmber: warmAmber,
                      ),
                      const SizedBox(height: 18),

                      // 5. Job Type Dropdown
                      _buildFieldLabel('Job Type'),
                      const SizedBox(height: 8),
                      _buildDropdownSelector(
                        value: _selectedJobType,
                        placeholder: 'Select Type',
                        onTap: _showJobTypePicker,
                      ),
                      const SizedBox(height: 18),

                      
                      _buildFieldLabel('Experience Required'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _experienceController,
                        focusNode: _experienceFocusNode,
                        hint: 'e.g., 5-8 years or 3+ years',
                        warmAmber: warmAmber,
                      ),
                      const SizedBox(height: 18),

                      // 7. Job Description
                      _buildFieldLabel('Job Description'),
                      const SizedBox(height: 8),
                      _buildTextArea(
                        controller: _descriptionController,
                        focusNode: _descriptionFocusNode,
                        hint: 'Enter a detailed job description...',
                        warmAmber: warmAmber,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // 8. Sticky Action Buttons at bottom: [ Post Job ] and [ Cancel ]
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    // Yellow Primary Button [ Post Job ]
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: warmAmber,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF0F172A),
                                ),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Post Job',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Outlined [ Cancel ] Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required Color warmAmber,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w500,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFF94A3B8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: warmAmber, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildDropdownSelector({
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                hasValue ? value : placeholder,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required Color warmAmber,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 4,
      maxLines: 6,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFF94A3B8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: warmAmber, width: 1.8),
        ),
      ),
    );
  }
}
