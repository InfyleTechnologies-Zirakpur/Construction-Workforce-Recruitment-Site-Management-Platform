import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/company_repository.dart';

class CreateFeedScreen extends StatefulWidget {
  const CreateFeedScreen({super.key, this.postToEdit});

  final FeedPost? postToEdit;

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

  @override
  void initState() {
    super.initState();
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
        // Always try to refresh company name from the backend profile
        try {
          final profiles = await CompanyRepository().getMyProfiles();
          // ignore: avoid_print
          print('🏢 [CreateFeedScreen] getMyProfiles response: $profiles');
          if (profiles.isNotEmpty) {
            final p = profiles.first;
            // Try all possible company name fields from the backend
            final freshName = p['companyName']?.toString() ??
                p['businessName']?.toString() ??
                p['organizationName']?.toString() ??
                p['name']?.toString();

            String? resolvedName = freshName;
         
            if ((resolvedName == null || resolvedName.isEmpty) && p['fullName'] != null) {
              resolvedName = p['fullName'].toString();
            }

            // ignore: avoid_print
            print('🏢 [CreateFeedScreen] Resolved companyName: "$resolvedName" (was: "$cName")');

            if (resolvedName != null && resolvedName.isNotEmpty) {
              cName = resolvedName;
              await storage.write(key: 'companyName', value: cName);
            }
          }
        } catch (e) {
          // ignore: avoid_print
          print('⚠️ [CreateFeedScreen] Failed to fetch company profiles: $e');
        }
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
        const SnackBar(
          content: Text('Please write something to share in your post.'),
          backgroundColor: AppColors.error,
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
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Your feed post has been updated!'),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
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
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Your feed post has been published!'),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.dark),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.postToEdit != null ? 'Edit Feed Post' : 'Create Feed Post',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                child: ElevatedButton(
                  onPressed: _isPosting ? null : () => _submitPost(authorName, authorRole),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.postToEdit != null ? 'Save' : 'Post',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Header Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          authorName.isNotEmpty ? authorName[0].toUpperCase() : 'W',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.dark.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              authorRole,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Text Content Input
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: AppColors.dark,
                      ),
                      decoration: const InputDecoration(
                        hintText: "What's happening on your construction site?\nShare work updates, safety tips, material queries, or announcements...",
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                    ),
                  ),

                  // Optional Tagged Role / Job Title Field
                  if (_showTitleField) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.work_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Tag Job/Role (e.g. Construction Workers & Site Incharge)',
                                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.black45),
                            onPressed: () {
                              _titleController.clear();
                              setState(() => _showTitleField = false);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Optional Location Tag Field
                  if (_showLocationField) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                hintText: 'Enter site location (e.g. Mohali Sector 82)',
                                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.black45),
                            onPressed: () {
                              _locationController.clear();
                              setState(() => _showLocationField = false);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Option Bar (Tag Location & Tag Role optional)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: Icon(
                          _showLocationField ? Icons.location_on : Icons.add_location_alt_outlined,
                          size: 18,
                          color: _showLocationField ? AppColors.primary : AppColors.dark,
                        ),
                        label: Text(
                          _showLocationField ? 'Location Tagged' : 'Tag Location (Optional)',
                          style: TextStyle(
                            color: _showLocationField ? AppColors.primary : AppColors.dark,
                            fontSize: 12.5,
                            fontWeight: _showLocationField ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        backgroundColor: _showLocationField ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: _showLocationField ? AppColors.primary : Colors.black12,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showLocationField = !_showLocationField;
                          });
                        },
                      ),
                      ActionChip(
                        avatar: Icon(
                          _showTitleField ? Icons.work : Icons.work_outline,
                          size: 18,
                          color: _showTitleField ? AppColors.primary : AppColors.dark,
                        ),
                        label: Text(
                          _showTitleField ? 'Role Tagged' : 'Tag Role/Job (Optional)',
                          style: TextStyle(
                            color: _showTitleField ? AppColors.primary : AppColors.dark,
                            fontSize: 12.5,
                            fontWeight: _showTitleField ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        backgroundColor: _showTitleField ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: _showTitleField ? AppColors.primary : Colors.black12,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showTitleField = !_showTitleField;
                          });
                        },
                      ),
                    ],
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
