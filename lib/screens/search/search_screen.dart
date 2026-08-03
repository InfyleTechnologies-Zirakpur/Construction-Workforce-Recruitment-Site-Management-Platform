import 'dart:async';

import 'package:construction_workforce_recruitment_site_management_platform/features/jobs/apply_job_screen.dart';
import 'package:construction_workforce_recruitment_site_management_platform/features/search/job_filters.dart';
import 'package:construction_workforce_recruitment_site_management_platform/features/search/job_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/search/hero_search_bar.dart';
import '../../features/bloc/worker_blocs.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _jobController = TextEditingController();
  final _locationController = TextEditingController();
  final _jobFocus = FocusNode();
  final _locationFocus = FocusNode();
  Timer? _debounce;
  bool _isSearching = false;
  String _query = '';
  String _location = '';
  JobFilters _filters = const JobFilters();

  static const _locations = ['Bathinda, Punjab', 'Chandigarh', 'Ludhiana', 'Mohali', 'Patiala'];

  @override
  void initState() {
    super.initState();
    _jobController.addListener(_onJobChanged);
    _locationController.addListener(() => setState(() {}));
    _locationFocus.addListener(() => setState(() {}));

    final jobsCubit = context.read<JobsCubit>();
    if (jobsCubit.state is Idle<List<Job>>) jobsCubit.load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _jobController.dispose();
    _locationController.dispose();
    _jobFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  void _onJobChanged() {
    _debounce?.cancel();
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _query = _jobController.text.trim();
        _isSearching = false;
      });
    });
  }

  List<Job> _filteredResults(List<Job> jobs) {
    final query = _query.toLowerCase();
    final location = _location.toLowerCase();
    return jobs.where((job) {
      final matchesQuery = query.isEmpty ||
          job.title.toLowerCase().contains(query) ||
          job.company.toLowerCase().contains(query) ||
          job.skills.any((skill) => skill.toLowerCase().contains(query));
      final matchesLocation = location.isEmpty || job.location.toLowerCase().contains(location);
      return matchesQuery && matchesLocation && _filters.matches(job);
    }).toList();
  }

  void _selectLocation(String location) {
    setState(() {
      _location = location;
      _locationController.text = location;
      _locationController.selection = TextSelection.collapsed(offset: location.length);
    });
    _locationFocus.unfocus();
  }

  void _useCurrentLocation() {
    // Replace this with geolocator permission + reverse geocoding later.
    _selectLocation('Bathinda, Punjab');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Using your current location: Bathinda, Punjab')),
    );
  }

  Future<void> _openFilters(List<Job> allJobs) async {
    final result = await showJobFiltersSheet(context, current: _filters, jobsForBounds: allJobs);
    if (result != null && mounted) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final matchingLocations = _locations.where((city) => city.toLowerCase().contains(_locationController.text.trim().toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Find jobs', style: textTheme.titleMedium?.copyWith(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: BlocBuilder<JobsCubit, LoadState<List<Job>>>(
              builder: (context, state) {
                final allJobs = state is Loaded<List<Job>> ? state.data : const <Job>[];
                final isLoadingJobs = state is Idle<List<Job>> || state is Loading<List<Job>>;
                final results = _filteredResults(allJobs);

                return ListView(
                  padding: EdgeInsets.fromLTRB(context.w(20), context.h(18), context.w(20), context.h(28)),
                  children: [
                    HeroSearchBar(
                      controller: _jobController,
                      focusNode: _jobFocus,
                      readOnly: false,
                      autofocus: false,
                      hintText: 'Trade, role, company, or skill',
                    ),
                    SizedBox(height: context.h(12)),
                    TextField(
                      controller: _locationController,
                      focusNode: _locationFocus,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'City or site location',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                        suffixIcon: _location.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.close), onPressed: () { setState(() { _location = ''; _locationController.clear(); }); })
                            : null,
                      ),
                    ),
                    if (_locationFocus.hasFocus) ...[
                      SizedBox(height: context.h(10)),
                      _locationPanel(context, matchingLocations, textTheme),
                    ],
                    SizedBox(height: context.h(12)),
                    _filtersRow(context, allJobs, textTheme),
                    SizedBox(height: context.h(16)),
                    Row(
                      children: [
                        Expanded(child: Text(_query.isEmpty && _filters.isEmpty ? 'Recommended jobs' : 'Search results', style: textTheme.titleMedium)),
                        if (_isSearching || isLoadingJobs) const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        if (!_isSearching && !isLoadingJobs) Text('${results.length} jobs', style: textTheme.bodySmall),
                      ],
                    ),
                    SizedBox(height: context.h(10)),
                    if (isLoadingJobs)
                      const SizedBox()
                    else if (state is Failed<List<Job>>)
                      _errorState(context, textTheme)
                    else if (!_isSearching && results.isEmpty)
                      _noResults(context, textTheme)
                    else
                      ...results.map((job) => _SearchJobCard(job: job)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _filtersRow(BuildContext context, List<Job> allJobs, TextTheme textTheme) {
    final activeCount = _filters.activeCount;
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _openFilters(allJobs),
          icon: const Icon(Icons.tune, size: 18),
          label: Text(activeCount == 0 ? 'Filters' : 'Filters ($activeCount)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: activeCount == 0 ? Colors.black87 : AppColors.primary,
            side: BorderSide(color: activeCount == 0 ? AppColors.border : AppColors.primary),
          ),
        ),
        if (activeCount > 0) ...[
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => setState(() => _filters = const JobFilters()),
            child: const Text('Clear filters'),
          ),
        ],
      ],
    );
  }

  Widget _locationPanel(BuildContext context, List<String> cities, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        ListTile(leading: const Icon(Icons.my_location, color: AppColors.primary), title: Text('Use current location', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)), subtitle: const Text('Find jobs near you'), onTap: _useCurrentLocation),
        if (cities.isNotEmpty) const Divider(height: 1),
        ...cities.map((city) => ListTile(leading: const Icon(Icons.location_city_outlined), title: Text(city), onTap: () => _selectLocation(city))),
        if (cities.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No matching locations found')),
      ]),
    );
  }

  Widget _errorState(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.h(42), horizontal: context.w(24)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 46),
        const SizedBox(height: 12),
        Text('Unable to load jobs', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () => context.read<JobsCubit>().load(), child: const Text('Retry')),
      ]),
    );
  }

  Widget _noResults(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.h(42), horizontal: context.w(24)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        const Icon(Icons.search_off_outlined, color: AppColors.primary, size: 46),
        const SizedBox(height: 12),
        Text('No jobs found', style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Try a different role, skill, city, or filters.', textAlign: TextAlign.center, style: textTheme.bodySmall),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () {
            _jobController.clear();
            _locationController.clear();
            setState(() {
              _query = '';
              _location = '';
              _filters = const JobFilters();
            });
          },
          child: const Text('Clear search'),
        ),
      ]),
    );
  }
}

