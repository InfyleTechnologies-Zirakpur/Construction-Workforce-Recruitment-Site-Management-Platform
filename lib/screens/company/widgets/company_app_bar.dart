import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/bloc/worker_blocs.dart';
import '../../notifications/notifications_screen.dart';

class CompanyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProfileTap;
  final String? logoUrl;
  final String? companyName;
  final bool showBackButton;
  final bool showNotifications;
  final bool showProfileAvatar;
  final VoidCallback? onBackPressed;

  const CompanyAppBar({
    super.key,
    this.onProfileTap,
    this.logoUrl,
    this.companyName,
    this.showBackButton = false,
    this.showNotifications = true,
    this.showProfileAvatar = true,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  String? _resolveImageUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'undefined') {
      return null;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final uri = Uri.tryParse(ApiConfig.baseUrl);
    if (uri != null) {
      final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      return trimmed.startsWith('/') ? '$origin$trimmed' : '$origin/$trimmed';
    }
    return trimmed;
  }

  Widget _buildFallbackAvatar() {
    final letter = (companyName != null && companyName!.trim().isNotEmpty)
        ? companyName!.trim()[0].toUpperCase()
        : null;
    return Center(
      child: letter != null
          ? Text(
              letter,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.business_rounded,
              size: 20,
              color: Colors.white,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedLogoUrl = _resolveImageUrl(logoUrl);

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
              onPressed: onBackPressed ?? () => Navigator.maybePop(context),
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
                    color: AppColors.companyPrimary,
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
              fontSize: 14,
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
                      builder: (_) => Theme(
                        data: AppTheme.companyTheme(context),
                        child: const NotificationsScreen(isCompany: true),
                      ),
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
                            color: AppColors.companyPrimary,
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
                    color: AppColors.companyPrimary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.companyPrimary.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: resolvedLogoUrl != null
                      ? Image.network(
                          resolvedLogoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildFallbackAvatar(),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildFallbackAvatar();
                          },
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
