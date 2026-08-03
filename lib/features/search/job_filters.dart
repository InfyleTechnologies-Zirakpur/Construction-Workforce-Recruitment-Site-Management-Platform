import '../../core/models/models.dart';

/// Immutable filter selection for the search screen. `null`/empty fields
/// mean "no constraint on this dimension".
class JobFilters {
  const JobFilters({
    this.minSalary,
    this.maxSalary,
    this.skills = const {},
    this.projectTypes = const {},
    this.experienceLevels = const {},
  });

  final int? minSalary;
  final int? maxSalary;
  final Set<String> skills;
  final Set<String> projectTypes;
  final Set<String> experienceLevels;

  bool get isEmpty =>
      minSalary == null &&
      maxSalary == null &&
      skills.isEmpty &&
      projectTypes.isEmpty &&
      experienceLevels.isEmpty;

  /// Number of active filter groups, used for a "3 filters" style badge.
  int get activeCount {
    var count = 0;
    if (minSalary != null || maxSalary != null) count++;
    if (skills.isNotEmpty) count++;
    if (projectTypes.isNotEmpty) count++;
    if (experienceLevels.isNotEmpty) count++;
    return count;
  }

  bool matches(Job job) {
    if (minSalary != null && job.dailyPay < minSalary!) return false;
    if (maxSalary != null && job.dailyPay > maxSalary!) return false;
    if (skills.isNotEmpty && !job.skills.any(skills.contains)) return false;
    if (projectTypes.isNotEmpty && !projectTypes.contains(job.projectType)) {
      return false;
    }
    if (experienceLevels.isNotEmpty &&
        !experienceLevels.contains(job.experienceLevel)) {
      return false;
    }
    return true;
  }

  JobFilters copyWith({
    int? minSalary,
    int? maxSalary,
    bool clearSalary = false,
    Set<String>? skills,
    Set<String>? projectTypes,
    Set<String>? experienceLevels,
  }) {
    return JobFilters(
      minSalary: clearSalary ? null : (minSalary ?? this.minSalary),
      maxSalary: clearSalary ? null : (maxSalary ?? this.maxSalary),
      skills: skills ?? this.skills,
      projectTypes: projectTypes ?? this.projectTypes,
      experienceLevels: experienceLevels ?? this.experienceLevels,
    );
  }
}
