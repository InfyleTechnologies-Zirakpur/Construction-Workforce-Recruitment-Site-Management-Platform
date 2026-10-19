import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../../features/repositories/company_repository.dart';
import '../company_profile_form_screen.dart';

class CompanyPostJobSheet extends StatefulWidget {
  final Map<String, dynamic>? myProfile;
  final VoidCallback onJobPosted;

  const CompanyPostJobSheet({
    super.key,
    this.myProfile,
    required this.onJobPosted,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic>? myProfile,
    required VoidCallback onJobPosted,
  }) async {
    if (myProfile == null) {
      final shouldSetup = await AppConfirmDialog.show(
        context,
        title: 'Company Profile Required',
        message:
            'You must register your company profile credentials before posting job requirements on the platform.',
        confirmLabel: 'Setup Profile',
        cancelLabel: 'Cancel',
        icon: Icons.business_rounded,
        isDestructive: false,
      );

      if (shouldSetup && context.mounted) {
        final created = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const CompanyProfileFormScreen()),
        );
        if (created == true && context.mounted) {
          onJobPosted();
          try {
            final profiles = await CompanyRepository().getMyProfiles();
            final updatedProfile = profiles.isNotEmpty ? profiles.first : null;
            if (updatedProfile != null && context.mounted) {
              CompanyPostJobSheet.show(
                context,
                myProfile: updatedProfile,
                onJobPosted: onJobPosted,
              );
            }
          } catch (_) {}
        }
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompanyPostJobSheet(
        myProfile: myProfile,
        onJobPosted: onJobPosted,
      ),
    );
  }

  @override
  State<CompanyPostJobSheet> createState() => _CompanyPostJobSheetState();
}

