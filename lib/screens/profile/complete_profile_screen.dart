import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../features/bloc/worker_blocs.dart';
import '../home/home_page.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, required this.phoneNumber});
  final String phoneNumber;
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _salary = TextEditingController();
  final _experience = TextEditingController();
  final _education = TextEditingController();
  final Set<String> _skills = {'Electrician'};
  final Set<String> _documents = {};

  // Local state for picked-but-not-yet-uploaded assets.
  Uint8List? _photoBytes;
  String? _photoName;
  bool _isUploadingPhoto = false;
  String? _uploadingDocumentType;
  final Map<String, String> _uploadedDocumentNames = {};

  static const _skillChoices = [
    'Electrician',
    'Plumber',
    'Mason',
    'Carpenter',
    'Welder',
    'Painter',
  ];

  static const _documentTypes = {
    'Aadhaar card': 'aadhaar',
    'Experience certificate': 'experience_certificate',
    'Skill certificate': 'skill_certificate',
  };

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _salary.dispose();
    _experience.dispose();
    _education.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null || !mounted) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoName = image.name;
    });

    // Upload immediately, same as WorkerProfileScreen. If your ProfileCubit
    // requires an existing saved profile before uploadPhoto() works, move
    // this call to after _saveProfile() succeeds instead.
    setState(() => _isUploadingPhoto = true);
    final url = await context.read<ProfileCubit>().uploadPhoto(
      bytes: bytes,
      filename: image.name,
    );
    if (!mounted) return;
    setState(() => _isUploadingPhoto = false);
    _message(url == null ? 'Photo upload failed.' : 'Profile photo uploaded.');
  }

  Future<void> _pickDocument(String label, String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null || !mounted) return;

    setState(() => _uploadingDocumentType = type);
    final document = await context.read<ProfileCubit>().uploadDocument(
      bytes: file!.bytes!,
      filename: file.name,
      type: type,
    );
    if (!mounted) return;

    setState(() {
      _uploadingDocumentType = null;
      if (document != null) {
        _documents.add(label);
        _uploadedDocumentNames[label] = file.name;
      }
    });
    _message(
      document == null
          ? 'Document upload failed.'
          : 'Document uploaded for verification.',
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileCubit>().update({
      'name': _name.text.trim(),
      'phone': widget.phoneNumber,
      'city': _location.text.trim(),
      'skills': _skills.toList(),
      'salaryExpectation': '₹${_salary.text.trim()}/day',
      'experience': [
        {'summary': _experience.text.trim()},
      ],
      'education': [
        {'qualification': _education.text.trim()},
      ],
      // NOTE: 'documents' is intentionally NOT sent here. Each document is
      // already persisted via uploadDocument() when picked, and
      // WorkerProfile.fromJson expects `documents` to be a
      // List<Map<String, dynamic>>. Sending _documents (plain label
      // strings) here overwrites that field with strings, which then
      // fails to cast to Map<String, dynamic> on the next profile load —
      // this was the "String is not a subtype of Map<String, dynamic>"
      // error.
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Build your profile')),
    body: BlocListener<ProfileCubit, LoadState>(
      listener: (context, state) {
        if (state is Loaded)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (_) => false,
          );
        if (state is Failed)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
      },
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.w(20),
                context.h(16),
                context.w(20),
                context.h(32),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _intro(context),
                    _card(context, 'Personal details', Icons.person_outline, [
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: '+91 ${widget.phoneNumber}',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Mobile number',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _location,
                        decoration: const InputDecoration(
                          labelText: 'Preferred working location',
                        ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Enter a location'
                            : null,
                      ),
                    ]),
                    _card(
                      context,
                      'Skills and work history',
                      Icons.construction_outlined,
                      [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _skillChoices
                              .map(
                                (skill) => FilterChip(
                                  label: Text(skill, style: Theme.of(context).textTheme.bodySmall),
                                  selected: _skills.contains(skill),
                                  selectedColor: AppColors.primary.withValues(
                                    alpha: .18,
                                  ),
                                  onSelected: (selected) => setState(
                                    () => selected
                                        ? _skills.add(skill)
                                        : _skills.remove(skill),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _experience,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Previous work history',
                            hintText: 'Example: 2 years as a site electrician',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _education,
                          decoration: const InputDecoration(
                            labelText: 'Educational qualification',
                            hintText: 'Example: 10th pass / ITI electrician',
                          ),
                        ),
                      ],
                    ),
                    _card(
                      context,
                      'Work preferences',
                      Icons.payments_outlined,
                      [
                        TextFormField(
                          controller: _salary,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Expected daily salary',
                            prefixText: '₹ ',
                            suffixText: '/day',
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Enter your expected salary'
                              : null,
                        ),
                      ],
                    ),
                    _card(
                      context,
                      'Photo and identity documents',
                      Icons.verified_user_outlined,
                      [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: context.w(30),
                              backgroundColor: AppColors.dark,
                              backgroundImage: _photoBytes == null
                                  ? null
                                  : MemoryImage(_photoBytes!),
                              child: _photoBytes == null
                                  ? Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                      size: context.sp(32),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isUploadingPhoto ? null : _pickPhoto,
                                icon: _isUploadingPhoto
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.camera_alt_outlined),
                                label: Text(
                                  _photoBytes == null
                                      ? 'Add profile photo'
                                      : (_photoName ?? 'Photo selected'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ..._documentTypes.entries.map((entry) {
                          final label = entry.key;
                          final type = entry.value;
                          final isUploading = _uploadingDocumentType == type;
                          final isUploaded = _documents.contains(label);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.description_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(label),
                            subtitle: Text(
                              isUploaded
                                  ? (_uploadedDocumentNames[label] ?? 'Uploaded')
                                  : 'Not uploaded yet',
                            ),
                            trailing: isUploading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: () => _pickDocument(label, type),
                                    child: Text(isUploaded ? 'Replace' : 'Upload'),
                                  ),
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: context.h(12)),
                    BlocBuilder<ProfileCubit, LoadState>(
                      builder: (context, state) => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state is Loading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: context.h(16),
                            ),
                          ),
                          child: state is Loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              :  Text('Save profile and continue', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _intro(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(context.w(18)),
    decoration: BoxDecoration(
      color: AppColors.dark,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help contractors find you',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Add your skills and work preferences for relevant jobs.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    ),
  );
  Widget _card(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) => Container(
    margin: EdgeInsets.only(top: context.h(16)),
    padding: EdgeInsets.all(context.w(16)),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
