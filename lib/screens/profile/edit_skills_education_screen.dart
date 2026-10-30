import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../features/bloc/worker_blocs.dart';

class _EducationItemControllers {
  String qualification;
  final TextEditingController instituteController;
  final TextEditingController yearController;
  final TextEditingController scoreController;

  _EducationItemControllers({
    required this.qualification,
    required String institute,
    required String year,
    required String score,
  })  : instituteController = TextEditingController(text: institute),
        yearController = TextEditingController(text: year),
        scoreController = TextEditingController(text: score);

  void dispose() {
    instituteController.dispose();
    yearController.dispose();
    scoreController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'qualification': qualification.trim(),
      'instituteName': instituteController.text.trim(),
      'yearOfPassing': yearController.text.trim(),
      'percentageOrCgpa': scoreController.text.trim(),
    };
  }
}

class EditSkillsEducationScreen extends StatefulWidget {
  final WorkerProfile profile;
  final bool initialFocusEducation;

  const EditSkillsEducationScreen({
    super.key,
    required this.profile,
    this.initialFocusEducation = false,
  });

  @override
  State<EditSkillsEducationScreen> createState() => _EditSkillsEducationScreenState();
}

class _EditSkillsEducationScreenState extends State<EditSkillsEducationScreen> {
  late final List<String> _skills;
  late final List<_EducationItemControllers> _educations;
  final TextEditingController _customSkillController = TextEditingController();
  final FocusNode _customSkillFocusNode = FocusNode();
  bool _isSaving = false;

  static const List<String> _commonTrades = [
    'Electrician',
    'Plumber',
    'Mason',
    'Carpenter',
    'Welder',
    'Painter',
    'Site Helper',
    'Crane Operator',
    'Tile Mason',
    'HVAC Technician',
    'Bar Bender',
    'Foreman',
    'Scaffolder',
    'Surveyor',
    'Heavy Equipment Operator',
  ];

  static const List<String> _qualificationOptions = [
    '10th Pass',
    '12th Pass / Intermediate',
    'ITI / Trade Certificate',
    'Diploma in Civil Engineering',
    'Diploma in Electrical Engineering',
    'Diploma in Mechanical Engineering',
    'Polytechnic Diploma',
    'B.Tech / B.E. (Civil)',
    'B.Tech / B.E. (Electrical)',
    'B.Tech / B.E. (Mechanical)',
    'Graduate (B.A / B.Sc / B.Com)',
    'Post Graduate',
    'Vocational Training',
    'Other Qualification',
  ];

  @override
  void initState() {
    super.initState();
    _skills = List<String>.from(widget.profile.skills);
    if (_skills.isEmpty) {
      _skills.add('Site Helper');
    }

    final parsed = widget.profile.parsedEducation;
    if (parsed.isNotEmpty) {
      _educations = parsed.map((ResumeEducation e) {
        return _EducationItemControllers(
          qualification: e.qualification.isNotEmpty ? e.qualification : '10th Pass',
          institute: e.instituteName,
          year: e.yearOfPassing,
          score: e.percentageOrCgpa,
        );
      }).toList();
    } else {
      _educations = [
        _EducationItemControllers(
          qualification: '10th Pass',
          institute: '',
          year: '',
          score: '',
        ),
      ];
    }
  }

  @override
  void dispose() {
    _customSkillController.dispose();
    _customSkillFocusNode.dispose();
    for (final e in _educations) {
      e.dispose();
    }
    super.dispose();
  }

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    final exists = _skills.any((s) => s.toLowerCase() == trimmed.toLowerCase());
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$trimmed" is already in your skills list.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _skills.add(trimmed);
      _customSkillController.clear();
    });
  }

  void _removeSkill(String skill) {
    if (_skills.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one trade skill is required.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _skills.remove(skill);
    });
  }

  void _addEducationRow() {
    setState(() {
      _educations.add(
        _EducationItemControllers(
          qualification: '10th Pass',
          institute: '',
          year: '',
          score: '',
        ),
      );
    });
  }

  void _removeEducationRow(int index) {
    setState(() {
      final removed = _educations.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _saveChanges() async {
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one trade skill.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final educationList = _educations
        .where((e) =>
            e.qualification.trim().isNotEmpty ||
            e.instituteController.text.trim().isNotEmpty)
        .map((e) => e.toMap())
        .toList();

    try {
      await context.read<ProfileCubit>().update({
        'skills': _skills,
        'education': educationList,
      });

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Skills & education saved successfully.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Skills & Education',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.dark),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                _isSaving ? 'Saving' : 'Save',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ─── 1. TRADE SKILLS SECTION ──────────────────
            _buildSectionContainer(
              title: 'Trade Skills',
              subtitle: 'Select from popular trades or type your custom skill',
              icon: Icons.construction_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Custom Skill Input Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customSkillController,
                          focusNode: _customSkillFocusNode,
                          textInputAction: TextInputAction.done,
                          onSubmitted: _addSkill,
                          decoration: InputDecoration(
                            hintText: 'e.g. Solar Panel Installer, Rigger...',
                            hintStyle: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _addSkill(_customSkillController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '+ Add',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current Selected Skills
                  const Text(
                    'Selected Skills:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_skills.isEmpty)
                    const Text(
                      'No skills selected. Please add at least one.',
                      style: TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.peachBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.peachBorder, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                skill,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.peachText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _removeSkill(skill),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 18),

                  // Quick Suggestion Chips
                  const Text(
                    'Quick Suggestions:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _commonTrades.map((trade) {
                      final isSelected = _skills.any((s) => s.toLowerCase() == trade.toLowerCase());
                      return InkWell(
                        onTap: () {
                          if (isSelected) {
                            _removeSkill(trade);
                          } else {
                            _addSkill(trade);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0x1F2B5B84) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? Icons.check_rounded : Icons.add_rounded,
                                size: 14,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trade,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.dark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── 2. EDUCATION & QUALIFICATIONS SECTION ───────
            _buildSectionContainer(
              title: 'Education & Qualifications',
              subtitle: 'Add degrees, diplomas, ITI certificates, or schooling',
              icon: Icons.school_rounded,
              trailing: TextButton.icon(
                onPressed: _addEducationRow,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add More'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              child: Column(
                children: [
                  if (_educations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No education records added yet.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _addEducationRow,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add Qualification'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._educations.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final edu = entry.value;
                      return _buildEducationCard(idx, edu);
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(
              _isSaving ? 'Saving Changes...' : 'Save Changes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.peachBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildEducationCard(int index, _EducationItemControllers edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
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
                'Qualification #${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (_educations.length > 1)
                InkWell(
                  onTap: () => _removeEducationRow(index),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Qualification Dropdown
          const Text(
            'Qualification / Degree',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _qualificationOptions.contains(edu.qualification)
                ? edu.qualification
                : _qualificationOptions.first,
            isExpanded: true,
            decoration: _inputDecoration(hint: 'Select qualification'),
            items: _qualificationOptions.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(
                  opt,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.dark),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => edu.qualification = val);
              }
            },
          ),
          const SizedBox(height: 12),

          // Institute Name
          const Text(
            'School / College / Institute Name',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: edu.instituteController,
            decoration: _inputDecoration(
              hint: 'e.g. Government ITI, Delhi / St. Xavier High School',
            ),
          ),
          const SizedBox(height: 12),

          // Year and Score in two columns
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Passing Year',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: edu.yearController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(hint: 'e.g. 2022'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Score / CGPA / %',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: edu.scoreController,
                      decoration: _inputDecoration(hint: 'e.g. 78% or 8.2'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}