class _SearchJobCard extends StatelessWidget {
  const _SearchJobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(context.w(15)),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            height: context.w(44),
            width: context.w(44),
            decoration: BoxDecoration(color: AppColors.dark.withOpacity(.08), borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.business_outlined, color: AppColors.dark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.title, style: textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(job.company, style: textTheme.bodySmall),
            ]),
          ),
          IconButton(
            onPressed: () => context.read<JobsCubit>().save(job.id),
            icon: Icon(
              job.saved ? Icons.bookmark : Icons.bookmark_border,
              color: job.saved ? AppColors.primary : Colors.black54,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 14, runSpacing: 7, children: [
          _line(Icons.location_on_outlined, job.location),
          _line(Icons.payments_outlined, '₹${job.dailyPay}/day'),
          _line(Icons.work_outline, job.projectType),
        ]),
        if (job.skills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: job.skills.map((tag) => Chip(label: Text(tag, style: textTheme.bodySmall), visualDensity: VisualDensity.compact)).toList()),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: job.applied
              ? OutlinedButton(onPressed: null, child: const Text('Already Applied'))
              : FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ApplyJobScreen(job: job)),
                    );
                  },
                  child: const Text('Apply Now'),
                ),
        ),
      ]),
    );
  }

  Widget _line(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.black45), const SizedBox(width: 4), Text(text)]);
}