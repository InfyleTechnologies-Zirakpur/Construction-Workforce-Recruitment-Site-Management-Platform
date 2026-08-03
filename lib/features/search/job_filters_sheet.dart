import 'package:construction_workforce_recruitment_site_management_platform/features/search/job_filters.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';

/// Shows the filter sheet and returns the chosen [JobFilters], or null if
/// the user dismissed it without applying.
Future<JobFilters?> showJobFiltersSheet(
  BuildContext context, {
  required JobFilters current,
  required List<Job> jobsForBounds,
}) {
  return showModalBottomSheet<JobFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _JobFiltersSheet(current: current, jobs: jobsForBounds),
  );
}

class _JobFiltersSheet extends StatefulWidget {
  const _JobFiltersSheet({required this.current, required this.jobs});
  final JobFilters current;
  final List<Job> jobs;

  @override
  State<_JobFiltersSheet> createState() => _JobFiltersSheetState();
}

class _JobFiltersSheetState extends State<_JobFiltersSheet> {
  static const _projectTypeOptions = ['Full-time', 'Contract', 'Daily Wage'];
  static const _experienceOptions = ['Fresher', 'Experienced'];

  late int _boundsMin;
  late int _boundsMax;
  late RangeValues _salaryRange;
  late Set<String> _skills;
  late Set<String> _projectTypes;
  late Set<String> _experienceLevels;

  @override
  void initState() {
    super.initState();
    final pays = widget.jobs.map((j) => j.dailyPay).toList();
    _boundsMin = pays.isEmpty ? 0 : (pays.reduce((a, b) => a < b ? a : b) ~/ 50) * 50;
    _boundsMax = pays.isEmpty ? 2000 : ((pays.reduce((a, b) => a > b ? a : b) ~/ 50) + 1) * 50;
    if (_boundsMax <= _boundsMin) _boundsMax = _boundsMin + 100;

    _salaryRange = RangeValues(
      (widget.current.minSalary ?? _boundsMin).toDouble().clamp(_boundsMin.toDouble(), _boundsMax.toDouble()),
      (widget.current.maxSalary ?? _boundsMax).toDouble().clamp(_boundsMin.toDouble(), _boundsMax.toDouble()),
    );
    _skills = {...widget.current.skills};
    _projectTypes = {...widget.current.projectTypes};
    _experienceLevels = {...widget.current.experienceLevels};
  }

  List<String> get _availableSkills {
    final all = <String>{};
    for (final job in widget.jobs) {
      all.addAll(job.skills);
    }
    final list = all.toList()..sort();
    return list;
  }

  void _reset() {
    setState(() {
      _salaryRange = RangeValues(_boundsMin.toDouble(), _boundsMax.toDouble());
      _skills = {};
      _projectTypes = {};
      _experienceLevels = {};
    });
  }

  void _apply() {
    final atMin = _salaryRange.start.round() == _boundsMin;
    final atMax = _salaryRange.end.round() == _boundsMax;
    Navigator.pop(
      context,
      JobFilters(
        minSalary: atMin ? null : _salaryRange.start.round(),
        maxSalary: atMax ? null : _salaryRange.end.round(),
        skills: _skills,
        projectTypes: _projectTypes,
        experienceLevels: _experienceLevels,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _chipGroup({
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option,style: textTheme.bodySmall ),
          selected: isSelected,
          onSelected: (_) => onToggle(option),
          selectedColor: AppColors.primary.withOpacity(0.15),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
          backgroundColor: Colors.white,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .85),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(20)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter jobs', style: textTheme.titleLarge),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Daily salary range'),
                    RangeSlider(
                      values: _salaryRange,
                      min: _boundsMin.toDouble(),
                      max: _boundsMax.toDouble(),
                      divisions: ((_boundsMax - _boundsMin) / 50).round().clamp(1, 100),
                      activeColor: AppColors.primary,
                      labels: RangeLabels('₹${_salaryRange.start.round()}', '₹${_salaryRange.end.round()}'),
                      onChanged: (values) => setState(() => _salaryRange = values),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${_salaryRange.start.round()}/day', style: textTheme.bodySmall),
                        Text('₹${_salaryRange.end.round()}/day', style: textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Skills'),
                    _availableSkills.isEmpty
                        ? Text('No skills to filter by yet', style: textTheme.bodySmall)
                        : _chipGroup(
                            options: _availableSkills,
                            selected: _skills,
                            onToggle: (skill) => setState(() {
                              _skills.contains(skill) ? _skills.remove(skill) : _skills.add(skill);
                            }),
                          ),
                    const SizedBox(height: 20),
                    _sectionTitle('Project type'),
                    _chipGroup(
                      options: _projectTypeOptions,
                      selected: _projectTypes,
                      onToggle: (type) => setState(() {
                        _projectTypes.contains(type) ? _projectTypes.remove(type) : _projectTypes.add(type);
                      }),
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Experience level'),
                    _chipGroup(
                      options: _experienceOptions,
                      selected: _experienceLevels,
                      onToggle: (level) => setState(() {
                        _experienceLevels.contains(level) ? _experienceLevels.remove(level) : _experienceLevels.add(level);
                      }),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  child: const Text('Apply filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
