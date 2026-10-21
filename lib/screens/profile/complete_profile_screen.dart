import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../features/bloc/worker_blocs.dart';
import '../home/home_page.dart';
import 'widgets/complete_profile_app_bar.dart';
import 'widgets/complete_profile_basic_info_card.dart';
import 'widgets/complete_profile_documents_studio.dart';
import 'widgets/complete_profile_hero_card.dart';
import 'widgets/complete_profile_section_card.dart';
import 'widgets/complete_profile_stats_bar.dart';
import 'widgets/complete_profile_trade_grid.dart';
import 'widgets/complete_profile_wage_studio.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, required this.phoneNumber});
  final String phoneNumber;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _workerName = '';
  final _cityController = TextEditingController();
  final _salaryController = TextEditingController(text: '700');
  final _emailController = TextEditingController();
  final _experienceRoleController = TextEditingController();
  final _experienceCompanyController = TextEditingController();
  final _experienceYearsController = TextEditingController(text: '1');

  String _selectedTrade = 'Electrician';
  List<String> _selectedTrades = ['Electrician'];

  Uint8List? _photoBytes;
  bool _isUploadingPhoto = false;

  final Map<String, String?> _uploadedDocs = {
    'experience_certificate': null,
    'skill_certificate': null,
  };
  String? _uploadingDocType;

  static const List<Map<String, dynamic>> _tradeOptions = [
    {
      'name': 'Electrician',
      'specialty': 'Wiring • Panels ',
      'icon': Icons.bolt_rounded,
    },
    {
      'name': 'Plumber',
      'specialty': 'Piping • Sanitary',
      'icon': Icons.plumbing_rounded,
    },
    {
      'name': 'Mason (Mistri)',
      'specialty': 'Brickwork • Plaster',
      'icon': Icons.foundation_rounded,
    },
    {
      'name': 'Carpenter',
      'specialty': 'Woodwork • Doors',
      'icon': Icons.carpenter_rounded,
    },
    {
      'name': 'Painter',
      'specialty': 'Wall Putty • Polish',
      'icon': Icons.format_paint_rounded,
    },
    {
      'name': 'Welder',
      'specialty': 'Arc Welding • Steel ',
      'icon': Icons.hardware_rounded,
    },
  ];

  static const List<String> _citySuggestions = [
    'Mohali',
    'Chandigarh',
    'Zirakpur',
    'Panchkula',
    'Delhi NCR',
    'Ludhiana',
  ];

  static const List<Map<String, dynamic>> _documentSpecs = [
    {
      'type': 'skill_certificate',
      'title': 'Skill Certificate / ITI',
      'subtitle': 'Trade diploma, ITI certificate or license (mandatory)',
      'badge': 'Mandatory',
      'icon': Icons.workspace_premium_outlined,
      'isKey': true,
      'isMandatory': true,
    },
    {
      'type': 'experience_certificate',
      'title': 'Experience Certificate',
      'subtitle': 'Past site proof or contractor letter (optional)',
      'badge': 'Optional',
      'icon': Icons.work_history_outlined,
      'isKey': false,
      'isMandatory': false,
    },
  ];

  static const List<String> _wagePills = ['500', '700', '900', '1200', '1500'];

  @override
  void initState() {
    super.initState();
    _cityController.addListener(() => setState(() {}));
    _salaryController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _experienceRoleController.addListener(() => setState(() {}));
    _experienceCompanyController.addListener(() => setState(() {}));
    _experienceYearsController.addListener(() => setState(() {}));

    const storage = FlutterSecureStorage();
    storage.read(key: 'workerName').then((val) {
      if (val != null && val.isNotEmpty && mounted) {
        setState(() => _workerName = val);
      }
    });
    storage.read(key: 'name').then((val) {
      if (val != null && val.isNotEmpty && mounted && _workerName.isEmpty) {
        setState(() => _workerName = val);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ProfileCubit>().state;
      if (state is Loaded<WorkerProfile>) {
        final profile = state.data;
        if (profile.name.isNotEmpty && profile.name != 'Worker' && profile.name != 'Job Seeker') {
          setState(() => _workerName = profile.name);
        }
        if (profile.city.isNotEmpty) {
          _cityController.text = profile.city;
        }
        if (profile.email != null && profile.email!.isNotEmpty) {
          _emailController.text = profile.email!;
        }
        if (profile.salaryExpectation.isNotEmpty) {
          final digits = profile.salaryExpectation.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.isNotEmpty) _salaryController.text = digits;
        }
        if (profile.skills.isNotEmpty) {
          setState(() {
            _selectedTrades = List<String>.from(profile.skills);
            _selectedTrade = profile.skills.first;
          });
        }
        if (profile.experience.isNotEmpty) {
          final exp = profile.experience.first;
          _experienceRoleController.text = exp.role;
          _experienceCompanyController.text = exp.company;
          _experienceYearsController.text = exp.years > 0 ? exp.years.toString() : '1';
        }
        if (profile.documents.isNotEmpty) {
          setState(() {
            for (final doc in profile.documents) {
              final rawType = (doc['type'] ?? '').toString().toLowerCase();
              final filename = (doc['filename'] ?? doc['title'] ?? 'Uploaded Document').toString();
              if (rawType.contains('experience')) {
                _uploadedDocs['experience_certificate'] = filename;
              } else if (rawType.contains('skill')) {
                _uploadedDocs['skill_certificate'] = filename;
              }
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _salaryController.dispose();
    _emailController.dispose();
    _experienceRoleController.dispose();
    _experienceCompanyController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  double _calculateProgress() {
    int points = 30; // Name already verified and set at signup
    if (_cityController.text.trim().isNotEmpty) points += 25;
    if (_salaryController.text.trim().isNotEmpty) points += 25;
    if (_uploadedDocs['skill_certificate'] != null) points += 20;
    return (points / 100).clamp(0.0, 1.0);
  }

  int _countUploadedDocs() {
    return _uploadedDocs.values.where((v) => v != null).length;
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 800,
      );
      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _isUploadingPhoto = true;
      });

      if (!mounted) return;
      final url = await context.read<ProfileCubit>().uploadPhoto(
        bytes: bytes,
        filename: image.name,
      );
      if (!mounted) return;

      if (url == null) {
        _showSnack('Photo upload failed. Please try an image under 5MB.', isError: true);
      } else {
        _showSnack('Profile photo updated.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Unable to pick photo: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _pickDocument(String type, String title) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      final file = result?.files.single;
      if (file?.bytes == null || !mounted) return;

      setState(() => _uploadingDocType = type);

      final document = await context.read<ProfileCubit>().uploadDocument(
        bytes: file!.bytes!,
        filename: file.name,
        type: type,
      );
      if (!mounted) return;

      setState(() {
        _uploadingDocType = null;
        if (document != null) {
          _uploadedDocs[type] = file.name;
        }
      });

      if (document == null) {
        _showSnack('Upload failed for $title. File must be under 10MB.', isError: true);
      } else {
        _showSnack('$title uploaded successfully.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingDocType = null);
      _showSnack(ApiErrorParser.extractMessage(e, fallback: 'Failed to upload document.'), isError: true);
    }
  }

  void _stepWage(int delta) {
    final current = int.tryParse(_salaryController.text.trim()) ?? 700;
    final next = (current + delta).clamp(300, 5000);
    setState(() => _salaryController.text = next.toString());
  }

  bool _isSavingProfile = false;

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadedDocs['skill_certificate'] == null) {
      _showSnack('Please upload your Skill Certificate / ITI to continue.', isError: true);
      return;
    }

    final wage = _salaryController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final salaryString = wage.isNotEmpty ? wage : '700';
    final email = _emailController.text.trim();
    final effectiveSkills = _selectedTrades.isNotEmpty ? _selectedTrades : [_selectedTrade];

    final expRole = _experienceRoleController.text.trim();
    final expCompany = _experienceCompanyController.text.trim();
    final expYears = _experienceYearsController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    final List<Map<String, dynamic>> experienceList = [];
    if (expCompany.isNotEmpty || expRole.isNotEmpty) {
      experienceList.add({
        'title': expRole.isNotEmpty ? expRole : effectiveSkills.first,
        'company': expCompany.isNotEmpty ? expCompany : 'XYZ Constructions',
        'years': expYears.isNotEmpty ? expYears : '1',
      });
    }

    final Map<String, dynamic> body = {
      if (_workerName.isNotEmpty) 'name': _workerName,
      'city': _cityController.text.trim(),
      'skills': effectiveSkills,
      'salaryExpectation': salaryString,
      'experience': experienceList,
      'education': const [],
    };
    if (email.isNotEmpty) {
      body['email'] = email;
    }

    setState(() => _isSavingProfile = true);

    context.read<ProfileCubit>().update(body);
  }

  void _showSnack(String message, {bool isError = false}) {
    final isNet = message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('server') ||
        message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('timed out');
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isNet
                  ? Icons.wifi_off_rounded
                  : (isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13.5),
              ),
            ),
          ],
        ),
        backgroundColor: isError || isNet ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleBackPress() {
    AppConfirmDialog.show(
      context,
      title: 'Complete Your Profile',
      message:
          'Please complete your profile details and upload your mandatory skill certificate to start applying for site jobs.',
      confirmLabel: 'Continue Profile',
      cancelLabel: null,
      icon: Icons.assignment_ind_outlined,
      isDestructive: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final progressPercent = (progress * 100).toInt();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CompleteProfileAppBar(
          progress: progress,
          progressPercent: progressPercent,
          onBackPressed: _handleBackPress,
        ),
        body: BlocListener<ProfileCubit, LoadState>(
          listener: (context, state) async {
            if (state is Loaded && _isSavingProfile) {
              setState(() => _isSavingProfile = false);

              const storageEncrypted = FlutterSecureStorage(
                aOptions: AndroidOptions(encryptedSharedPreferences: true),
              );
              const storagePlain = FlutterSecureStorage();

              await storageEncrypted.write(key: 'profileCompleted', value: 'true');
              await storagePlain.write(key: 'profileCompleted', value: 'true');

              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (_) => false,
              );
            }
            if (state is Failed && _isSavingProfile) {
              setState(() => _isSavingProfile = false);
              _showSnack(state.message, isError: true);
            }
          },
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                  children: [
                    // 1. HERO IDENTITY CARD
                    CompleteProfileHeroCard(
                      displayName: _workerName,
                      displayCity: _cityController.text,
                      phoneNumber: widget.phoneNumber,
                      selectedTrade: _selectedTrade,
                      photoBytes: _photoBytes,
                      isUploadingPhoto: _isUploadingPhoto,
                      onPickPhoto: _pickPhoto,
                    ),
                    const SizedBox(height: 14),

                    // 2. LIVE SUMMARY STATS BAR
                    CompleteProfileStatsBar(
                      wage: '₹${_salaryController.text.trim().isEmpty ? '700' : _salaryController.text.trim()}/day',
                      selectedTrade: _selectedTrade,
                      uploadedDocsCount: _countUploadedDocs(),
                    ),
                    const SizedBox(height: 14),

                    // 3. PERSONAL DETAILS CARD
                    CompleteProfileBasicInfoCard(
                      cityController: _cityController,
                      emailController: _emailController,
                      citySuggestions: _citySuggestions,
                      onSelectCity: (city) => setState(() => _cityController.text = city),
                    ),
                    const SizedBox(height: 14),

                    // 4. SELECT YOUR TRADE STUDIO (Up to 4 Skills)
                    CompleteProfileSectionCard(
                      title: 'Select Trade Skills',
                      subtitle: 'Choose your construction skills (select up to 4)',
                      icon: Icons.handyman_rounded,
                      child: CompleteProfileTradeGrid(
                        tradeOptions: _tradeOptions,
                        selectedTrade: _selectedTrade,
                        selectedTrades: _selectedTrades,
                        onTradeSelected: (trade) {
                          setState(() {
                            if (_selectedTrades.contains(trade)) {
                              if (_selectedTrades.length > 1) {
                                _selectedTrades.remove(trade);
                              }
                            } else {
                              if (_selectedTrades.length < 4) {
                                _selectedTrades.add(trade);
                              } else {
                                _showSnack('Maximum 4 trade skills can be selected.');
                              }
                            }
                            _selectedTrade = _selectedTrades.first;
                            if (_experienceRoleController.text.isEmpty) {
                              _experienceRoleController.text = _selectedTrade;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. DAILY WAGE RATE STUDIO
                    CompleteProfileSectionCard(
                      title: 'Expected Daily Wage',
                      subtitle: 'Set your baseline wage rate for daily site work',
                      icon: Icons.payments_rounded,
                      child: CompleteProfileWageStudio(
                        salaryController: _salaryController,
                        selectedTrade: _selectedTrade,
                        wagePills: _wagePills,
                        onStepWage: _stepWage,
                        onSelectPreset: (rate) => setState(() => _salaryController.text = rate),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5.5 WORK EXPERIENCE CARD
                    CompleteProfileSectionCard(
                      title: 'Work Experience',
                      subtitle: 'Past company and site experience ({ title, company, years })',
                      icon: Icons.work_history_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Job Title / Trade',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _experienceRoleController,
                                      textCapitalization: TextCapitalization.words,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.dark),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Mason',
                                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                                        prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.textSecondary),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Years',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _experienceYearsController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.dark),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. 3',
                                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                                        prefixIcon: const Icon(Icons.access_time_rounded, size: 18, color: AppColors.textSecondary),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Company / Contractor Name',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _experienceCompanyController,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.dark),
                            decoration: InputDecoration(
                              hintText: 'e.g. XYZ Constructions',
                              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                              prefixIcon: const Icon(Icons.business_outlined, size: 18, color: AppColors.textSecondary),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 6. DOCUMENT VERIFICATION SECTION
                    CompleteProfileSectionCard(
                      title: 'Verification Documents',
                      subtitle: 'Skill certificate is mandatory; experience certificate is optional',
                      icon: Icons.verified_user_rounded,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _countUploadedDocs() == 2 ? const Color(0xFFDCFCE7) : AppColors.peachBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _countUploadedDocs() == 2 ? const Color(0xFF86EFAC) : AppColors.peachBorder,
                          ),
                        ),
                        child: Text(
                          _countUploadedDocs() == 2 ? '2/2 Uploaded ✓' : '${_countUploadedDocs()}/2 Uploaded',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _countUploadedDocs() == 2 ? const Color(0xFF15803D) : AppColors.peachText,
                          ),
                        ),
                      ),
                      child: CompleteProfileDocumentsStudio(
                        documentSpecs: _documentSpecs,
                        uploadedDocs: _uploadedDocs,
                        uploadingDocType: _uploadingDocType,
                        onPickDocument: _pickDocument,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 7. FINISH CALL-TO-ACTION BUTTON
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSubmitButton() {
    return BlocBuilder<ProfileCubit, LoadState>(
      builder: (context, state) {
        final isLoading = state is Loading;
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(
              isLoading ? 'Saving Profile...' : 'Save Profile & Explore Jobs',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}
