import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/resume/resume_storage_service.dart';

class _WorkExperienceControllers {
  final TextEditingController jobTitle;
  final TextEditingController companyName;
  final TextEditingController startDate;
  final TextEditingController endDate;
  final TextEditingController responsibility;
  bool isCurrentlyWorking;

  _WorkExperienceControllers({
    String jobTitle = '',
    String companyName = '',
    String startDate = '',
    String endDate = '',
    String responsibility = '',
    this.isCurrentlyWorking = false,
  })  : jobTitle = TextEditingController(text: jobTitle),
        companyName = TextEditingController(text: companyName),
        startDate = TextEditingController(text: startDate),
        endDate = TextEditingController(text: endDate),
        responsibility = TextEditingController(text: responsibility);

  ResumeWorkExperience toModel() {
    return ResumeWorkExperience(
      jobTitle: jobTitle.text.trim(),
      companyName: companyName.text.trim(),
      startDate: startDate.text.trim(),
      endDate: isCurrentlyWorking ? 'Present' : endDate.text.trim(),
      isCurrentlyWorking: isCurrentlyWorking,
      responsibility: responsibility.text.trim(),
    );
  }

  void dispose() {
    jobTitle.dispose();
    companyName.dispose();
    startDate.dispose();
    endDate.dispose();
    responsibility.dispose();
  }
}

class _EducationControllers {
  String qualification;
  final TextEditingController instituteName;
  final TextEditingController yearOfPassing;
  final TextEditingController percentageOrCgpa;

  _EducationControllers({
    this.qualification = '10th Pass',
    String instituteName = '',
    String yearOfPassing = '',
    String percentageOrCgpa = '',
  })  : instituteName = TextEditingController(text: instituteName),
        yearOfPassing = TextEditingController(text: yearOfPassing),
        percentageOrCgpa = TextEditingController(text: percentageOrCgpa);

  ResumeEducation toModel() {
    return ResumeEducation(
      qualification: qualification,
      instituteName: instituteName.text.trim(),
      yearOfPassing: yearOfPassing.text.trim(),
      percentageOrCgpa: percentageOrCgpa.text.trim(),
    );
  }

  void dispose() {
    instituteName.dispose();
    yearOfPassing.dispose();
    percentageOrCgpa.dispose();
  }
}

class _CertificationControllers {
  final TextEditingController name;
  final TextEditingController issuedBy;
  final TextEditingController issueDate;

  _CertificationControllers({
    String name = '',
    String issuedBy = '',
    String issueDate = '',
  })  : name = TextEditingController(text: name),
        issuedBy = TextEditingController(text: issuedBy),
        issueDate = TextEditingController(text: issueDate);

  ResumeCertification toModel() {
    return ResumeCertification(
      name: name.text.trim(),
      issuedBy: issuedBy.text.trim(),
      issueDate: issueDate.text.trim(),
    );
  }

  void dispose() {
    name.dispose();
    issuedBy.dispose();
    issueDate.dispose();
  }
}

class CreateResumeScreen extends StatefulWidget {
  final ResumeModel? initialResume;

  const CreateResumeScreen({super.key, this.initialResume});

  @override
  State<CreateResumeScreen> createState() => _CreateResumeScreenState();
}

class _CreateResumeScreenState extends State<CreateResumeScreen> {
  final _formKey = GlobalKey<FormState>();

  late final PageController _pageController;
  int _currentPage = 0;

  // 1. Personal Info Controllers
  late TextEditingController _titleController;
  late TextEditingController _fullNameController;
  late TextEditingController _dobController;
  String _selectedGender = 'Male';
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  // 2. Professional Summary Controllers
  late TextEditingController _currentRoleController;
  late TextEditingController _totalExperienceController;
  late TextEditingController _aboutYouController;

  // 3. Persistent Dynamic Item Controllers
  final List<_WorkExperienceControllers> _workExpControllers = [];
  final List<_EducationControllers> _educationControllers = [];
  final List<String> _technicalSkills = [];
  final List<String> _equipmentOperated = [];
  final List<_CertificationControllers> _certControllers = [];

  final TextEditingController _skillInputController = TextEditingController();
  final TextEditingController _equipmentInputController = TextEditingController();

