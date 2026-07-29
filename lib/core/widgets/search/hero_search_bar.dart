import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// The search field used on the home hero AND on [SearchScreen] — the two
/// share a [Hero] tag so tapping one morphs smoothly into the other.
///
/// On home it's `readOnly` (a tap target, not an editable field — no
/// keyboard pops up, `onTap` handles navigation). On the search screen it's
/// a real, focused, editable [TextField].
class HeroSearchBar extends StatelessWidget {
  final String heroTag;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final bool autofocus;

  const HeroSearchBar({
    super.key,
    this.heroTag = 'search-bar',
    this.readOnly = true,
    this.onTap,
    this.controller,
    this.focusNode,
    this.hintText = 'Trade, role, or keyword',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.15),
            //     blurRadius: 12,
            //     offset: const Offset(0, 6),
            //   ),
            // ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: readOnly,
            showCursor: !readOnly,
            autofocus: autofocus,
            onTap: onTap,
            style: textTheme.bodyMedium,
            decoration: InputDecoration(
              icon: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.search, color: AppColors.primary),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              hintText: hintText,
              hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black38),
            ),
          ),
        ),
      ),
    );
  }
}
