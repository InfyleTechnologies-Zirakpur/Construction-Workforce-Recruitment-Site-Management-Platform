class CompanyModel {
  final String id;
  final String name;
  final String? registrationNumber;
  final String? gstNumber;
  final String? panNumber;
  final String contactEmail;
  final String contactPhone;
  final String? alternatePhone;
  final String city;
  final String state;
  final String? address;
  final String? pincode;
  final String? businessType;
  final List<String> specializations;
  final List<String> operationalAreas;
  final String? website;
  final String? logoUrl;
  final String? description;
  final int? yearEstablished;
  final String? teamSizeRange;
  final String verificationStatus;
  final String? verificationRemarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyModel({
    required this.id,
    required this.name,
    this.registrationNumber,
    this.gstNumber,
    this.panNumber,
    required this.contactEmail,
    required this.contactPhone,
    this.alternatePhone,
    required this.city,
    required this.state,
    this.address,
    this.pincode,
    this.businessType,
    this.specializations = const [],
    this.operationalAreas = const [],
    this.website,
    this.logoUrl,
    this.description,
    this.yearEstablished,
    this.teamSizeRange,
    this.verificationStatus = 'pending',
    this.verificationRemarks,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    int? parseYear(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return CompanyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['companyName']?.toString() ??
          'Company',
      registrationNumber: json['registrationNumber']?.toString(),
      gstNumber: json['gstNumber']?.toString(),
      panNumber: json['panNumber']?.toString(),
      contactEmail: json['contactEmail']?.toString() ??
          json['email']?.toString() ??
          '',
      contactPhone: json['contactPhone']?.toString() ??
          json['phone']?.toString() ??
          '',
      alternatePhone: json['alternatePhone']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      address: json['address']?.toString(),
      pincode: json['pincode']?.toString(),
      businessType: json['businessType']?.toString(),
      specializations: List<String>.from(
        (json['specializations'] as List?)?.map((e) => e.toString()) ?? const [],
      ),
      operationalAreas: List<String>.from(
        (json['operationalAreas'] as List?)?.map((e) => e.toString()) ?? const [],
      ),
      website: json['website']?.toString(),
      logoUrl: json['logoUrl']?.toString() ?? json['avatarUrl']?.toString(),
      description: json['description']?.toString(),
      yearEstablished: parseYear(json['yearEstablished']),
      teamSizeRange: json['teamSizeRange']?.toString(),
      verificationStatus:
          json['verificationStatus']?.toString() ?? 'pending',
      verificationRemarks: json['verificationRemarks']?.toString(),
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
      'name': name,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
      if (gstNumber != null) 'gstNumber': gstNumber,
      if (panNumber != null) 'panNumber': panNumber,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      if (alternatePhone != null) 'alternatePhone': alternatePhone,
      'city': city,
      'state': state,
      if (address != null) 'address': address,
      if (pincode != null) 'pincode': pincode,
      if (businessType != null) 'businessType': businessType,
      'specializations': specializations,
      'operationalAreas': operationalAreas,
      if (website != null) 'website': website,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (description != null) 'description': description,
      if (yearEstablished != null) 'yearEstablished': yearEstablished,
      if (teamSizeRange != null) 'teamSizeRange': teamSizeRange,
      'verificationStatus': verificationStatus,
      if (verificationRemarks != null) 'verificationRemarks': verificationRemarks,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Body for POST /companies
  Map<String, dynamic> toCreatePayload() {
    return {
      'name': name,
      if (registrationNumber != null && registrationNumber!.isNotEmpty)
        'registrationNumber': registrationNumber,
      if (gstNumber != null && gstNumber!.isNotEmpty) 'gstNumber': gstNumber,
      if (panNumber != null && panNumber!.isNotEmpty) 'panNumber': panNumber,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      if (alternatePhone != null && alternatePhone!.isNotEmpty)
        'alternatePhone': alternatePhone,
      'city': city,
      'state': state,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (pincode != null && pincode!.isNotEmpty) 'pincode': pincode,
      if (businessType != null && businessType!.isNotEmpty)
        'businessType': businessType,
      if (specializations.isNotEmpty) 'specializations': specializations,
      if (operationalAreas.isNotEmpty) 'operationalAreas': operationalAreas,
      if (website != null && website!.isNotEmpty) 'website': website,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (yearEstablished != null) 'yearEstablished': yearEstablished,
      if (teamSizeRange != null && teamSizeRange!.isNotEmpty)
        'teamSizeRange': teamSizeRange,
    };
  }
}