  bool _isSaving = false;

  static const List<String> _suggestedSkills = [
    'AutoCAD',
    'Site Management',
    'Quantity Surveying',
    'Safety Protocols',
    'Bricklaying',
    'Plastering',
    'Bar Bending',
    'Electrical Wiring',
    'Plumbing',
    'Welding',
    'Tile Fitting',
    'Surveying',
  ];

  static const List<String> _suggestedEquipment = [
    'JCB',
    'Tower Crane',
    'Excavator',
    'Bulldozer',
    'Concrete Mixer',
    'Forklift',
    'Road Roller',
    'Hydra Crane',
    'Welding Machine',
  ];

  static const List<String> _qualifications = [
    '10th Pass',
    '12th Pass',
    'ITI',
    'Diploma in Civil',
    'Diploma in Mechanical',
    'Diploma in Electrical',
    'B.Tech / B.E Civil',
    'B.Tech / B.E Mechanical',
    'B.Tech / B.E Electrical',
    'Graduate',
    'Post Graduate',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final r = widget.initialResume;

    _titleController = TextEditingController(text: r?.title ?? '');
    _fullNameController = TextEditingController(text: r?.fullName ?? '');
    _dobController = TextEditingController(text: r?.dob ?? '');
    _selectedGender = (r?.gender != null && r!.gender.isNotEmpty) ? r.gender : 'Male';
    _phoneController = TextEditingController(text: r?.phone.replaceAll('+91', '').trim() ?? '');
    _emailController = TextEditingController(text: r?.email ?? '');
    _addressController = TextEditingController(text: r?.currentAddress ?? '');

    _currentRoleController = TextEditingController(text: r?.currentRole ?? '');
    _totalExperienceController = TextEditingController(text: r?.totalExperience ?? '');
    _aboutYouController = TextEditingController(text: r?.aboutYou ?? '');

    if (r != null) {
      for (final exp in r.workExperiences) {
        _workExpControllers.add(_WorkExperienceControllers(
          jobTitle: exp.jobTitle,
          companyName: exp.companyName,
          startDate: exp.startDate,
          endDate: exp.endDate,
          responsibility: exp.responsibility,
          isCurrentlyWorking: exp.isCurrentlyWorking,
        ));
      }
      for (final edu in r.educations) {
        _educationControllers.add(_EducationControllers(
          qualification: edu.qualification,
          instituteName: edu.instituteName,
          yearOfPassing: edu.yearOfPassing,
          percentageOrCgpa: edu.percentageOrCgpa,
        ));
      }
      for (final cert in r.certifications) {
        _certControllers.add(_CertificationControllers(
          name: cert.name,
          issuedBy: cert.issuedBy,
          issueDate: cert.issueDate,
        ));
      }
      _technicalSkills.addAll(r.technicalSkills);
      _equipmentOperated.addAll(r.equipmentOperated);
    }

    _prefillFromProfileIfEmpty();
  }

