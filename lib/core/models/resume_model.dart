class ResumeWorkExperience {
  final String jobTitle;
  final String companyName;
  final String startDate;
  final String endDate;
  final bool isCurrentlyWorking;
  final String responsibility;

  const ResumeWorkExperience({
    required this.jobTitle,
    required this.companyName,
    this.startDate = '',
    this.endDate = '',
    this.isCurrentlyWorking = false,
    this.responsibility = '',
  });

  factory ResumeWorkExperience.fromJson(Map<String, dynamic> json) {
    return ResumeWorkExperience(
      jobTitle: json['jobTitle']?.toString() ?? json['title']?.toString() ?? json['role']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? json['company']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      isCurrentlyWorking: json['isCurrentlyWorking'] == true || json['currentlyWorking'] == true,
      responsibility: json['responsibility']?.toString() ?? json['responsibilities']?.toString() ?? json['summary']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'jobTitle': jobTitle,
    'companyName': companyName,
    'startDate': startDate,
    'endDate': endDate,
    'isCurrentlyWorking': isCurrentlyWorking,
    'responsibility': responsibility,
  };
}

class ResumeEducation {
  final String qualification;
  final String instituteName;
  final String yearOfPassing;
  final String percentageOrCgpa;

  const ResumeEducation({
    required this.qualification,
    required this.instituteName,
    this.yearOfPassing = '',
    this.percentageOrCgpa = '',
  });

  factory ResumeEducation.fromJson(Map<String, dynamic> json) {
    return ResumeEducation(
      qualification: json['qualification']?.toString() ?? json['degree']?.toString() ?? '',
      instituteName: json['instituteName']?.toString() ?? json['institute']?.toString() ?? json['school']?.toString() ?? '',
      yearOfPassing: json['yearOfPassing']?.toString() ?? json['year']?.toString() ?? '',
      percentageOrCgpa: json['percentageOrCgpa']?.toString() ?? json['cgpa']?.toString() ?? json['grade']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'qualification': qualification,
    'instituteName': instituteName,
    'yearOfPassing': yearOfPassing,
    'percentageOrCgpa': percentageOrCgpa,
  };
}

class ResumeCertification {
  final String name;
  final String issuedBy;
  final String issueDate;

  const ResumeCertification({
    required this.name,
    required this.issuedBy,
    this.issueDate = '',
  });

  factory ResumeCertification.fromJson(Map<String, dynamic> json) {
    return ResumeCertification(
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      issuedBy: json['issuedBy']?.toString() ?? json['authority']?.toString() ?? '',
      issueDate: json['issueDate']?.toString() ?? json['date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'issuedBy': issuedBy,
    'issueDate': issueDate,
  };
}

class ResumeModel {
  final String id;
  final String title;
  final DateTime updatedAt;
  final int usedApplicationsCount;
  final String? fileUrl;
  final String? localPath;
  final bool isUploadedFile;

  bool get isUploaded => isUploadedFile;

  // 1. Personal Information
  final String fullName;
  final String dob;
  final String gender;
  final String phone;
  final String email;
  final String currentAddress;

  // 2. Professional Summary
  final String currentRole;
  final String totalExperience;
  final String aboutYou;

  // 3. Work Experience
  final List<ResumeWorkExperience> workExperiences;

  // 4. Education
  final List<ResumeEducation> educations;

  // 5. Skills & Equipment
  final List<String> technicalSkills;
  final List<String> equipmentOperated;

  // 6. Certifications & Licenses
  final List<ResumeCertification> certifications;

  const ResumeModel({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.usedApplicationsCount = 0,
    this.fileUrl,
    this.localPath,
    this.isUploadedFile = false,
    required this.fullName,
    this.dob = '',
    this.gender = 'Male',
    required this.phone,
    this.email = '',
    this.currentAddress = '',
    this.currentRole = '',
    this.totalExperience = '',
    this.aboutYou = '',
    this.workExperiences = const [],
    this.educations = const [],
    this.technicalSkills = const [],
    this.equipmentOperated = const [],
    this.certifications = const [],
  });

  ResumeModel copyWith({
    String? id,
    String? title,
    DateTime? updatedAt,
    int? usedApplicationsCount,
    String? fileUrl,
    String? localPath,
    bool? isUploadedFile,
    String? fullName,
    String? dob,
    String? gender,
    String? phone,
    String? email,
    String? currentAddress,
    String? currentRole,
    String? totalExperience,
    String? aboutYou,
    List<ResumeWorkExperience>? workExperiences,
    List<ResumeEducation>? educations,
    List<String>? technicalSkills,
    List<String>? equipmentOperated,
    List<ResumeCertification>? certifications,
  }) {
    return ResumeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      usedApplicationsCount: usedApplicationsCount ?? this.usedApplicationsCount,
      fileUrl: fileUrl ?? this.fileUrl,
      localPath: localPath ?? this.localPath,
      isUploadedFile: isUploadedFile ?? this.isUploadedFile,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currentAddress: currentAddress ?? this.currentAddress,
      currentRole: currentRole ?? this.currentRole,
      totalExperience: totalExperience ?? this.totalExperience,
      aboutYou: aboutYou ?? this.aboutYou,
      workExperiences: workExperiences ?? this.workExperiences,
      educations: educations ?? this.educations,
      technicalSkills: technicalSkills ?? this.technicalSkills,
      equipmentOperated: equipmentOperated ?? this.equipmentOperated,
      certifications: certifications ?? this.certifications,
    );
  }

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    final rawExp = (json['workExperiences'] as List?) ?? (json['experience'] as List?) ?? [];
    final experiences = rawExp
        .whereType<Map>()
        .map((e) => ResumeWorkExperience.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawEdu = (json['educations'] as List?) ?? (json['education'] as List?) ?? [];
    final educations = rawEdu
        .whereType<Map>()
        .map((e) => ResumeEducation.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawCerts = (json['certifications'] as List?) ?? [];
    final certifications = rawCerts
        .whereType<Map>()
        .map((e) => ResumeCertification.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ResumeModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'My Resume',
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      usedApplicationsCount: (json['usedApplicationsCount'] as num?)?.toInt() ?? 0,
      fileUrl: json['fileUrl']?.toString(),
      localPath: json['localPath']?.toString(),
      isUploadedFile: json['isUploadedFile'] == true ||
          (json['workExperiences'] == null &&
              ((json['experience'] as List?)?.isEmpty ?? true) &&
              (json['fileUrl'] != null || json['localPath'] != null)),
      fullName: json['fullName']?.toString() ?? json['name']?.toString() ?? '',
      dob: json['dob']?.toString() ?? json['dateOfBirth']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'Male',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      currentAddress: json['currentAddress']?.toString() ?? json['address']?.toString() ?? json['city']?.toString() ?? '',
      currentRole: json['currentRole']?.toString() ?? json['role']?.toString() ?? '',
      totalExperience: json['totalExperience']?.toString() ?? json['experienceYears']?.toString() ?? '',
      aboutYou: json['aboutYou']?.toString() ?? json['summary']?.toString() ?? json['bio']?.toString() ?? '',
      workExperiences: experiences,
      educations: educations,
      technicalSkills: List<String>.from((json['technicalSkills'] as List?)?.map((e) => e.toString()) ?? (json['skills'] as List?)?.map((e) => e.toString()) ?? []),
      equipmentOperated: List<String>.from((json['equipmentOperated'] as List?)?.map((e) => e.toString()) ?? (json['equipment'] as List?)?.map((e) => e.toString()) ?? []),
      certifications: certifications,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'updatedAt': updatedAt.toIso8601String(),
    'usedApplicationsCount': usedApplicationsCount,
    if (fileUrl != null) 'fileUrl': fileUrl,
    if (localPath != null) 'localPath': localPath,
    'isUploadedFile': isUploadedFile,
    'fullName': fullName,
    'dob': dob,
    'gender': gender,
    'phone': phone,
    'email': email,
    'currentAddress': currentAddress,
    'currentRole': currentRole,
    'totalExperience': totalExperience,
    'aboutYou': aboutYou,
    'workExperiences': workExperiences.map((e) => e.toJson()).toList(),
    'educations': educations.map((e) => e.toJson()).toList(),
    'technicalSkills': technicalSkills,
    'equipmentOperated': equipmentOperated,
    'certifications': certifications.map((e) => e.toJson()).toList(),
  };
}

