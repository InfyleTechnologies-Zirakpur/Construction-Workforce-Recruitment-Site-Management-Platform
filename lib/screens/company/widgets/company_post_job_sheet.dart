import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/repositories/company_repository.dart';
import '../company_profile_form_screen.dart';

class CompanyPostJobSheet extends StatefulWidget {
  final VoidCallback onJobPosted;

  const CompanyPostJobSheet({super.key, required this.onJobPosted});

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic>? myProfile,
    required VoidCallback onJobPosted,
  }) async {
    if (myProfile == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Company Profile Required', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark)),
          content: const Text(
            'You must register your company profile credentials before posting job requirements on the platform.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompanyProfileFormScreen()),
                ).then((_) => onJobPosted());
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Setup Profile', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CompanyPostJobSheet(onJobPosted: onJobPosted),
    );
  }

  @override
  State<CompanyPostJobSheet> createState() => _CompanyPostJobSheetState();
}

class _CompanyPostJobSheetState extends State<CompanyPostJobSheet> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _compensation = TextEditingController();
  final _workforce = TextEditingController(text: '5');
  final _skills = TextEditingController();
  final _description = TextEditingController();
  final _repo = CompanyRepository();
  bool _isPosting = false;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _compensation.dispose();
    _workforce.dispose();
    _skills.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _location.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and location are required.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      await _repo.createJob({
        'title': _title.text.trim(),
        'location': _location.text.trim(),
        'compensation': num.tryParse(_compensation.text.trim()) ?? 1000,
        'workforceRequired': int.tryParse(_workforce.text.trim()) ?? 1,
        'skills': _skills.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'description': _description.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job requirements posted successfully!'), backgroundColor: Colors.green),
        );
        widget.onJobPosted();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      final errStr = e.toString();
      if (errStr.contains('Company profile not found')) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete your company profile first.'), backgroundColor: Colors.orange),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompanyProfileFormScreen()),
        ).then((_) => widget.onJobPosted());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Posting failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Post New Job Requirement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Job Title *', hintText: 'e.g. Senior Site Mason')),
              const SizedBox(height: 10),
              TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location / Site *', hintText: 'e.g. Mohali Sector 82')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _compensation,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Daily Pay (₹)', prefixText: '₹ '),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _workforce,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Workers Needed'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: _skills, decoration: const InputDecoration(labelText: 'Skills Required', hintText: 'Masonry, Formwork, Plastering')),
              const SizedBox(height: 10),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Job Description & Site Requirements'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isPosting ? null : _submit,
                  child: _isPosting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Publish Requirement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
