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
                        color: AppColors.peachBorder,
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      backgroundImage: profile.profilePhotoUrl != null &&
                              profile.profilePhotoUrl!.isNotEmpty
                          ? NetworkImage(profile.profilePhotoUrl!)
                          : null,
                      child: (profile.profilePhotoUrl == null ||
                              profile.profilePhotoUrl!.isEmpty)
                          ? const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: AppColors.primary,
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
                            border: Border.all(color: Colors.white, width: 2),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.peachBorder,
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              primaryTrade,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isKycVerified
                                ? const Color(0xFFDCFCE7)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isKycVerified
                                  ? const Color(0xFF86EFAC)
                                  : AppColors.peachBorder,
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
                                    ? const Color(0xFF16A34A)
                                    : AppColors.peachText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isKycVerified ? 'Verified' : 'Pending',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isKycVerified
                                      ? const Color(0xFF15803D)
                                      : AppColors.peachText,
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
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              profile.city,
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
                  ],
                ),
              ),
            ],
          ),
          if (isUploadingPhoto) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.peachBorder,
                  width: 0.8,
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Uploading your profile photo...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
