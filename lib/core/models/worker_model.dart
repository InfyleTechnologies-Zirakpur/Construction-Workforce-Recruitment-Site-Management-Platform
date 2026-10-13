class WorkerExperience {
  final String company;
  final String role;
  final int years;
  final String? summary;

  const WorkerExperience({
    required this.company,
    required this.role,
    this.years = 0,
    this.summary,
  });

  factory WorkerExperience.fromJson(Map<String, dynamic> json) {
    int parseYears(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return WorkerExperience(
      company: json['company']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      years: parseYears(json['years'] ?? json['experienceYears']),
      summary: json['summary']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'role': role,
      'years': years,
      if (summary != null) 'summary': summary,
    };
  }
}

class WorkerProfileModel {
  final String id;
  final String? userId;
  final String fullName;
  final String phone;
  final String city;
  final List<String> skills;
  final String salaryExpectation;
  final List<WorkerExperience> experience;
  final String? profilePhoto;
  final int? experienceYears;
  final String? availabilityStatus;
  final List<Map<String, dynamic>> documents;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkerProfileModel({
    required this.id,
    this.userId,
    required this.fullName,
    required this.phone,
    required this.city,
    this.skills = const [],
    this.salaryExpectation = '',
    this.experience = const [],
    this.profilePhoto,
    this.experienceYears,
    this.availabilityStatus,
    this.documents = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    int? parseYears(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    final rawName = json['fullName']?.toString() ??
        json['name']?.toString() ??
        json['displayName']?.toString() ??
        'Worker';

    final rawPhoto = json['profilePhoto']?.toString() ??
        json['profilePhotoUrl']?.toString() ??
        json['photoUrl']?.toString() ??
        json['avatarUrl']?.toString();

    final List<WorkerExperience> parsedExp = [];
    if (json['experience'] is List) {
      for (final item in json['experience'] as List) {
        if (item is Map) {
          parsedExp.add(WorkerExperience.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          parsedExp.add(WorkerExperience(company: '', role: '', summary: item));
        }
      }
    }

    return WorkerProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      fullName: rawName,
      phone: json['phone']?.toString() ?? json['contactPhone']?.toString() ?? '',
      city: json['city']?.toString() ?? json['location']?.toString() ?? '',
      skills: List<String>.from(
        (json['skills'] as List?)?.map((e) => e.toString()) ?? const [],
      ),
      salaryExpectation: json['salaryExpectation']?.toString() ?? '',
      experience: parsedExp,
      profilePhoto: rawPhoto,
      experienceYears: parseYears(json['experienceYears'] ?? json['totalExperienceYears']),
      availabilityStatus: json['availabilityStatus']?.toString(),
      documents: List<Map<String, dynamic>>.from(
        (json['documents'] as List?)?.whereType<Map<String, dynamic>>() ?? const [],
      ),
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
      if (userId != null) 'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'city': city,
      'skills': skills,
      'salaryExpectation': salaryExpectation,
      'experience': experience.map((e) => e.toJson()).toList(),
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (availabilityStatus != null) 'availabilityStatus': availabilityStatus,
      'documents': documents,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Request body for PUT /profile
  Map<String, dynamic> toUpdatePayload() {
    return {
      'city': city,
      'skills': skills,
      'salaryExpectation': salaryExpectation,
      'experience': experience.map((e) => e.toJson()).toList(),
      if (fullName.isNotEmpty) 'name': fullName,
      if (fullName.isNotEmpty) 'fullName': fullName,
    };
  }
}
