import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/company_repository.dart';

class CreateFeedScreen extends StatefulWidget {
  final FeedPost? postToEdit;
  final bool? isCompany;
  final bool isTab;
  final VoidCallback? onPostSuccess;

  const CreateFeedScreen({
    super.key,
    this.postToEdit,
    this.isCompany,
    this.isTab = false,
    this.onPostSuccess,
  });

  @override
  State<CreateFeedScreen> createState() => _CreateFeedScreenState();
}

class _CreateFeedScreenState extends State<CreateFeedScreen> {
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _projectController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isPosting = false;
  bool _isCompany = false;
  String? _companyName;
  String? _userName;
  String _selectedVisibility = 'Public';

  static const Color _warmAmber = Color(0xFFF5A623); // Exact amber from screenshots
  static const Color _darkText = Color(0xFF0F172A);
  static const Color _pillBg = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    if (widget.isCompany != null) {
      _isCompany = widget.isCompany!;
    }

    if (widget.postToEdit != null) {
      final post = widget.postToEdit!;
      _contentController.text = post.content;
      _projectController.text = post.taggedTitle ?? '';
      _locationController.text = post.location ?? '';
    }

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final role = await storage.read(key: 'role');
      final savedName = await storage.read(key: 'userName');
      var cName = await storage.read(key: 'companyName');

