import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/utils/api_error_parser.dart';
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
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _salaryController = TextEditingController(text: '700');

  String _selectedTrade = 'Electrician';

  Uint8List? _photoBytes;
  bool _isUploadingPhoto = false;

  final Map<String, String?> _uploadedDocs = {
    'aadhaar': null,
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
      'type': 'aadhaar',
      'title': 'Aadhaar Card',
      'subtitle': 'Government photo ID & address verification',
      'badge': 'Recommended',
      'icon': Icons.badge_outlined,
      'isKey': true,
    },
    {
      'type': 'experience_certificate',
      'title': 'Experience Certificate',
      'subtitle': 'Past site proof or contractor letter',
      'badge': '2x Hiring Priority',
      'icon': Icons.work_history_outlined,
      'isKey': false,
    },
    {
      'type': 'skill_certificate',
      'title': 'Skill Certificate / ITI',
      'subtitle': 'Trade diploma, ITI certificate or license',
      'badge': 'Verified Skill',
      'icon': Icons.workspace_premium_outlined,
      'isKey': false,
    },
  ];

  static const List<String> _wagePills = ['500', '700', '900', '1200', '1500'];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _cityController.addListener(() => setState(() {}));
    _salaryController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ProfileCubit>().state;
      if (state is Loaded<WorkerProfile>) {
        final profile = state.data;
        if (profile.name.isNotEmpty && profile.name != 'Worker' && profile.name != 'Job Seeker') {
          _nameController.text = profile.name;
        }
        if (profile.city.isNotEmpty) {
          _cityController.text = profile.city;
        }
        if (profile.salaryExpectation.isNotEmpty) {
          final digits = profile.salaryExpectation.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.isNotEmpty) _salaryController.text = digits;
        }
        if (profile.skills.isNotEmpty) {
          final first = profile.skills.first;
          if (_tradeOptions.any((t) => t['name'] == first)) {
            setState(() => _selectedTrade = first);
          }
        }
        if (profile.documents.isNotEmpty) {
          setState(() {
            for (final doc in profile.documents) {
              final rawType = (doc['type'] ?? '').toString().toLowerCase();
              final filename = (doc['filename'] ?? doc['title'] ?? 'Uploaded Document').toString();
              if (rawType.contains('aadhaar')) {
                _uploadedDocs['aadhaar'] = filename;
              } else if (rawType.contains('experience')) {
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
    _nameController.dispose();
    _cityController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  double _calculateProgress() {
    int points = 0;
    if (_nameController.text.trim().length >= 3) points += 25;
    if (_cityController.text.trim().isNotEmpty) points += 25;
    if (_salaryController.text.trim().isNotEmpty) points += 20;
    final docsCount = _uploadedDocs.values.where((v) => v != null).length;
    points += (docsCount * 10);
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

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final wage = _salaryController.text.trim();
    final salaryString = wage.isNotEmpty ? '₹$wage/day' : '';

    context.read<ProfileCubit>().update({
      'name': _nameController.text.trim(),
      'phone': widget.phoneNumber,
      'city': _cityController.text.trim(),
      'skills': [_selectedTrade],
      'salaryExpectation': salaryString,
      'experience': [
        {'summary': 'Primary trade: $_selectedTrade'},
      ],
      'education': const [],
    });
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

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final progressPercent = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CompleteProfileAppBar(
        progress: progress,
        progressPercent: progressPercent,
      ),
      body: BlocListener<ProfileCubit, LoadState>(
        listener: (context, state) {
          if (state is Loaded) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomePage()),
              (_) => false,
            );
          }
          if (state is Failed) {
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
                      displayName: _nameController.text,
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
                      nameController: _nameController,
                      cityController: _cityController,
                      citySuggestions: _citySuggestions,
                      onSelectCity: (city) => setState(() => _cityController.text = city),
                    ),
                    const SizedBox(height: 14),

                    // 4. SELECT YOUR TRADE STUDIO
                    CompleteProfileSectionCard(
                      title: 'Select Your Trade',
                      subtitle: 'Choose your primary construction trade specialization',
                      icon: Icons.handyman_rounded,
                      child: CompleteProfileTradeGrid(
                        tradeOptions: _tradeOptions,
                        selectedTrade: _selectedTrade,
                        onTradeSelected: (trade) => setState(() => _selectedTrade = trade),
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

                    // 6. 3-ID DOCUMENT VERIFICATION SECTION
                    CompleteProfileSectionCard(
                      title: 'Verification Documents (3 IDs)',
                      subtitle: 'Upload proof of identity and past work to get verified by contractors',
                      icon: Icons.verified_user_rounded,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _countUploadedDocs() == 3 ? const Color(0xFFDCFCE7) : AppColors.peachBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _countUploadedDocs() == 3 ? const Color(0xFF86EFAC) : AppColors.peachBorder,
                          ),
                        ),
                        child: Text(
                          _countUploadedDocs() == 3 ? '3/3 Complete ✓' : '${_countUploadedDocs()}/3 Uploaded',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _countUploadedDocs() == 3 ? const Color(0xFF15803D) : AppColors.peachText,
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}
