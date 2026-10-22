import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Optional tags and location card for CreateFeedScreen.
class CreatePostTagsCard extends StatelessWidget {
  final bool showTitleField;
  final bool showLocationField;
  final VoidCallback onToggleTitle;
  final VoidCallback onToggleLocation;
  final TextEditingController titleController;
  final TextEditingController locationController;

  const CreatePostTagsCard({
    super.key,
    required this.showTitleField,
    required this.showLocationField,
    required this.onToggleTitle,
    required this.onToggleLocation,
    required this.titleController,
    required this.locationController,
    this.isCompany = false,
  });

  final bool isCompany;

  Color get _primary => isCompany ? AppColors.companyPrimary : AppColors.primary;
  Color get _chipBg => isCompany ? AppColors.companyTagBackground : AppColors.peachBackground;

  InputDecoration _inputDeco({required String hint, String? label, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: _primary) : null,
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
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _chipBg : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primary : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : icon,
              size: 16,
              color: isSelected ? _primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
          Row(
            children: [
              Icon(Icons.sell_outlined, size: 18, color: _primary),
              const SizedBox(width: 8),
              const Text(
                'Optional Tags & Location',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tag a role or site location to help nearby workers find your post',
            style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _toggleChip(
                label: showTitleField ? 'Role Tagged' : 'Tag Role / Job',
                isSelected: showTitleField,
                icon: Icons.work_outline,
                onTap: onToggleTitle,
              ),
              _toggleChip(
                label: showLocationField ? 'Location Tagged' : 'Tag Site Location',
                isSelected: showLocationField,
                icon: Icons.location_on_outlined,
                onTap: onToggleLocation,
              ),
            ],
          ),
          if (showTitleField) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: titleController,
              decoration: _inputDeco(
                hint: 'e.g. Electricians & Site Supervisors',
                label: 'Tagged Role / Trade',
                prefixIcon: Icons.work_outline,
              ),
            ),
          ],
          if (showLocationField) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: locationController,
              decoration: _inputDeco(
                hint: 'e.g. Mohali Sector 82 / Greater Noida Site',
                label: 'Site Location',
                prefixIcon: Icons.location_on_outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
