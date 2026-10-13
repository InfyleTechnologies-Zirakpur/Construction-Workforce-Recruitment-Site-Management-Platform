class JobModel {
  final String id;
  final String title;
  final String location;
  final String description;
  final String company;
  final double dailyPay;
  final num compensation;
  final List<String> skills;
  final List<String> requirements;
  final bool saved;
  final bool applied;
  final String projectType;
  final String experienceLevel;
  final int workforceRequired;
  final String status;
  final String? companyId;
  final String? applicationId;
  final String? applicationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const JobModel({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.company,
    required this.dailyPay,
    this.compensation = 0,
    required this.skills,
    this.requirements = const [],
    required this.saved,
    required this.applied,
    required this.projectType,
    required this.experienceLevel,
    this.workforceRequired = 1,
    this.status = 'published',
    this.companyId,
    this.applicationId,
    this.applicationStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    double parseWage(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    }

    final double dPay = parseWage(json['dailyPay']);
    final double comp = parseWage(json['compensation']);
    final double effectivePay = dPay > 0 ? dPay : comp;

    return JobModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      company: json['company'] is String
          ? json['company'] as String
          : json['company']?['name']?.toString() ??
              json['company']?['companyName']?.toString() ??
              '',
      dailyPay: effectivePay,
      compensation: comp > 0 ? comp : effectivePay,
      skills: List<String>.from(
        (json['skills'] as List?)?.map((e) => e.toString()) ?? const [],
      ),
      requirements: List<String>.from(
        (json['requirements'] as List?)?.map((e) => e.toString()) ?? const [],
      ),
      saved: json['saved'] == true,
      applied: json['applied'] == true,
      projectType: json['projectType']?.toString() ?? 'Full-time',
      experienceLevel: json['experienceLevel']?.toString() ?? 'Any',
      workforceRequired: (json['workforceRequired'] as num?)?.toInt() ?? 1,
      status: json['status']?.toString() ?? 'published',
      companyId: json['companyId']?.toString(),
      applicationId: json['applicationId']?.toString(),
      applicationStatus:
          json['applicationStatus']?.toString() ?? json['status']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'description': description,
      'company': company,
      'dailyPay': dailyPay,
      'compensation': compensation,
      'skills': skills,
      'requirements': requirements,
      'saved': saved,
      'applied': applied,
      'projectType': projectType,
      'experienceLevel': experienceLevel,
      'workforceRequired': workforceRequired,
      'status': status,
      if (companyId != null) 'companyId': companyId,
      if (applicationId != null) 'applicationId': applicationId,
      if (applicationStatus != null) 'applicationStatus': applicationStatus,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Request body for POST /jobs
  Map<String, dynamic> toCreateJobPayload() {
    return {
      'title': title,
      'location': location,
      'description': description,
      'skills': skills,
      'compensation': dailyPay > 0 ? dailyPay : compensation,
      'workforceRequired': workforceRequired,
      'projectType': projectType,
      'experienceLevel': experienceLevel,
    };
  }
}
