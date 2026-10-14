import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../features/bloc/worker_blocs.dart';
import '../../notifications/notifications_screen.dart';

class CompanyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProfileTap;
  final String? logoUrl;
  final String? companyName;
  final bool showBackButton;
  final bool showNotifications;
  final bool showProfileAvatar;

  const CompanyAppBar({
    super.key,
    this.onProfileTap,
    this.logoUrl,
    this.companyName,
    this.showBackButton = false,
    this.showNotifications = true,
    this.showProfileAvatar = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  Widget _buildFallbackAvatar() {
    if (companyName != null && companyName!.trim().isNotEmpty) {
      return Center(
        child: Text(
          companyName!.trim()[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return const Icon(
      Icons.account_circle_outlined,
      color: AppColors.dark,
      size: 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValidLogo = logoUrl != null &&
        logoUrl!.trim().isNotEmpty &&
        logoUrl!.trim().startsWith('http');

    return AppBar(
      backgroundColor: AppColors.card,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: showBackButton ? 0 : 16,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.dark, size: 19),
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Flow',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Hire',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Workforce Recruitment',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        if (showNotifications)
          BlocBuilder<NotificationsCubit, LoadState<List<WorkerNotification>>>(
            builder: (context, state) {
              final hasUnread = state is Loaded<List<WorkerNotification>> &&
                  state.data.any((n) => !n.isRead);

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.dark,
                        size: 24,
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        if (showProfileAvatar)
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 16),
            child: Center(
              child: InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.peachBackground,
                    border: Border.all(color: AppColors.peachBorder, width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasValidLogo
                      ? Image.network(
                          logoUrl!.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
                        )
                      : _buildFallbackAvatar(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