  void _prefillFromProfileIfEmpty() {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is Loaded<WorkerProfile>) {
      final p = profileState.data;
      if (_titleController.text.isEmpty && p.name.isNotEmpty) {
        _titleController.text = '${p.name} Resume';
      }
      if (_fullNameController.text.isEmpty && p.name.isNotEmpty) {
        _fullNameController.text = p.name;
      }
      if (_phoneController.text.isEmpty && p.phone.isNotEmpty) {
        _phoneController.text = p.phone.replaceAll('+91', '').trim();
      }
      if (_emailController.text.isEmpty && p.email != null && p.email!.isNotEmpty) {
        _emailController.text = p.email!;
      }
      if (_addressController.text.isEmpty && p.city.isNotEmpty) {
        _addressController.text = p.city;
      }
      if (_technicalSkills.isEmpty && p.skills.isNotEmpty) {
        _technicalSkills.addAll(p.skills);
      }
      if (p.experience.isNotEmpty) {
        if (_currentRoleController.text.isEmpty) {
          _currentRoleController.text = p.experience.first.role;
        }
        int totalYrs = 0;
        for (final exp in p.experience) {
          totalYrs += exp.years;
        }
        if (totalYrs > 0 && _totalExperienceController.text.isEmpty) {
          _totalExperienceController.text = '$totalYrs ${totalYrs == 1 ? "Year" : "Years"}';
        }
      }
      if (widget.initialResume == null && p.experience.isNotEmpty) {
        _workExpControllers.clear();
        for (final exp in p.experience) {
          _workExpControllers.add(_WorkExperienceControllers(
            jobTitle: exp.role,
            companyName: exp.company == 'XYZ Constructions' ? '' : exp.company,
            startDate: exp.startDate ?? (exp.years > 0 ? '${exp.years} Yrs' : ''),
            endDate: exp.endDate ?? (exp.isCurrentlyWorking ? 'Present' : ''),
            isCurrentlyWorking: exp.isCurrentlyWorking || exp.endDate == 'Present',
            responsibility: exp.responsibility ?? exp.summary ?? '',
          ));
        }
      }
      if (widget.initialResume == null && p.education.isNotEmpty) {
        _educationControllers.clear();
        for (final edu in p.education) {
          if (edu is Map) {
            _educationControllers.add(_EducationControllers(
              qualification: edu['qualification']?.toString() ?? edu['degree']?.toString() ?? '10th Pass',
              instituteName: edu['instituteName']?.toString() ?? edu['institution']?.toString() ?? '',
              yearOfPassing: edu['yearOfPassing']?.toString() ?? edu['year']?.toString() ?? '',
              percentageOrCgpa: edu['percentageOrCgpa']?.toString() ?? edu['score']?.toString() ?? '',
            ));
          } else if (edu is String && edu.trim().isNotEmpty) {
            _educationControllers.add(_EducationControllers(qualification: edu.trim(), instituteName: ''));
          }
        }
      }
    }

