import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/search/job_filters.dart';
import '../../features/search/job_filters_sheet.dart';
import '../home/widgets/home_job_card.dart';
import '../home/widgets/job_details_sheet.dart';

class _RecentSearchItem {
  final String query;
  final String location;

  const _RecentSearchItem({
    required this.query,
    required this.location,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'location': location,
      };

  factory _RecentSearchItem.fromJson(Map<String, dynamic> json) => _RecentSearchItem(
        query: json['query']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
      );
}

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialLocation;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialLocation,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _storageKey = 'job_seeker_search_history';

  late final TextEditingController _jobController;
  late final TextEditingController _locationController;
  final FocusNode _jobFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();

  bool _hasSearched = false;
  bool _showAllRecent = false;
  JobFilters _filters = const JobFilters();
  List<_RecentSearchItem> _recentSearches = [];

  @override
  void initState() {
    super.initState();

    _jobController = TextEditingController(text: widget.initialQuery ?? '');
    _locationController = TextEditingController(text: widget.initialLocation ?? '');

    _jobController.addListener(() => setState(() {}));
    _locationController.addListener(() => setState(() {}));
    _jobFocus.addListener(() => setState(() {}));
    _locationFocus.addListener(() => setState(() {}));

    _loadRecentSearches();

    final jobsCubit = context.read<JobsCubit>();
    if (jobsCubit.state is Idle<List<Job>>) {
      jobsCubit.load();
    }

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _executeSearch();
      });
    }
  }

  @override
  void dispose() {
    _jobController.dispose();
    _locationController.dispose();
    _jobFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          if (!mounted) return;
          setState(() {
            _recentSearches = decoded
                .whereType<Map>()
                .map((m) => _RecentSearchItem.fromJson(Map<String, dynamic>.from(m)))
                .where((item) => item.query.isNotEmpty || item.location.isNotEmpty)
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveRecentSearches() async {
    try {
      final encoded = jsonEncode(_recentSearches.map((e) => e.toJson()).toList());
      await _storage.write(key: _storageKey, value: encoded);
    } catch (_) {}
  }

  void _executeSearch() {
    _jobFocus.unfocus();
    _locationFocus.unfocus();

    final query = _jobController.text.trim();
    final location = _locationController.text.trim();

    if (query.isNotEmpty || location.isNotEmpty) {
      _addRecent(query, location);
    }

    setState(() {
      _hasSearched = true;
    });

    context.read<JobsCubit>().search(
          query: query.isEmpty ? null : query,
          location: location.isEmpty ? null : location,
        );
  }

  void _addRecent(String query, String location) {
    setState(() {
      _recentSearches.removeWhere(
        (item) =>
            item.query.toLowerCase() == query.toLowerCase() &&
            item.location.toLowerCase() == location.toLowerCase(),
      );
      _recentSearches.insert(
        0,
        _RecentSearchItem(query: query, location: location),
      );
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    });
    _saveRecentSearches();
  }

  void _removeRecent(int index) {
    setState(() {
      _recentSearches.removeAt(index);
    });
    _saveRecentSearches();
  }

  void _applyRecentSearch(_RecentSearchItem item) {
    _jobController.text = item.query;
    if (item.location.isNotEmpty) {
      _locationController.text = item.location;
    }
    _executeSearch();
  }

  void _applySuggestedSearch(String term) {
    _jobController.text = term;
    _executeSearch();
  }

  int _computeMatchingJobCount(String query, String location, List<Job> allJobs) {
    final q = query.trim().toLowerCase();
    final loc = location.trim().toLowerCase();
    return allJobs.where((j) {
      final matchesQ = q.isEmpty ||
          j.title.toLowerCase().contains(q) ||
          j.company.toLowerCase().contains(q) ||
          j.skills.any((s) => s.toLowerCase().contains(q));
      final matchesLoc = loc.isEmpty || j.location.toLowerCase().contains(loc);
      return matchesQ && matchesLoc;
    }).length;
  }

  List<String> _getDynamicSuggestions(List<Job> allJobs) {
    final currentInput = _jobController.text.trim().toLowerCase();
    if (currentInput.isEmpty) {
      return const [];
    }

    final Set<String> pool = {};

    for (final job in allJobs) {
      if (job.title.trim().isNotEmpty) pool.add(job.title.trim());
      for (final skill in job.skills) {
        if (skill.trim().isNotEmpty) pool.add(skill.trim());
      }
      if (job.company.trim().isNotEmpty) pool.add(job.company.trim());
    }

    return pool
        .where((term) =>
            term.toLowerCase().contains(currentInput) &&
            term.toLowerCase() != currentInput)
        .take(10)
        .toList();
  }

  List<String> _getDynamicLocations(List<Job> allJobs) {
    final locInput = _locationController.text.trim().toLowerCase();
    if (locInput.isEmpty) {
      return const [];
    }

    final pool = allJobs
        .map((j) => j.location.trim())
        .where((loc) => loc.isNotEmpty)
        .toSet();

    return pool
        .where((loc) =>
            loc.toLowerCase().contains(locInput) &&
            loc.toLowerCase() != locInput)
        .take(6)
        .toList();
  }

  List<Job> _filteredResults(List<Job> jobs) {
    final query = _jobController.text.trim().toLowerCase();
    final location = _locationController.text.trim().toLowerCase();

    return jobs.where((job) {
      final matchesQuery = query.isEmpty ||
          job.title.toLowerCase().contains(query) ||
          job.company.toLowerCase().contains(query) ||
          job.skills.any((skill) => skill.toLowerCase().contains(query));
      final matchesLocation = location.isEmpty || job.location.toLowerCase().contains(location);
      return matchesQuery && matchesLocation && _filters.matches(job);
    }).toList();
  }

  Future<void> _openFilters(List<Job> allJobs) async {
    final result = await showJobFiltersSheet(context, current: _filters, jobsForBounds: allJobs);
    if (result != null && mounted) {
      setState(() => _filters = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _jobFocus.hasFocus || _locationFocus.hasFocus;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<JobsCubit, LoadState<List<Job>>>(
          builder: (context, state) {
            final allJobs = state is Loaded<List<Job>> ? state.data : const <Job>[];
            final isLoadingJobs = state is Loading<List<Job>> || state is Idle<List<Job>>;

            return Column(
              children: [
                // Top Bar with Circular Back button and 2-in-1 Unified Search Container
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _buildTopSearchCard(isFocused),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.border),

                // Content Area: Either Suggestions/Recent OR Search Results
                Expanded(
                  child: _hasSearched && !isFocused
                      ? _buildSearchResults(allJobs, state)
                      : _buildSearchSuggestions(allJobs, isLoadingJobs),
                ),

                // Fixed Bottom Search Pill Button
                _buildBottomSearchButton(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopSearchCard(bool isFocused) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Circular back button
        Material(
          color: const Color(0xFFF2F4F7),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (_hasSearched && !isFocused) {
                setState(() => _hasSearched = false);
              } else {
                Navigator.maybePop(context);
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(Icons.arrow_back, color: AppColors.dark, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Unified 2-in-1 Rounded Container in Job Seeker Theme
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused ? AppColors.primary : const Color(0xFFD0D5DD),
                width: isFocused ? 2.0 : 1.2,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Job title, keywords or company
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 20, color: AppColors.dark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _jobController,
                          focusNode: _jobFocus,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _locationFocus.requestFocus(),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Job title, keywords or company',
                            hintStyle: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textMuted,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            suffixIcon: _jobController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _jobController.clear();
                                      setState(() {});
                                    },
                                    child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                                  )
                                : null,
                            suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider line between job and location
                const Divider(height: 1, thickness: 1, color: AppColors.border),

                // Row 2: Location
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20, color: AppColors.dark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          focusNode: _locationFocus,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _executeSearch(),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'City, state or site location',
                            hintStyle: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textMuted,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            suffixIcon: _locationController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _locationController.clear();
                                      setState(() {});
                                    },
                                    child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                                  )
                                : null,
                            suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions(List<Job> allJobs, bool isLoadingJobs) {
    final isTypingJob = _jobController.text.trim().isNotEmpty;
    final isTypingLocation = _locationController.text.trim().isNotEmpty;
    final isTyping = isTypingJob || isTypingLocation;

    final recentToShow = _showAllRecent ? _recentSearches : _recentSearches.take(3).toList();
    final dynamicSuggestions = isTypingJob ? _getDynamicSuggestions(allJobs) : const <String>[];
    final dynamicLocations = isTypingLocation ? _getDynamicLocations(allJobs) : const <String>[];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. If typing in location field, show matching location suggestions
        if (isTypingLocation && dynamicLocations.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Matching Locations',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...dynamicLocations.map((loc) {
            return InkWell(
              onTap: () {
                _locationController.text = loc;
                _executeSearch();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.dark, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 10),
        ],

        // 2. If typing in job field, show matching related suggestions ONLY
        if (isTypingJob && dynamicSuggestions.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Matching Roles & Skills',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...dynamicSuggestions.map((term) {
            return InkWell(
              onTap: () => _applySuggestedSearch(term),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppColors.dark,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        term,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        // 3. When NOT typing, show user's Recent Searches (if any)
        if (!isTyping && _recentSearches.isNotEmpty) ...[
          ...List.generate(recentToShow.length, (index) {
            final item = recentToShow[index];
            final matchingCount = _computeMatchingJobCount(item.query, item.location, allJobs);

            return InkWell(
              onTap: () => _applyRecentSearch(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.dark,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.query.isNotEmpty ? item.query : item.location,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              children: [
                                TextSpan(
                                  text: '$matchingCount active',
                                  style: const TextStyle(
                                    color: AppColors.peachText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.location.isNotEmpty)
                                  TextSpan(text: ' in ${item.location}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () => _removeRecent(index),
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            );
          }),

          // "More recent searches" link button
          if (_recentSearches.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showAllRecent = !_showAllRecent;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      _showAllRecent ? 'Fewer recent searches' : 'More recent searches',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.peachText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],

        // 4. When NOT typing and NO recent searches, show clean idle state
        if (!isTyping && _recentSearches.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.peachBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Search open positions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter job title, trades, required skills, or city above to find opportunities.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResults(List<Job> allJobs, LoadState<List<Job>> state) {
    if (state is Loading<List<Job>>) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      );
    }

    if (state is Failed<List<Job>>) {
      return _errorState(context);
    }

    final results = _filteredResults(allJobs);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _executeSearch();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          // Results Header with Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${results.length} jobs found',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openFilters(allJobs),
                icon: const Icon(Icons.tune, size: 16),
                label: Text(_filters.activeCount == 0 ? 'Filters' : 'Filters (${_filters.activeCount})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _filters.activeCount == 0 ? AppColors.dark : AppColors.peachText,
                  side: BorderSide(
                    color: _filters.activeCount == 0 ? AppColors.border : AppColors.peachBorder,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (results.isEmpty)
            _noResults(context)
          else
            ...results.map(
              (job) => HomeJobCard(
                job: job,
                margin: const EdgeInsets.only(bottom: 14),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => JobDetailsSheet(job: job),
                  );
                },
                onSaveToggle: () {
                  if (job.saved) {
                    context.read<JobsCubit>().unsave(job.id);
                  } else {
                    context.read<JobsCubit>().save(job.id);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSearchButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _executeSearch,
          icon: const Icon(Icons.search, color: Colors.white, size: 20),
          label: const Text(
            'Search',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 1.5,
            shadowColor: AppColors.primary.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Unable to load jobs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please check your network connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _executeSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noResults(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, color: AppColors.primary, size: 48),
          const SizedBox(height: 14),
          const Text(
            'No matching jobs found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try checking spelling or using different keywords or location.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () {
              _jobController.clear();
              _locationController.clear();
              setState(() {
                _filters = const JobFilters();
                _hasSearched = false;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dark,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clear and Try Again'),
          ),
        ],
      ),
    );
  }
}