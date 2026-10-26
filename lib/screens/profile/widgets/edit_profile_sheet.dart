import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

class _ExperienceItemControllers {
  final TextEditingController titleController;
  final TextEditingController companyController;
  final TextEditingController yearsController;

  _ExperienceItemControllers({
    required String title,
    required String company,
    required String years,
  })  : titleController = TextEditingController(text: title),
        companyController = TextEditingController(text: company),
        yearsController = TextEditingController(text: years);

  void dispose() {
    titleController.dispose();
    companyController.dispose();
    yearsController.dispose();
  }
}

class EditProfileSheet extends StatefulWidget {
  final WorkerProfile profile;
  final ValueChanged<Map<String, dynamic>> onSave;

  const EditProfileSheet({
    super.key,
    required this.profile,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required WorkerProfile profile,
    required ValueChanged<Map<String, dynamic>> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(profile: profile, onSave: onSave),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _salaryController;
  late final TextEditingController _skillsController;
  late final TextEditingController _emailController;
  late final List<_ExperienceItemControllers> _experienceList;

  static const List<String> _suggestedTrades = [
    'Electrician',
    'Plumber',
    'Mason',
    'Carpenter',
    'Painter',
    'Welder',
    'Site Helper',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _cityController = TextEditingController(text: widget.profile.city);
    _salaryController = TextEditingController(
      text: widget.profile.salaryExpectation.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    _skillsController = TextEditingController(
      text: widget.profile.skills.join(', '),
    );
    _emailController = TextEditingController(text: widget.profile.email ?? '');

    _experienceList = widget.profile.experience.map((WorkerExperience e) {
      return _ExperienceItemControllers(
        title: e.role,
        company: e.company,
        years: e.years > 0 ? e.years.toString() : '1',
      );
    }).toList();

    if (_experienceList.isEmpty) {
      _experienceList.add(_ExperienceItemControllers(
        title: widget.profile.skills.isNotEmpty ? widget.profile.skills.first : 'Mason',
        company: 'XYZ Constructions',
        years: '1',
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _salaryController.dispose();
    _skillsController.dispose();
    _emailController.dispose();
    for (final item in _experienceList) {
      item.dispose();
    }
    super.dispose();
  }

  void _addSuggestedSkill(String trade) {
    final currentList = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (!currentList.contains(trade)) {
      currentList.add(trade);
      setState(() {
        _skillsController.text = currentList.join(', ');
      });
    }
  }

  void _addExperienceItem() {
    setState(() {
      _experienceList.add(_ExperienceItemControllers(
        title: '',
        company: '',
        years: '1',
      ));
    });
  }

  void _removeExperienceItem(int index) {
    if (_experienceList.length <= 1) return;
    setState(() {
      final removed = _experienceList.removeAt(index);
      removed.dispose();
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showToast('Full name cannot be empty.');
      return;
    }

    final city = _cityController.text.trim();
    final rawSalary = _salaryController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final salary = rawSalary.isNotEmpty ? rawSalary : '800';
    final email = _emailController.text.trim();

    if (email.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showToast('Please enter a valid email address.');
      return;
    }

    final skills = _skillsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final experience = _experienceList
        .map((item) {
          final t = item.titleController.text.trim();
          final c = item.companyController.text.trim();
          final y = item.yearsController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
          return {
            'title': t.isNotEmpty ? t : (skills.isNotEmpty ? skills.first : 'Mason'),
            'company': c.isNotEmpty ? c : 'XYZ Constructions',
            'years': y.isNotEmpty ? y : '1',
          };
        })
        .where((exp) => exp['company']!.isNotEmpty || exp['title']!.isNotEmpty)
        .toList();

    final Map<String, dynamic> payload = {
      'name': name,
      'city': city,
      'salaryExpectation': salary,
      'skills': skills.isNotEmpty ? skills : ['Mason'],
      'experience': experience,
      'education': widget.profile.education,
    };

    if (email.isNotEmpty) {
      payload['email'] = email;
    }

    widget.onSave(payload);
    Navigator.of(context).pop();
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit Professional Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Update your profile options: city, salary, skills, email & experience',
                style: TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),

              // 1. FULL NAME
              _buildInputLabel('Full Name'),
              _buildTextField(
                controller: _nameController,
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),

              // 2. CITY (Preferred Location)
              _buildInputLabel('City / Preferred Location'),
              _buildTextField(
                controller: _cityController,
                hintText: 'e.g. Delhi, Mohali, Chandigarh',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 14),

              // 3. SALARY EXPECTATION
              _buildInputLabel('Salary Expectation (Daily/Monthly Wage)'),
              _buildTextField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                hintText: 'e.g. 800',
                prefixText: '₹ ',
                suffixText: '/day',
                prefixIcon: Icons.payments_outlined,
              ),
              const SizedBox(height: 14),

              // 4. SKILLS
              _buildInputLabel('Skills (replaces existing skills)'),
              _buildTextField(
                controller: _skillsController,
                hintText: 'e.g. Mason, Electrician, Plumber',
                prefixIcon: Icons.construction_outlined,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _suggestedTrades.map((trade) {
                  return InkWell(
                    onTap: () => _addSuggestedSkill(trade),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.peachBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.peachBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            trade,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.peachText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 5. EMAIL (Optional)
              _buildInputLabel('Email Address'),
              _buildTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                hintText: 'e.g. rahul@gmail.com',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 4),
              const Text(
                'Note: Changing email resets email verification status.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),

              // 6. EXPERIENCE LIST ({ title, company, years })
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputLabel('Work Experience ({ title, company, years })'),
                  TextButton.icon(
                    onPressed: _addExperienceItem,
                    icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Add More',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _experienceList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _experienceList[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Experience #${index + 1}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            if (_experienceList.length > 1)
                              InkWell(
                                onTap: () => _removeExperienceItem(index),
                                child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildMiniField(
                                controller: item.titleController,
                                hintText: 'Job Title (e.g. Mason)',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildMiniField(
                                controller: item.yearsController,
                                hintText: 'Years (e.g. 3)',
                                icon: Icons.access_time_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildMiniField(
                          controller: item.companyController,
                          hintText: 'Company / Site (e.g. XYZ Constructions)',
                          icon: Icons.business_outlined,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Profile Changes',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? prefixText,
    String? suffixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, color: AppColors.dark),
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
          prefixText: prefixText,
          prefixStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
          suffixText: suffixText,
          suffixStyle: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14.5, color: AppColors.dark),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 16),
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      ),
    );
  }
}