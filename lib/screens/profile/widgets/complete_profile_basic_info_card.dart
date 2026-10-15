import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'complete_profile_section_card.dart';

class CompleteProfileBasicInfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController cityController;
  final List<String> citySuggestions;
  final ValueChanged<String> onSelectCity;

  const CompleteProfileBasicInfoCard({
    super.key,
    required this.nameController,
    required this.cityController,
    required this.citySuggestions,
    required this.onSelectCity,
  });

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompleteProfileSectionCard(
      title: 'Basic Information',
      subtitle: 'How contractors identify and locate you on site',
      icon: Icons.person_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Full Name *'),
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.dark,
              fontWeight: FontWeight.w600,
            ),
            decoration: _buildInputDecoration(
              hintText: 'e.g. Ramesh Kumar',
              prefixIcon: Icons.person_outline_rounded,
            ),
            validator: (v) {
              final val = (v ?? '').trim();
              if (val.isEmpty) return 'Please enter your full name';
              if (val.length < 3) return 'Name must be at least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInputLabel('Preferred Working City *'),
          TextFormField(
            controller: cityController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.dark,
              fontWeight: FontWeight.w600,
            ),
            decoration: _buildInputDecoration(
              hintText: 'e.g. Mohali, Chandigarh, Delhi NCR',
              prefixIcon: Icons.location_on_outlined,
            ),
            validator: (v) {
              final val = (v ?? '').trim();
              if (val.isEmpty) return 'Please enter your working location';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: citySuggestions.map((city) {
              final isSelected = cityController.text.trim().toLowerCase() == city.toLowerCase();
              return InkWell(
                onTap: () => onSelectCity(city),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.peachBackground : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        size: 11,
                        color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
