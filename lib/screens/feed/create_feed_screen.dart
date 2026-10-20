import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/company_repository.dart';
import 'widgets/create_post_tags_card.dart';


class CreateFeedScreen extends StatefulWidget {
  const CreateFeedScreen({super.key, this.postToEdit, this.isCompany});

  final FeedPost? postToEdit;
  final bool? isCompany;

  @override
  State<CreateFeedScreen> createState() => _CreateFeedScreenState();
}

class _CreateFeedScreenState extends State<CreateFeedScreen> {
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _titleController = TextEditingController();
  bool _showLocationField = false;
  bool _showTitleField = false;
  bool _isPosting = false;

  bool _isCompany = false;
  String? _companyName;

  Color get _themePrimary => _isCompany ? AppColors.companyPrimary : AppColors.primary;
  Color get _chipBg => _isCompany ? AppColors.companyTagBackground : AppColors.peachBackground;
  Color get _chipBorder => _isCompany ? AppColors.companyTagBorder : AppColors.peachBorder;
  Color get _chipText => _isCompany ? AppColors.companyTagText : AppColors.peachText;

  @override
  void initState() {
    super.initState();
    if (widget.isCompany != null) {
      _isCompany = widget.isCompany!;
    }
    if (widget.postToEdit != null) {
      _contentController.text = widget.postToEdit!.content;
      _titleController.text = widget.postToEdit!.taggedTitle ?? '';
      _locationController.text = widget.postToEdit!.location ?? '';
      _showTitleField = _titleController.text.isNotEmpty;
      _showLocationField = _locationController.text.isNotEmpty;
    }
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final role = await storage.read(key: 'role');
      var cName = await storage.read(key: 'companyName');

      if (role == 'company') {
        try {
          final profiles = await CompanyRepository().getMyProfiles();
          if (profiles.isNotEmpty) {
            final p = profiles.first;
            final freshName = p['companyName']?.toString() ??
                p['businessName']?.toString() ??
                p['organizationName']?.toString() ??
                p['name']?.toString() ??
                p['fullName']?.toString();

            if (freshName != null && freshName.isNotEmpty) {
              cName = freshName;
              await storage.write(key: 'companyName', value: cName);
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _isCompany = role == 'company';
          if (cName != null && cName.isNotEmpty) {
            _companyName = cName;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _submitPost(String authorName, String authorRole) {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write something to share in your post.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    final locationText = _locationController.text.trim();
    final titleText = _titleController.text.trim();

    if (widget.postToEdit != null) {
      context.read<FeedCubit>().updatePost(
            widget.postToEdit!.id,
            description: text,
            location: locationText.isNotEmpty ? locationText : null,
            title: titleText.isNotEmpty ? titleText : null,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Your feed post has been updated!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      context.read<FeedCubit>().addPost(
            content: text,
            location: locationText.isNotEmpty ? locationText : null,
            taggedTitle: titleText.isNotEmpty ? titleText : null,
            authorName: authorName,
            authorRole: authorRole,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Your feed post has been published!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    Navigator.of(context).pop(true);
  }

  InputDecoration _inputDeco({required String hint, String? label, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: _themePrimary) : null,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _themePrimary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, LoadState<WorkerProfile>>(
      builder: (context, profileState) {
        String authorName = _isCompany ? (_companyName ?? 'Company') : '';
        String authorRole = _isCompany ? 'Hiring Employer' : 'Construction Specialist';

        if (!_isCompany && profileState is Loaded<WorkerProfile>) {
          if (profileState.data.name.isNotEmpty) {
            authorName = profileState.data.name;
          }
          if (profileState.data.skills.isNotEmpty) {
            authorRole = profileState.data.skills.first;
          }
        }

        final isEditing = widget.postToEdit != null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.card,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.dark),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isEditing ? 'Edit Feed Post' : 'Create Feed Post',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.border, height: 1),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Author Header Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isCompany ? AppColors.companyPrimary : _chipBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCompany ? AppColors.companyPrimary : _chipBorder,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          authorName.isNotEmpty
                              ? authorName[0].toUpperCase()
                              : (_isCompany ? 'C' : 'W'),
                          style: TextStyle(
                            color: _isCompany ? Colors.white : _themePrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName.isNotEmpty ? authorName : 'Verified Member',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: AppColors.dark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: _chipBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _chipBorder, width: 0.8),
                              ),
                              child: Text(
                                authorRole,
                                style: TextStyle(
                                  color: _chipText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Post Content Input Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note_rounded, size: 20, color: _themePrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Post Content',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Share work updates, questions, material queries, or announcements',
                        style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 6,
                        style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.dark),
                        decoration: _inputDeco(
                          hint: "What's happening on your site? (e.g. Need 4 bar benders in Mohali, concrete pouring safety guidelines updated...)",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Optional Tags Card
                CreatePostTagsCard(
                  showTitleField: _showTitleField,
                  showLocationField: _showLocationField,
                  onToggleTitle: () => setState(() => _showTitleField = !_showTitleField),
                  onToggleLocation: () => setState(() => _showLocationField = !_showLocationField),
                  titleController: _titleController,
                  locationController: _locationController,
                  isCompany: _isCompany,
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _themePrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isPosting ? null : () => _submitPost(authorName, authorRole),
                        child: _isPosting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isEditing ? 'Save Changes' : 'Publish Post',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
