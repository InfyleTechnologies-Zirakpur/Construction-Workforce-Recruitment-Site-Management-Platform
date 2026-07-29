import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/search/hero_search_bar.dart';

/// Opened by tapping the home hero's search bar. The search field itself
/// [Hero]-morphs in from the home screen; location + quick filters live
/// only here, revealed after the transition lands.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _roleFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();

  static const List<String> _popularSearches = [
    'Electrician',
    'Plumber',
    'Mason',
    'Carpenter',
    'Crane Operator',
    'Site Supervisor',
  ];

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _roleFocus.requestFocus();
  });
  _locationFocus.addListener(() => setState(() {}));
}

@override
void dispose() {
  _roleController.dispose();
  _locationController.dispose();
  _roleFocus.dispose();
  _locationFocus.dispose(); // add this
  super.dispose();
}

  void _applyQuickSearch(String term) {
    _roleController.text = term;
    _roleController.selection = TextSelection.collapsed(offset: term.length);
  }

  void _handleSearch() {
    // TODO: wire up to your real jobs search/filter call.
    Navigator.of(context).pop({
      'role': _roleController.text.trim(),
      'location': _locationController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Search Jobs',
          style: textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero-matched field — same tag as the home hero search bar.
              HeroSearchBar(
                readOnly: false,
                autofocus: false,
                controller: _roleController,
                focusNode: _roleFocus,
                hintText: 'Trade, role, or keyword',
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _locationController,
                  focusNode: _locationFocus,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.location_on_outlined, color: AppColors.primary),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    hintText: 'City or site location',
                    hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black38),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (_locationFocus.hasFocus) ...[
                  const SizedBox(height: 12),
                  Row(
                    spacing: 10,
                    children: [
                      Icon(Icons.location_searching, color: AppColors.primary),
                      Text(
                        'use current location',
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              const SizedBox(height: 28),
              Text('Popular Searches', style: textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularSearches
                    .map(
                      (term) => GestureDetector(
                        onTap: () => _applyQuickSearch(term),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            term,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12.5,
                              color: AppColors.dark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSearch,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Search Jobs',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
