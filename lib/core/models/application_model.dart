import 'job_model.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String? userId;
  final String status;
  final double? expectedDailyWage;
  final String? coverNote;
  final List<String> skills;
  final int? experienceYears;
  final String? availableFrom;
  final String? contactPhone;
  final String? reviewRemarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final JobModel? job;
  final String? applicantName;
  final String? applicantPhone;
  final String? applicantAvatarUrl;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    this.userId,
    required this.status,
    this.expectedDailyWage,
    this.coverNote,
    this.skills = const [],
    this.experienceYears,
    this.availableFrom,
    this.contactPhone,
    this.reviewRemarks,
    this.createdAt,
    this.updatedAt,
    this.job,
    this.applicantName,
    this.applicantPhone,
    this.applicantAvatarUrl,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    double? parseWage(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    int? parseYears(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    final jobData = json['job'] is Map
        ? JobModel.fromJson(Map<String, dynamic>.from(json['job']))
        : null;

    final userObj = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : (json['worker'] is Map
            ? Map<String, dynamic>.from(json['worker'])
            : (json['seeker'] is Map
                ? Map<String, dynamic>.from(json['seeker'])
                : null));

    final rawName = userObj?['fullName']?.toString() ??
        userObj?['name']?.toString() ??
        json['fullName']?.toString() ??
        json['applicantName']?.toString();

    final rawPhone = userObj?['phone']?.toString() ??
        json['contactPhone']?.toString() ??
        json['phone']?.toString();

    final rawAvatar = userObj?['avatarUrl']?.toString() ??
        userObj?['profilePhotoUrl']?.toString() ??
        json['avatarUrl']?.toString();

    return ApplicationModel(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ??
          (json['job'] is Map ? json['job']['id']?.toString() ?? '' : ''),
      userId: json['userId']?.toString() ?? userObj?['id']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      expectedDailyWage: parseWage(json['expectedDailyWage'] ?? json['dailyWage']),
      coverNote: json['coverNote']?.toString() ?? json['note']?.toString(),
      skills: List<String>.from(
        (json['skills'] as List?)?.map((e) => e.toString()) ?? const [],
      ),
      experienceYears: parseYears(json['experienceYears'] ?? json['yearsOfExperience']),
      availableFrom: json['availableFrom']?.toString(),
      contactPhone: rawPhone,
      reviewRemarks: json['reviewRemarks']?.toString() ??
          json['remarks']?.toString() ??
          json['remark']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      job: jobData,
      applicantName: rawName,
      applicantPhone: rawPhone,
      applicantAvatarUrl: rawAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      if (userId != null) 'userId': userId,
      'status': status,
      if (expectedDailyWage != null) 'expectedDailyWage': expectedDailyWage,
      if (coverNote != null) 'coverNote': coverNote,
      if (skills.isNotEmpty) 'skills': skills,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (availableFrom != null) 'availableFrom': availableFrom,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (reviewRemarks != null) 'reviewRemarks': reviewRemarks,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (job != null) 'job': job!.toJson(),
    };
  }

  /// Request body for POST /applications/jobs/:jobId/apply
  Map<String, dynamic> toApplyPayload() {
    return {
      if (coverNote != null && coverNote!.isNotEmpty) 'coverNote': coverNote,
      if (expectedDailyWage != null) 'expectedDailyWage': expectedDailyWage,
      if (skills.isNotEmpty) 'skills': skills,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (availableFrom != null && availableFrom!.isNotEmpty)
        'availableFrom': availableFrom,
      if (contactPhone != null && contactPhone!.isNotEmpty)
        'contactPhone': contactPhone,
    };
  }
}
