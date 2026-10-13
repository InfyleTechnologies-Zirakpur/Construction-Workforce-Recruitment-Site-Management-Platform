import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';

class ProfileHeaderCard extends StatelessWidget {
  final WorkerProfile profile;
  final bool isUploadingPhoto;
  final VoidCallback onUploadPhoto;
  final bool isKycVerified;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    required this.isUploadingPhoto,
    required this.onUploadPhoto,
    required this.isKycVerified,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTrade = profile.skills.isNotEmpty
        ? profile.skills.first
        : 'Skilled Tradesperson';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: const Color(0xFF1F2937),
                      backgroundImage: profile.profilePhotoUrl != null &&
                              profile.profilePhotoUrl!.isNotEmpty
                          ? NetworkImage(profile.profilePhotoUrl!)
                          : null,
                      child: (profile.profilePhotoUrl == null ||
                              profile.profilePhotoUrl!.isEmpty)
                          ? const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: Colors.white70,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isUploadingPhoto ? null : onUploadPhoto,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.dark, width: 2),
                          ),
                          child: isUploadingPhoto
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                        ),
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
                    Text(
                      profile.name.isNotEmpty ? profile.name : 'Worker',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              primaryTrade,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isKycVerified
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isKycVerified
                                  ? Colors.green.withValues(alpha: 0.5)
                                  : Colors.amber.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isKycVerified
                                    ? Icons.verified_rounded
                                    : Icons.schedule_rounded,
                                size: 12,
                                color: isKycVerified
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFFFBBF24),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isKycVerified ? 'Verified' : 'Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isKycVerified
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFFBBF24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (profile.city.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              profile.city,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Colors.white60,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUploadingPhoto
                        ? 'Uploading your profile photo...'
                        : 'Tap the camera button to upload or change your photo',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
