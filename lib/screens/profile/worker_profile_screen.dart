import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../features/bloc/worker_blocs.dart';
import '../auth/login_screen.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/profile_details_card.dart';
import 'widgets/profile_documents_card.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_stats_bar.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  bool _isUploadingPhoto = false;
  bool _isUploadingDocument = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  static String _subtypeOf(String t) {
    final v = t.trim().toLowerCase();
    if (v == 'aadhaar') return 'aadhaar';
    if (v.startsWith('experience')) return 'experience';
    if (v.startsWith('skill')) return 'skill';
    return v;
  }

  int _countVerifiedDocs(List<Map<String, dynamic>> docs) {
    final types = docs
        .map((d) => _subtypeOf((d['type'] ?? '').toString()))
        .toSet();
    return ['aadhaar', 'experience', 'skill']
        .where((t) => types.contains(t))
        .length;
  }

  bool _isKycVerified(List<Map<String, dynamic>> docs) {
    return docs.any(
      (d) => _subtypeOf((d['type'] ?? '').toString()) == 'aadhaar',
    );
  }

  Future<void> _uploadPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    final url = await context.read<ProfileCubit>().uploadPhoto(
      bytes: await image.readAsBytes(),
      filename: image.name,
    );
    if (!mounted) return;

    setState(() => _isUploadingPhoto = false);
    _showMessage(
      url == null ? 'Photo upload failed.' : 'Profile photo updated.',
    );
    if (url != null) context.read<ProfileCubit>().load();
  }

  Future<void> _uploadDocument(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null || !mounted) return;

    setState(() => _isUploadingDocument = true);
    final document = await context.read<ProfileCubit>().uploadDocument(
      bytes: file!.bytes!,
      filename: file.name,
      type: type,
    );
    if (!mounted) return;

    setState(() => _isUploadingDocument = false);
    _showMessage(
      document == null
          ? 'Document upload failed.'
          : 'Document uploaded for verification.',
    );
    if (document != null) context.read<ProfileCubit>().load();
  }

  void _editProfile(WorkerProfile profile) {
    EditProfileSheet.show(
      context,
      profile: profile,
      onSave: (data) => context.read<ProfileCubit>().update(data),
    );
  }

  void _showMessage(String message) {
    final isErr = message.toLowerCase().contains('failed') ||
        message.toLowerCase().contains('error') ||
        message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('connection');
    final isNet = message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('connection') ||
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
                  : (isErr ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isErr ? const Color(0xFFDC2626) : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of BuildHire? You will need to verify your phone number to sign back in.',
      confirmLabel: 'Log Out',
      cancelLabel: 'Cancel',
      icon: Icons.logout_rounded,
      isDestructive: false,
    );

    if (confirm && context.mounted) {
      final authCubit = context.read<AuthCubit>();
      final profileCubit = context.read<ProfileCubit>();
      final jobsCubit = context.read<JobsCubit>();
      final dashboardCubit = context.read<DashboardCubit>();
      final messagesCubit = context.read<MessagesCubit>();
      final notificationsCubit = context.read<NotificationsCubit>();
      final navigator = Navigator.of(context, rootNavigator: true);

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      try {
        await NotificationService.instance.handleLogout();
      } catch (_) {}
      try {
        await authCubit.logout();
      } catch (_) {}

      try {
        profileCubit.reset();
      } catch (_) {}
      try {
        jobsCubit.reset();
      } catch (_) {}
      try {
        dashboardCubit.reset();
      } catch (_) {}
      try {
        messagesCubit.reset();
      } catch (_) {}
      try {
        notificationsCubit.reset();
      } catch (_) {}

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, LoadState<WorkerProfile>>(
      builder: (context, state) {
        if (state is Idle<WorkerProfile> || state is Loading<WorkerProfile>) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3.5,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is Failed<WorkerProfile>) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: AppColors.peachBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      state.message.toLowerCase().contains('internet') ||
                              state.message.toLowerCase().contains('connection') ||
                              state.message.toLowerCase().contains('network') ||
                              state.message.toLowerCase().contains('timed out')
                          ? Icons.wifi_off_rounded
                          : Icons.error_outline_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load profile',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>().load(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final profile = (state as Loaded<WorkerProfile>).data;
        final verifiedDocsCount = _countVerifiedDocs(profile.documents);
        final isKycVerified = _isKycVerified(profile.documents);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<ProfileCubit>().load(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // Profile Header Banner Card (Name Card)
                  ProfileHeaderCard(
                    profile: profile,
                    isUploadingPhoto: _isUploadingPhoto,
                    onUploadPhoto: _uploadPhoto,
                    isKycVerified: isKycVerified,
                  ),
                  const SizedBox(height: 16),

                  // Summary Stats Bar (Expected Wages, Trade Skills, Documents)
                  ProfileStatsBar(
                    profile: profile,
                    verifiedDocsCount: verifiedDocsCount,
                  ),

                  // Professional Details Card
                  ProfileDetailsCard(
                    profile: profile,
                    onEdit: () => _editProfile(profile),
                  ),
                  const SizedBox(height: 16),

                  // Documents Card
                  ProfileDocumentsCard(
                    documents: profile.documents,
                    isUploadingDocument: _isUploadingDocument,
                    onUploadDocument: _uploadDocument,
                  ),
                  const SizedBox(height: 20),

                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _editProfile(profile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit Profile Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Log Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.peachBackground,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.peachBorder,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
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
      },
    );
  }
}
