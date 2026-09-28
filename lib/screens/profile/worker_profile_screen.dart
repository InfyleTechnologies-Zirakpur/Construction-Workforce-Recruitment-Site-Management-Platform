import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';
import '../auth/login_screen.dart';

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
    _showMessage(url == null ? 'Photo upload failed.' : 'Profile photo updated.');
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
    final name = TextEditingController(text: profile.name);
    final city = TextEditingController(text: profile.city);
    final salary = TextEditingController(
      text: profile.salaryExpectation.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final skills = TextEditingController(text: profile.skills.join(', '));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit professional profile',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: city,
                    decoration: const InputDecoration(
                      labelText: 'Preferred location',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: salary,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Expected daily salary',
                      prefixText: '₹ ',
                      suffixText: '/day',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skills,
                    decoration: const InputDecoration(
                      labelText: 'Skills',
                      hintText: 'Electrician, Wiring',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<ProfileCubit>().update({
                          'name': name.text.trim(),
                          'city': city.text.trim(),
                          'salaryExpectation': '₹${salary.text.trim()}/day',
                          'skills': skills.text
                              .split(',')
                              .map((item) => item.trim())
                              .where((item) => item.isNotEmpty)
                              .toList(),
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Save changes'),
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<ProfileCubit, LoadState<WorkerProfile>>(
      builder: (context, state) {
        if (state is Idle<WorkerProfile> || state is Loading<WorkerProfile>) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: SmartSkeleton.list(
              itemCount: 4,
              hasLeading: true,
              leadingIsCircle: true,
              hasTags: false,
            ),
          );
        }

        if (state is Failed<WorkerProfile>) {
          return Center(
            child: Text('Unable to load profile', style: textTheme.titleMedium),
          );
        }

        final profile = (state as Loaded<WorkerProfile>).data;
        return RefreshIndicator(
          onRefresh: () => context.read<ProfileCubit>().load(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.w(20),
                  context.h(20),
                  context.w(20),
                  context.h(32),
                ),
                children: [
                  _profileHeader(context, profile, textTheme),
                  SizedBox(height: context.h(16)),
                  _section(
                    context,
                    title: 'Professional details',
                    icon: Icons.badge_outlined,
                    children: [
                      _detail(Icons.phone_outlined, 'Mobile number', '+91 ${profile.phone}'),
                      _detail(Icons.location_on_outlined, 'Preferred location', profile.city),
                      _detail(Icons.payments_outlined, 'Salary expectation', profile.salaryExpectation),
                      _detail(Icons.construction_outlined, 'Skills', profile.skills.join(', ')),
                    ],
                  ),
                  SizedBox(height: context.h(16)),
                  _section(
                    context,
                    title: 'Documents',
                    icon: Icons.folder_shared_outlined,
                    children: [
                      Text(
                        'Upload documents for contractor verification.',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      _documentRow('Aadhaar card', 'aadhaar'),
                      _documentRow('Experience certificate', 'experience_certificate'),
                      _documentRow('Skill certificate', 'skill_certificate'),
                      if (_isUploadingDocument) const LinearProgressIndicator(),
                    ],
                  ),
                  SizedBox(height: context.h(12)),
                  OutlinedButton.icon(
                    onPressed: () => _editProfile(profile),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile details'),
                  ),
                  SizedBox(height: context.h(12)),
                  OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Log out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Log out', style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out? ', style: TextStyle(color: AppColors.dark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Clear secure storage and state
      await context.read<AuthCubit>().logout();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _profileHeader(
    BuildContext context,
    WorkerProfile profile,
    TextTheme textTheme,
  ) {
    return Container(
      padding: EdgeInsets.all(context.w(18)),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: context.w(34),
                backgroundColor: Colors.white,
                backgroundImage: profile.profilePhotoUrl == null
                    ? null
                    : NetworkImage(profile.profilePhotoUrl!),
                child: profile.profilePhotoUrl == null
                    ? Icon(Icons.person, size: context.sp(38), color: AppColors.dark)
                    : null,
              ),
              Positioned(
                right: -3,
                bottom: -3,
                child: InkWell(
                  onTap: _isUploadingPhoto ? null : _uploadPhoto,
                  child: CircleAvatar(
                    radius: context.w(14),
                    backgroundColor: AppColors.primary,
                    child: _isUploadingPhoto
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: textTheme.titleLarge?.copyWith(color: Colors.white)),
                const SizedBox(height: 3),
                Text('Worker profile', style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
                Text('Tap the camera to update your photo', style: textTheme.bodySmall?.copyWith(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleMedium)]),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.dark),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  Widget _documentRow(String title, String type) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined, color: AppColors.primary),
      title: Text(title),
      subtitle: const Text('Upload for verification'),
      trailing: OutlinedButton(
        onPressed: _isUploadingDocument ? null : () => _uploadDocument(type),
        child: const Text('Upload'),
      ),
    );
  }
}