      if (role == 'company' || widget.isCompany == true) {
        try {
          final comp = await CompanyRepository().getMyCompanyProfile();
          final p = comp ?? (await CompanyRepository().getMyProfiles()).firstOrNull;
          if (p != null) {
            final freshName = p['name']?.toString() ??
                p['companyName']?.toString() ??
                p['businessName']?.toString() ??
                p['fullName']?.toString();

            if (freshName != null && freshName.trim().isNotEmpty) {
              cName = freshName.trim();
              await storage.write(key: 'companyName', value: cName);
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _isCompany = (role == 'company' || widget.isCompany == true);
          if (cName != null && cName.isNotEmpty) {
            _companyName = cName;
          }
          if (savedName != null && savedName.isNotEmpty) {
            _userName = savedName;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    _projectController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'AR';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _insertAtCursor(String textToInsert) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start;
    final end = selection.end;

    if (start < 0 || end < 0) {
      _contentController.text = text + textToInsert;
      _contentController.selection = TextSelection.collapsed(offset: _contentController.text.length);
    } else {
      final newText = text.replaceRange(start, end, textToInsert);
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + textToInsert.length),
      );
    }
    _focusNode.requestFocus();
  }

  void _toggleVisibility() {
    setState(() {
      if (_selectedVisibility == 'Public') {
        _selectedVisibility = 'Project Only';
      } else {
        _selectedVisibility = 'Public';
      }
    });
  }

  void _showSystemEmojiPicker() {
    // Dynamically generated native system emojis from Unicode codepoints
    final smileys = List.generate(0x1F64F - 0x1F600 + 1, (i) => String.fromCharCode(0x1F600 + i));
    final construction = [
      0x1F3D7, 0x1F6A7, 0x1F477, 0x1F528, 0x1F527, 0x1FA9B, 0x1F69C, 0x1F69B,
      0x1F3E2, 0x1F3E0, 0x1F4CF, 0x1F4D0, 0x26A0, 0x2705, 0x1F6E0, 0x2692, 0x1F9AF, 0x26FD
    ].map((code) => String.fromCharCode(code)).toList();
    final gestures = [
      0x1F44D, 0x1F44E, 0x1F44C, 0x1F44F, 0x1F64C, 0x1F91D, 0x1F4AA, 0x1F44B,
      0x270C, 0x1F91E, 0x1F91F, 0x1F446, 0x1F447, 0x261D
    ].map((code) => String.fromCharCode(code)).toList();
    final highlights = [
      0x1F389, 0x1F3C6, 0x1F3AF, 0x2B50, 0x1F525, 0x2728, 0x1F4AF, 0x1F4CA,
      0x1F4C8, 0x1F4DD, 0x1F514, 0x23F0
    ].map((code) => String.fromCharCode(code)).toList();

    int selectedTab = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final activeList = selectedTab == 0
              ? smileys
              : selectedTab == 1
                  ? construction
                  : selectedTab == 2
                      ? gestures
                      : highlights;

          return Container(
            height: 340,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'System Emojis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _darkText,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _warmAmber,
                        ),
                      ),
                    ),
                  ],
                ),
                // Category Tabs
                Row(
                  children: [
                    _buildEmojiTab('😀 Smileys', 0, selectedTab, () => setSheetState(() => selectedTab = 0)),
                    const SizedBox(width: 6),
                    _buildEmojiTab('🏗️ Site', 1, selectedTab, () => setSheetState(() => selectedTab = 1)),
                    const SizedBox(width: 6),
                    _buildEmojiTab('👍 Hands', 2, selectedTab, () => setSheetState(() => selectedTab = 2)),
                    const SizedBox(width: 6),
                    _buildEmojiTab('⭐ Stars', 3, selectedTab, () => setSheetState(() => selectedTab = 3)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: activeList.length,
                    itemBuilder: (_, index) {
                      final emoji = activeList[index];
                      return InkWell(
                        onTap: () {
                          _insertAtCursor(emoji);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmojiTab(String label, int index, int currentTab, VoidCallback onTap) {
    final isSelected = index == currentTab;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _warmAmber : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFFB45309) : _darkText,
            ),
          ),
        ),
      ),
    );
  }

  void _showTagProjectDialog() {
    final tempController = TextEditingController(text: _projectController.text);
    final quickProjects = [
      'Skyview Towers',
      'Metro Phase 2',
      'Highland Residency',
      'Downtown Mall Site',
      'Expressway Sector 4',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tag Project',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Link this update to a specific construction site or ongoing project.',
                style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tempController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Skyview Towers Phase 1',
                  prefixIcon: const Icon(Icons.domain_rounded, color: _warmAmber),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _warmAmber, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Select Project:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickProjects.map((p) {
                  return InkWell(
                    onTap: () {
                      setModalState(() {
                        tempController.text = p;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: tempController.text == p ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tempController.text == p ? _warmAmber : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tempController.text == p ? const Color(0xFFB45309) : _darkText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _projectController.text = tempController.text.trim();
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _warmAmber,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Save Tagged Project',
                    style: TextStyle(
                      color: _darkText,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
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

  void _showLocationDialog() {
    final tempController = TextEditingController(text: _locationController.text);
    final quickLocations = [
      'Mumbai, Maharashtra',
      'Bengaluru, Karnataka',
      'Pune Site 2',
      'Delhi NCR Project',
      'Hyderabad Central',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Set Location',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Specify the city, state or job site address for this update.',
                style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tempController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Bandra Kurla Complex, Mumbai',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: _warmAmber),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _warmAmber, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Popular Locations:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickLocations.map((loc) {
                  return InkWell(
                    onTap: () {
                      setModalState(() {
                        tempController.text = loc;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: tempController.text == loc ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tempController.text == loc ? const Color(0xFF3B82F6) : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        loc,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tempController.text == loc ? const Color(0xFF1D4ED8) : _darkText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _locationController.text = tempController.text.trim();
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _warmAmber,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Save Location',
                    style: TextStyle(
                      color: _darkText,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
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

  void _submitPost(String authorName, String authorRole) {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something to share in your update.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    final locationText = _locationController.text.trim();
    final projectText = _projectController.text.trim();

    if (widget.postToEdit != null) {
      context.read<FeedCubit>().updatePost(
            widget.postToEdit!.id,
            description: text,
            location: locationText.isNotEmpty ? locationText : null,
            title: projectText.isNotEmpty ? projectText : null,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Your update has been modified!'),
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
            taggedTitle: projectText.isNotEmpty ? projectText : null,
            authorName: authorName,
            authorRole: authorRole,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Your site update has been shared!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (widget.onPostSuccess != null) {
      widget.onPostSuccess!();
    } else if (Navigator.canPop(context)) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, LoadState<WorkerProfile>>(
      builder: (context, profileState) {
        String effectiveName = 'Alex Rivera';
        if (_userName != null && _userName!.trim().isNotEmpty) {
          effectiveName = _userName!.trim();
        } else if (_isCompany && _companyName != null && _companyName!.trim().isNotEmpty) {
          effectiveName = _companyName!.trim();
        } else if (!_isCompany && profileState is Loaded<WorkerProfile> && profileState.data.name.isNotEmpty) {
          effectiveName = profileState.data.name.trim();
        }

        final initials = _getInitials(effectiveName);
        final isEditing = widget.postToEdit != null;

        final projectSubtitle = _projectController.text.trim().isNotEmpty
            ? _projectController.text.trim().toUpperCase()
            : 'SKYVIEW TOWERS';
        final subtitleText = 'SITE SUPERVISOR • $projectSubtitle';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: !widget.isTab,
            leading: widget.isTab
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, color: _darkText, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
            title: Text(
              isEditing ? 'Edit Update' : 'Create Post',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _darkText,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 1. Author Header matching replica: Circle Avatar + Name + Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      // Golden/Amber circle with bold dark initials
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: _warmAmber,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _darkText,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // User Name
                      Expanded(
                        child: Text(
                          effectiveName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _darkText,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Light Grey Divider Line
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),

                // 3. Scrollable Input & Content Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Borderless Multiline Text Field
                        TextField(
                          controller: _contentController,
                          focusNode: _focusNode,
                          maxLines: null,
                          minLines: 6,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.45,
                            color: _darkText,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Share a site update, progress, or achievement...',
                            hintStyle: TextStyle(
                              fontSize: 16.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        
                        // Active Tag Badges (Project & Location)
                        if (_projectController.text.isNotEmpty || _locationController.text.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_projectController.text.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.domain_rounded, size: 15, color: Color(0xFFD97706)),
                                      const SizedBox(width: 5),
                                      Text(
                                        _projectController.text,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => setState(() => _projectController.clear()),
                                        child: const Icon(Icons.close, size: 14, color: Color(0xFFD97706)),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_locationController.text.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 5),
                                      Text(
                                        _locationController.text,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => setState(() => _locationController.clear()),
                                        child: const Icon(Icons.close, size: 14, color: Color(0xFF2563EB)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // 4. Action Chips: [ Tag Project ] and [ Location ]
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionPill(
                          icon: Icons.domain_rounded,
                          label: 'Tag Project',
                          onTap: _showTagProjectDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionPill(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          onTap: _showLocationDialog,
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Tool Row: [@, #, 🙂] on the left, [Visible to: Public] on the right
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // @ button
                      InkWell(
                        onTap: () => _insertAtCursor('@'),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            '@',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // # button
                      InkWell(
                        onTap: () => _insertAtCursor('#'),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            '#',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 🙂 Emoji button
                      InkWell(
                        onTap: _showSystemEmojiPicker,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Icon(
                            Icons.sentiment_satisfied_alt_outlined,
                            size: 24,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Visible to: Public
                      InkWell(
                        onTap: _toggleVisibility,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Visible to: ',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                TextSpan(
                                  text: _selectedVisibility,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: _warmAmber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 6. Bottom Sticky Primary Button: [ Share Update ]
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : () => _submitPost(effectiveName, 'Site Supervisor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _warmAmber,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _darkText,
                              ),
                            )
                          : Text(
                              isEditing ? 'Save Changes' : 'Share Update',
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: _darkText,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _pillBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: _warmAmber,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _darkText,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