class _CompanyPostJobSheetState extends State<CompanyPostJobSheet> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _compensation = TextEditingController();
  final _skillInput = TextEditingController();
  final _description = TextEditingController();
  final _skillFocusNode = FocusNode();
  final _repo = CompanyRepository();

  int _workersNeeded = 5;
  bool _isPosting = false;
  String? _selectedTradePreset;

  // Predefined trades from Job Seeker screen
  static const List<String> _tradePresets = [
    'Electrician',
    'Plumber',
    'Mason',
    'Carpenter',
    'Painter',
    'Welder',
    'Laborer',
  ];

  // Active skill chips list - starts empty with no prefilled suggestions
  final List<String> _skillsList = [];

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _compensation.dispose();
    _skillInput.dispose();
    _skillFocusNode.dispose();
    _description.dispose();
    super.dispose();
  }

  InputDecoration _cleanDeco(
    String hint, {
    String? counterText,
    TextStyle? hintStyle,
  }) {
    return InputDecoration(
      isDense: true,
      filled: false,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      counterText: counterText,
      hintText: hint,
      hintStyle: hintStyle ??
          const TextStyle(
            fontSize: 15.5,
            color: Color(0xFF98A2B3),
            fontWeight: FontWeight.normal,
          ),
    );
  }

  void _onTradeSelected(String trade) {
    setState(() {
      if (_selectedTradePreset == trade) {
        _selectedTradePreset = null;
      } else {
        _selectedTradePreset = trade;
        _title.text = trade;
      }
    });
  }

  void _autoFillLocation() {
    final companyLoc = widget.myProfile?['address']?.toString() ??
        widget.myProfile?['city']?.toString() ??
        widget.myProfile?['location']?.toString();

    final target = (companyLoc != null && companyLoc.trim().isNotEmpty)
        ? companyLoc.trim()
        : 'Sector 17, Chandigarh';

    setState(() {
      _location.text = target;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Site location set to: $target'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.contains(',')) {
      final parts = trimmed.split(',');
      for (final part in parts) {
        final p = part.trim();
        if (p.isNotEmpty && !_skillsList.contains(p)) {
          setState(() {
            _skillsList.add(p);
          });
        }
      }
      _skillInput.clear();
      _skillFocusNode.requestFocus();
      return;
    }
    if (!_skillsList.contains(trimmed)) {
      setState(() {
        _skillsList.add(trimmed);
        _skillInput.clear();
      });
    } else {
      _skillInput.clear();
    }
    _skillFocusNode.requestFocus();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _location.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job Title and Site Location are required.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      await _repo.createJob({
        'title': _title.text.trim(),
        'location': _location.text.trim(),
        'compensation': num.tryParse(_compensation.text.trim()) ?? 800,
        'workforceRequired': _workersNeeded,
        'skills': () {
          final all = List<String>.from(_skillsList);
          if (_skillInput.text.trim().isNotEmpty) {
            final extra = _skillInput.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
            for (final s in extra) {
              if (!all.contains(s)) all.add(s);
            }
          }
          return all;
        }(),
        'description': _description.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job requirement published successfully!'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onJobPosted();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      final errStr = e.toString();
      if (errStr.contains('Company profile not found')) {
        Navigator.pop(context);
        final shouldSetup = await AppConfirmDialog.show(
          context,
          title: 'Company Profile Required',
          message:
              'Please complete your company profile details before posting job requirements.',
          confirmLabel: 'Setup Profile',
          cancelLabel: 'Cancel',
          icon: Icons.business_rounded,
          isDestructive: false,
        );
        if (shouldSetup && context.mounted) {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CompanyProfileFormScreen()),
          );
          if (created == true && context.mounted) {
            widget.onJobPosted();
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Posting failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag pill
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D5DD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Title Header Row with Close 'X'
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Post New Job Requirement',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF101828),
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Find the right workers for your site',
                            style: TextStyle(
                              fontSize: 15.5,
                              color: Color(0xFF667085),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Color(0xFF101828), size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Predefined trade chips from Job Seeker screen
              SizedBox(
                height: 34,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _tradePresets.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final trade = _tradePresets[index];
                    final isSelected = _selectedTradePreset == trade ||
                        _title.text.trim().toLowerCase() == trade.toLowerCase();
                    return InkWell(
                      onTap: () => _onTradeSelected(trade),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF4ED) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFEAECF0),
                            width: isSelected ? 1.4 : 1.1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            trade,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : const Color(0xFF475467),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Scrollable Form Body
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Job Title Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEAECF0), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.work_outline_rounded, color: Color(0xFF344054), size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      text: 'Job Title ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475467),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '*',
                                          style: TextStyle(
                                            color: Color(0xFFF95724),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  TextField(
                                    controller: _title,
                                    onChanged: (val) {
                                      if (_selectedTradePreset != null &&
                                          val.trim().toLowerCase() != _selectedTradePreset!.toLowerCase()) {
                                        setState(() => _selectedTradePreset = null);
                                      }
                                    },
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF101828),
                                    ),
                                    decoration: _cleanDeco('e.g. Electrician, Painter, Helper'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Location / Site Card with Peach GPS Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEAECF0), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFF344054), size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      text: 'Location / Site ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475467),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '*',
                                          style: TextStyle(
                                            color: Color(0xFFF95724),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  TextField(
                                    controller: _location,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF101828),
                                    ),
                                    decoration: _cleanDeco('e.g. Sector 17, Chandigarh'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _autoFillLocation,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4ED),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFFD9C7), width: 1),
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Daily Pay (₹) & Workers Needed (2 Column Row)
                      Row(
                        children: [
                          // Daily Pay
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFEAECF0), width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    '₹',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF344054),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Daily Pay (₹)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF475467),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        TextField(
                                          controller: _compensation,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF101828),
                                          ),
                                          decoration: _cleanDeco('e.g. 800'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Workers Needed
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFEAECF0), width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.people_outline_rounded, color: Color(0xFF344054), size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Workers Needed',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF475467),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '$_workersNeeded',
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF101828),
                                              ),
                                            ),
                                            const Spacer(),
                                            // Minus button
                                            InkWell(
                                              onTap: () {
                                                if (_workersNeeded > 1) {
                                                  setState(() => _workersNeeded--);
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(14),
                                              child: Container(
                                                width: 26,
                                                height: 26,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFF2F4F7),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.remove,
                                                  size: 15,
                                                  color: Color(0xFF475467),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Plus button
                                            InkWell(
                                              onTap: () => setState(() => _workersNeeded++),
                                              borderRadius: BorderRadius.circular(14),
                                              child: Container(
                                                width: 26,
                                                height: 26,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 15,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 4. Skills Required Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEAECF0), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.handyman_outlined, color: Color(0xFF344054), size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Skills Required',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475467),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  TextField(
                                    controller: _skillInput,
                                    focusNode: _skillFocusNode,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (val) => _addSkill(val),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF101828),
                                    ),
                                    decoration: _cleanDeco('e.g. Electrical work, Wiring, Installation'),
                                  ),
                                ],
                              ),
                            ),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _skillInput,
                              builder: (context, value, _) {
                                if (value.text.trim().isEmpty) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _addSkill(_skillInput.text),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_skillsList.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skillsList.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4ED),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFFD9C7),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    skill,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFF95724),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _skillsList.remove(skill);
                                      });
                                    },
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // 5. Job Description & Site Requirements Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEAECF0), width: 1.2),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.description_outlined, color: Color(0xFF344054), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Job Description & Site Requirements',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475467),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _description,
                                    maxLines: 3,
                                    maxLength: 500,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFF101828),
                                    ),
                                    decoration: _cleanDeco(
                                      'Describe the job, work hours, site details, requirements, safety guidelines, etc.',
                                      counterText: '',
                                      hintStyle: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF98A2B3),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _description,
                                      builder: (context, val, _) {
                                        return Text(
                                          '${val.text.length}/500',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF98A2B3),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 6. Publish Requirement Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isPosting ? null : _submit,
                          child: _isPosting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Publish Requirement',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
