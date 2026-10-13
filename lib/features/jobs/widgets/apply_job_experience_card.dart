import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Card widget handling Experienced vs Fresher toggle and input fields.
class ApplyJobExperienceCard extends StatelessWidget {
  final bool hasExperience;
  final ValueChanged<bool> onExperienceChanged;
  final TextEditingController companyController;
  final TextEditingController roleController;
  final TextEditingController yearsController;
  final TextEditingController trainingController;

  const ApplyJobExperienceCard({
    super.key,
    required this.hasExperience,
    required this.onExperienceChanged,
    required this.companyController,
    required this.roleController,
    required this.yearsController,
    required this.trainingController,
  });

  InputDecoration _inputDeco({required String hint, String? label}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _experienceToggle() {
    Widget option(String label, bool value, IconData icon) {
      final isSelected = hasExperience == value;
      return Expanded(
        child: InkWell(
          onTap: () => onExperienceChanged(value),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.peachBackground : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : icon,
                  size: 16,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option('Experienced', true, Icons.workspace_premium_outlined),
        const SizedBox(width: 10),
        option('Fresher', false, Icons.school_outlined),
      ],
    );
  }

  Widget _experienceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: companyController,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Please enter your previous company' : null,
          decoration: _inputDeco(hint: 'e.g. L&T Construction', label: 'Previous Company Name'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: roleController,
          decoration: _inputDeco(hint: 'e.g. Site Electrician / Supervisor', label: 'Trade / Role'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: yearsController,
          keyboardType: TextInputType.number,
          decoration: _inputDeco(hint: 'e.g. 3', label: 'Years of Experience'),
        ),
      ],
    );
  }

  Widget _fresherFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.peachBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.peachBorder, width: 0.8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No previous experience required for this role. You can list any training, courses, or certificates below.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.dark, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: trainingController,
          maxLines: 3,
          decoration: _inputDeco(
            hint: 'e.g. ITI Electrician certificate, 3-month site safety workshop',
            label: 'Training / Certifications (optional)',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Row(
            children: [
              Icon(Icons.work_history_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Your Experience',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Let the employer know your site background',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _experienceToggle(),
          const SizedBox(height: 14),
          if (hasExperience) _experienceFields() else _fresherFields(),
        ],
      ),
    );
  }
}
