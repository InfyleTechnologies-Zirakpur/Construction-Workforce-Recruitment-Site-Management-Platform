import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final IconData icon;
  final bool isDestructive;
  final bool? isCompany;
  final Color? confirmColor;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.icon = Icons.info_outline_rounded,
    this.isDestructive = false,
    this.isCompany,
    this.confirmColor,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String? cancelLabel = 'Cancel',
    IconData icon = Icons.info_outline_rounded,
    bool isDestructive = false,
    bool? isCompany,
    Color? confirmColor,
  }) async {
    final callerTheme = Theme.of(context);
    final isCompanyTheme = isCompany ??
        (callerTheme.primaryColor.toARGB32() == AppColors.companyPrimary.toARGB32());

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Theme(
        data: callerTheme,
        child: AppConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          icon: icon,
          isDestructive: isDestructive,
          isCompany: isCompanyTheme,
          confirmColor: confirmColor,
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = math.min(screenWidth - 48, 380.0);

    final themePrimary = Theme.of(context).primaryColor;
    final isComp = isCompany ?? (themePrimary.toARGB32() == AppColors.companyPrimary.toARGB32());

    final primaryColor = confirmColor ?? (isComp ? AppColors.companyPrimary : AppColors.primary);
    final bgTagColor = isComp ? AppColors.companyTagBackground : AppColors.peachBackground;

    final activeIconBg = isComp
        ? AppColors.companyTagBackground
        : (isDestructive ? AppColors.error.withValues(alpha: 0.12) : bgTagColor);
    final activeIconColor = isComp
        ? AppColors.companyPrimary
        : (isDestructive ? AppColors.error : primaryColor);
    final activeConfirmBtnBg = isComp
        ? AppColors.companyPrimary
        : (isDestructive ? AppColors.error : primaryColor);

    final cardBgColor = isComp ? AppColors.companyTagBackground : AppColors.peachBackground;
    final cardBorderColor = isComp ? AppColors.companyTagBorder : AppColors.peachBorder;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: cardBorderColor,
                  width: 1.2,
                ),
              ),
              child: Icon(
                icon,
                color: activeIconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.dark.withValues(alpha: 0.75),
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            if (cancelLabel != null && cancelLabel!.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.dark,
                          side: BorderSide(
                            color: cardBorderColor,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelLabel!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeConfirmBtnBg,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeConfirmBtnBg,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
