import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CompleteProfileHeroCard extends StatelessWidget {
  final String displayName;
  final String displayCity;
  final String phoneNumber;
  final String selectedTrade;
  final Uint8List? photoBytes;
  final bool isUploadingPhoto;
  final VoidCallback onPickPhoto;

  const CompleteProfileHeroCard({
    super.key,
    required this.displayName,
    required this.displayCity,
    required this.phoneNumber,
    required this.selectedTrade,
    required this.photoBytes,
    required this.isUploadingPhoto,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final name = displayName.trim().isEmpty ? 'Your Full Name' : displayName.trim();
    final location = displayCity.trim().isEmpty ? 'Preferred Location' : displayCity.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.peachBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.peachBorder,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dynamic Photo Avatar with Camera Button
          GestureDetector(
            onTap: isUploadingPhoto ? null : onPickPhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.peachBorder,
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    backgroundImage: photoBytes != null ? MemoryImage(photoBytes!) : null,
                    child: photoBytes == null
                        ? Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'W',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: isUploadingPhoto
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // User Details Preview
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.peachBorder,
                            width: 0.9,
                          ),
                        ),
                        child: Text(
                          selectedTrade,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.peachText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Phone verified badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF86EFAC),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 12,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phoneNumber.startsWith('+') ? phoneNumber : '+91 $phoneNumber',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