    if (_workExpControllers.isEmpty) {
      _workExpControllers.add(_WorkExperienceControllers(isCurrentlyWorking: true));
    }
    if (_educationControllers.isEmpty) {
      _educationControllers.add(_EducationControllers(qualification: '10th Pass'));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _currentRoleController.dispose();
    _totalExperienceController.dispose();
    _aboutYouController.dispose();
    _skillInputController.dispose();
    _equipmentInputController.dispose();
    for (final c in _workExpControllers) {
      c.dispose();
    }
    for (final c in _educationControllers) {
      c.dispose();
    }
    for (final c in _certControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1996, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentPage = 0);
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required personal information fields.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final phoneFormatted = _phoneController.text.trim().startsWith('+91')
          ? _phoneController.text.trim()
          : '+91 ${_phoneController.text.trim()}';

      final workExperiences = _workExpControllers
          .map((c) => c.toModel())
          .where((w) => w.jobTitle.isNotEmpty || w.companyName.isNotEmpty)
          .toList();
      final educations = _educationControllers
          .map((c) => c.toModel())
          .where((e) => e.instituteName.isNotEmpty || e.qualification.isNotEmpty)
          .toList();
      final certifications = _certControllers
          .map((c) => c.toModel())
          .where((c) => c.name.isNotEmpty)
          .toList();

      final resume = ResumeModel(
        id: widget.initialResume?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : '${_currentRoleController.text.trim().isNotEmpty ? _currentRoleController.text.trim() : "My"} Resume',
        updatedAt: DateTime.now(),
        usedApplicationsCount: widget.initialResume?.usedApplicationsCount ?? 0,
        fileUrl: widget.initialResume?.fileUrl,
        localPath: widget.initialResume?.localPath,
        isUploadedFile: false,
        fullName: _fullNameController.text.trim(),
        dob: _dobController.text.trim(),
        gender: _selectedGender,
        phone: phoneFormatted,
        email: _emailController.text.trim(),
        currentAddress: _addressController.text.trim(),
        currentRole: _currentRoleController.text.trim(),
        totalExperience: _totalExperienceController.text.trim(),
        aboutYou: _aboutYouController.text.trim(),
        workExperiences: workExperiences,
        educations: educations,
        technicalSkills: _technicalSkills,
        equipmentOperated: _equipmentOperated,
        certifications: certifications,
      );

      // Save and sync with backend (backend generates official multi-page PDF and commits to DB)
      await ResumeStorageService.addOrUpdateResume(resume);

      // Sync updated skills, education, and real experience with Worker Profile
      if (mounted) {
        final profilePayload = <String, dynamic>{
          'name': resume.fullName,
          'city': resume.currentAddress,
          if (resume.technicalSkills.isNotEmpty) 'skills': resume.technicalSkills,
          if (resume.workExperiences.isNotEmpty)
            'experience': resume.workExperiences.map((e) => e.toJson()).toList(),
          if (resume.educations.isNotEmpty)
            'education': resume.educations.map((e) => e.toJson()).toList(),
        };
        try {
          await context.read<ProfileCubit>().update(profilePayload);
        } catch (_) {}
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialResume == null ? 'Resume created successfully!' : 'Resume updated successfully!',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save resume: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getNextPageTitle(int pageIndex) {
    switch (pageIndex) {
      case 1:
        return 'Work Experience';
      case 2:
        return 'Skills & Gear';
      case 3:
        return 'Education & Certs';
      default:
        return 'Next';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.initialResume == null ? 'Create Resume' : 'Edit Resume',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveResume,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Column(
            children: [
              _buildStepTabs(),
              Container(color: const Color(0xFFE2E8F0), height: 1),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          onPageChanged: (idx) => setState(() => _currentPage = idx),
          children: [
            _buildPersonalInfoPage(),
            _buildWorkExperiencePage(),
            _buildSkillsPage(),
            _buildEducationAndCertsPage(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentPage > 0) ...[
              OutlinedButton.icon(
                onPressed: () {
                  final prev = _currentPage - 1;
                  setState(() => _currentPage = prev);
                  _pageController.animateToPage(
                    prev,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_currentPage < 3) {
                          final next = _currentPage + 1;
                          setState(() => _currentPage = next);
                          _pageController.animateToPage(
                            next,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _saveResume();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _currentPage < 3
                            ? 'Next: ${_getNextPageTitle(_currentPage + 1)} →'
                            : 'Save & Generate Official Resume',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTabs() {
    final steps = [
      {'title': '1. Personal', 'icon': Icons.person_outline},
      {'title': '2. Work Exp (${_workExpControllers.length})', 'icon': Icons.business_center_outlined},
      {'title': '3. Skills & Gear', 'icon': Icons.handyman_outlined},
      {'title': '4. Education & Certs', 'icon': Icons.school_outlined},
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _currentPage == index;
          return GestureDetector(
            onTap: () {
              setState(() => _currentPage = index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    steps[index]['icon'] as IconData,
                    size: 15,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    steps[index]['title'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
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

  // ─── PAGE 0: PERSONAL INFORMATION & SUMMARY ─────────────────────────
  Widget _buildPersonalInfoPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        _buildFieldLabel('Resume Title (e.g. Civil Engineer Resume)'),
        _buildTextField(
          controller: _titleController,
          hint: 'e.g. Site Supervisor CV, Lead Foreman',
          icon: Icons.title,
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(
          icon: Icons.person_outline_rounded,
          title: 'Personal Information',
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Full Name *'),
        _buildTextField(
          controller: _fullNameController,
          hint: 'Enter your full name',
          icon: Icons.badge_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Date of Birth'),
                  GestureDetector(
                    onTap: _selectDateOfBirth,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: _dobController,
                        hint: 'DD/MM/YYYY',
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Gender'),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGender = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Phone Number *'),
        _buildTextField(
          controller: _phoneController,
          hint: '10-digit mobile number',
          icon: Icons.phone_outlined,
          prefixText: '+91 ',
          keyboardType: TextInputType.phone,
          validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid 10-digit phone number' : null,
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Email Address'),
        _buildTextField(
          controller: _emailController,
          hint: 'e.g. name@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Current Address / City'),
        _buildTextField(
          controller: _addressController,
          hint: 'e.g. Noida Sector 62, Uttar Pradesh',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 24),

        _buildSectionHeader(
          icon: Icons.description_outlined,
          title: 'Professional Summary',
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Current Role / Designation'),
        _buildTextField(
          controller: _currentRoleController,
          hint: 'e.g. Site Supervisor, JCB Operator, Civil Engineer',
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('Total Experience'),
        _buildTextField(
          controller: _totalExperienceController,
          hint: 'e.g. 5 Years, 3+ Years',
        ),
        const SizedBox(height: 14),

        _buildFieldLabel('About You (Career Statement)'),
        _buildTextField(
          controller: _aboutYouController,
          hint: 'Write a brief summary of your construction background, expertise, and strengths (use **bold** for highlights)...',
          maxLines: 4,
        ),
      ],
    );
  }

  // ─── PAGE 1: WORK EXPERIENCE (DEDICATED PAGE FOR REAL JOBS) ─────────
  Widget _buildWorkExperiencePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enter all real jobs and site projects you have worked on. Each entry will be rendered with company, dates, and responsibilities on your resume.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E3A8A),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              icon: Icons.business_center_outlined,
              title: 'Work Experiences (${_workExpControllers.length})',
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _workExpControllers.add(_WorkExperienceControllers(isCurrentlyWorking: true));
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_workExpControllers.isEmpty)
          _buildEmptyPlaceholder('No work experience added yet. Tap "+ Add Job" above to add your real past jobs.')
        else
          ...List.generate(_workExpControllers.length, (index) => _buildWorkExperienceForm(index)),
      ],
    );
  }

  // ─── PAGE 2: SKILLS & MACHINERY ─────────────────────────────────────
  Widget _buildSkillsPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
      children: [
        _buildSectionHeader(
          icon: Icons.handyman_outlined,
          title: 'Technical Skills',
        ),
        const SizedBox(height: 12),

        _buildFieldLabel('Add Trade Skills'),
        _buildChipInput(
          controller: _skillInputController,
          hint: 'Type a skill (e.g. Brickwork) and press Enter or +',
          chips: _technicalSkills,
          onAdd: (val) {
            if (val.isNotEmpty && !_technicalSkills.contains(val)) {
              setState(() => _technicalSkills.add(val));
            }
          },
          onRemove: (val) => setState(() => _technicalSkills.remove(val)),
        ),
        const SizedBox(height: 10),
        _buildSuggestions(
          items: _suggestedSkills,
          selected: _technicalSkills,
          onSelect: (item) {
            setState(() {
              if (_technicalSkills.contains(item)) {
                _technicalSkills.remove(item);
              } else {
                _technicalSkills.add(item);
              }
            });
          },
        ),
        const SizedBox(height: 28),

        _buildSectionHeader(
          icon: Icons.precision_manufacturing_outlined,
          title: 'Equipment & Machinery Operated',
        ),
        const SizedBox(height: 12),

        _buildFieldLabel('Heavy Machinery / Tools'),
        _buildChipInput(
          controller: _equipmentInputController,
          hint: 'Type equipment (e.g. JCB, Crane) and press +',
          chips: _equipmentOperated,
          onAdd: (val) {
            if (val.isNotEmpty && !_equipmentOperated.contains(val)) {
              setState(() => _equipmentOperated.add(val));
            }
          },
          onRemove: (val) => setState(() => _equipmentOperated.remove(val)),
        ),
        const SizedBox(height: 10),
        _buildSuggestions(
          items: _suggestedEquipment,
          selected: _equipmentOperated,
          onSelect: (item) {
            setState(() {
              if (_equipmentOperated.contains(item)) {
                _equipmentOperated.remove(item);
              } else {
                _equipmentOperated.add(item);
              }
            });
          },
        ),
      ],
    );
  }

  // ─── PAGE 3: EDUCATION & CERTIFICATIONS ─────────────────────────────
  Widget _buildEducationAndCertsPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              icon: Icons.school_outlined,
              title: 'Education (${_educationControllers.length})',
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _educationControllers.add(_EducationControllers(qualification: 'Diploma in Civil'));
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_educationControllers.isEmpty)
          _buildEmptyPlaceholder('No education records added yet.')
        else
          ...List.generate(_educationControllers.length, (index) => _buildEducationForm(index)),
        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              icon: Icons.verified_outlined,
              title: 'Certifications & Licenses (${_certControllers.length})',
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _certControllers.add(_CertificationControllers());
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_certControllers.isEmpty)
          _buildEmptyPlaceholder('No certifications added yet.')
        else
          ...List.generate(_certControllers.length, (index) => _buildCertificationForm(index)),
      ],
    );
  }

  // ─── UI Helper Widgets ──────────────────────────────────────────────

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 14.5,
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: const Color(0xFF94A3B8))
            : null,
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildWorkExperienceForm(int index) {
    final item = _workExpControllers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                onPressed: () {
                  setState(() {
                    final removed = _workExpControllers.removeAt(index);
                    removed.dispose();
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFieldLabel('Job Title / Trade Role *'),
          _buildTextField(
            controller: item.jobTitle,
            hint: 'e.g. Mason, Site Supervisor, Crane Operator',
          ),
          const SizedBox(height: 10),
          _buildFieldLabel('Company / Contractor Name *'),
          _buildTextField(
            controller: item.companyName,
            hint: 'e.g. L&T Construction, Tata Projects, NCC Ltd',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Start Year/Date'),
                    _buildTextField(controller: item.startDate, hint: 'e.g. 2021'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('End Year/Date'),
                    _buildTextField(
                      controller: item.endDate,
                      hint: item.isCurrentlyWorking ? 'Present' : 'e.g. 2024',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: item.isCurrentlyWorking,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() {
                    item.isCurrentlyWorking = val ?? false;
                    if (item.isCurrentlyWorking) {
                      item.endDate.text = 'Present';
                    }
                  });
                },
              ),
              const Text(
                'Currently working in this role',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildFieldLabel('Responsibilities & Site Achievements'),
          _buildTextField(
            controller: item.responsibility,
            hint: 'e.g. Managed civil construction works, safety compliance, machinery inspection, workforce delegation',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationForm(int index) {
    final item = _educationControllers[index];
    final selectedQual = _qualifications.contains(item.qualification)
        ? item.qualification
        : _qualifications.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                onPressed: () {
                  setState(() {
                    final removed = _educationControllers.removeAt(index);
                    removed.dispose();
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFieldLabel('Qualification Level'),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedQual,
                isExpanded: true,
                items: _qualifications.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => item.qualification = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildFieldLabel('Institute / College / Board Name'),
          _buildTextField(
            controller: item.instituteName,
            hint: 'e.g. Government Polytechnic, Delhi University',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Passing Year'),
                    _buildTextField(
                      controller: item.yearOfPassing,
                      hint: 'e.g. 2020',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Score / CGPA / %'),
                    _buildTextField(
                      controller: item.percentageOrCgpa,
                      hint: 'e.g. 78% or 8.2',
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

  Widget _buildCertificationForm(int index) {
    final item = _certControllers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Certification #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                onPressed: () {
                  setState(() {
                    final removed = _certControllers.removeAt(index);
                    removed.dispose();
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildFieldLabel('Certification / License Name'),
          _buildTextField(
            controller: item.name,
            hint: 'e.g. Crane Operator License, OSHA Safety, First Aid',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Issued By'),
                    _buildTextField(controller: item.issuedBy, hint: 'e.g. NSDC, L&T Institute'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Issue Date'),
                    _buildTextField(controller: item.issueDate, hint: 'e.g. 2022'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipInput({
    required TextEditingController controller,
    required String hint,
    required List<String> chips,
    required ValueChanged<String> onAdd,
    required ValueChanged<String> onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                onFieldSubmitted: (v) {
                  final text = v.trim();
                  if (text.isNotEmpty) {
                    onAdd(text);
                    controller.clear();
                  }
                },
                style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: hint,
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 36),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  onAdd(text);
                  controller.clear();
                }
              },
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((c) {
              return Chip(
                label: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                backgroundColor: const Color(0xFFEFF6FF),
                deleteIconColor: const Color(0xFFEF4444),
                onDeleted: () => onRemove(c),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestions({
    required List<String> items,
    required List<String> selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        final isSel = selected.contains(item);
        return GestureDetector(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSel ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSel ? AppColors.primary : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSel ? Icons.check : Icons.add,
                  size: 13,
                  color: isSel ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  item,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyPlaceholder(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
