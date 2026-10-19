import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CompleteProfileTradeGrid extends StatelessWidget {
  final List<Map<String, dynamic>> tradeOptions;
  final String selectedTrade;
  final ValueChanged<String> onTradeSelected;

  const CompleteProfileTradeGrid({
    super.key,
    required this.tradeOptions,
    required this.selectedTrade,
    required this.onTradeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tradeOptions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemBuilder: (context, index) {
        final trade = tradeOptions[index];
        final name = (trade['name'] ?? '').toString();
        final specialty = (trade['specialty'] ?? '').toString();
        final icon = trade['icon'] as IconData? ?? Icons.handyman_rounded;
        final isSelected = selectedTrade == name;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTradeSelected(name),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.peachBackground : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.peachBackground,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      icon,
                      size: 19,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                            color: isSelected ? const Color(0xFF9A3412) : AppColors.dark,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialty,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
