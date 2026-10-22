import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class TradeFilterBar extends StatelessWidget {
  final List<String> tradeList;
  final String? selectedTrade;
  final ValueChanged<String?> onTradeSelected;

  const TradeFilterBar({
    super.key,
    required this.tradeList,
    required this.selectedTrade,
    required this.onTradeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Browse by Trade',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tradeList.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final trade = tradeList[i];
              final isAll = trade == 'All';
              final isSelected =
                  isAll ? (selectedTrade == null) : (selectedTrade == trade);

              return InkWell(
                onTap: () {
                  if (isAll) {
                    onTradeSelected(null);
                  } else {
                    onTradeSelected(isSelected ? null : trade);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    trade,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.dark,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
