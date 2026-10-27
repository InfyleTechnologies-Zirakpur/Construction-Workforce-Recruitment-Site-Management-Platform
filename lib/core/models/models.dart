import 'worker_model.dart';

export 'job_model.dart';
export 'application_model.dart';
export 'company_model.dart';
export 'worker_model.dart';
export 'feed_post_model.dart';
export 'document_model.dart';

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.dailyPay,
    required this.skills,
    this.description = '',
    this.requirements = const [],
    this.saved = false,
    this.applied = false,
    this.applicationId,
    this.applicationStatus,
    this.reviewRemarks,
    this.projectType = 'Full-time',
    this.experienceLevel = 'Any',
    this.createdAt,
    this.workforceRequired,
  });
  final String id, title, company, location;
  final int dailyPay;
  final List<String> skills;
  final String description;
  final List<String> requirements;
  final bool saved, applied;
  final String? applicationId;
  final String? applicationStatus;
  final String? reviewRemarks;
  // e.g. 'Full-time', 'Contract', 'Daily Wage'
  final String projectType;
  // e.g. 'Fresher', 'Experienced', 'Any'
  final String experienceLevel;
  final String? createdAt;
  final int? workforceRequired;
  factory Job.fromJson(Map<String, dynamic> j) {
    int parsePay(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
      return 0;
    }

    final pay = parsePay(j['dailyPay']) != 0 ? parsePay(j['dailyPay']) : parsePay(j['compensation']);

    int? parseHeadcount(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return Job(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? 'Job Title',
      company: j['company'] is Map ? (j['company']['name']?.toString() ?? 'Company') : (j['company']?.toString() ?? 'Company'),
      location: j['location']?.toString() ?? 'Location',
      dailyPay: pay,
      skills: List<String>.from((j['skills'] as List?)?.map((e) => e.toString()) ?? []),
      description: j['description']?.toString() ?? '',
      requirements: List<String>.from((j['requirements'] as List?)?.map((e) => e.toString()) ?? []),
      saved: j['saved'] == true,
      applied: j['applied'] == true,
      applicationId: j['applicationId']?.toString(),
      applicationStatus: j['applicationStatus']?.toString() ?? j['status']?.toString(),
      reviewRemarks: j['reviewRemarks']?.toString() ?? j['remark']?.toString() ?? j['remarks']?.toString(),
      projectType: j['projectType']?.toString() ?? 'Full-time',
      experienceLevel: j['experienceLevel']?.toString() ?? 'Any',
      createdAt: j['createdAt']?.toString() ?? j['postedAt']?.toString() ?? j['created_at']?.toString() ?? j['date']?.toString(),
      workforceRequired: parseHeadcount(j['workforceRequired'] ?? j['workersRequired'] ?? j['headcount'] ?? j['vacancies'] ?? j['openings']),
    );
  }

  Job copyWith({
    String? id,
    String? title,
    String? company,
    String? location,
    int? dailyPay,
    List<String>? skills,
    String? description,
    List<String>? requirements,
    bool? saved,
    bool? applied,
    String? applicationId,
    String? applicationStatus,
    String? reviewRemarks,
    String? projectType,
    String? experienceLevel,
    String? createdAt,
    int? workforceRequired,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      dailyPay: dailyPay ?? this.dailyPay,
      skills: skills ?? this.skills,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      saved: saved ?? this.saved,
      applied: applied ?? this.applied,
      applicationId: applicationId ?? this.applicationId,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      reviewRemarks: reviewRemarks ?? this.reviewRemarks,
      projectType: projectType ?? this.projectType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      createdAt: createdAt ?? this.createdAt,
      workforceRequired: workforceRequired ?? this.workforceRequired,
    );
  }
}

class Attendance {
  const Attendance({
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.hours,
  });
  final String date, checkIn, hours;
  final String? checkOut;
  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
    date: j['date'],
    checkIn: j['checkIn'],
    checkOut: j['checkOut'],
    hours: j['hours'],
  );
}

class WorkerProfile {
  const WorkerProfile({
    required this.name,
    required this.phone,
    required this.city,
    required this.skills,
    required this.salaryExpectation,
    this.email,
    this.experience = const [],
    this.education = const [],
    this.profilePhotoUrl,
    this.resumeUrl,
    this.documents = const [],
  });
  final String name, phone, city, salaryExpectation;
  final String? email;
  final List<String> skills;
  final List<WorkerExperience> experience;
  final List<dynamic> education;
  final String? profilePhotoUrl;
  final String? resumeUrl;
  final List<Map<String, dynamic>> documents;

  factory WorkerProfile.fromJson(Map<String, dynamic> j) {
    final List<WorkerExperience> parsedExp = [];
    if (j['experience'] is List) {
      for (final item in j['experience'] as List) {
        if (item is Map) {
          parsedExp.add(WorkerExperience.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          parsedExp.add(WorkerExperience(company: '', role: item));
        }
      }
    }

    final rawDocs = (j['documents'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];

    String? resume = j['resumeUrl']?.toString() ??
        j['resume']?.toString() ??
        j['cvUrl']?.toString();
    if (resume == null || resume.isEmpty) {
      for (final doc in rawDocs) {
        final t = (doc['type'] ?? '').toString().toLowerCase();
        final fn = (doc['fileName'] ?? doc['originalFilename'] ?? doc['name'] ?? '').toString().toLowerCase();
        if (t == 'resume' || t == 'cv' || fn.contains('resume')) {
          resume = doc['fileUrl']?.toString() ?? doc['url']?.toString();
          break;
        }
      }
    }

    return WorkerProfile(
      name: j['fullName']?.toString() ?? j['name']?.toString() ?? 'Worker',
      phone: j['phone']?.toString() ?? j['contactPhone']?.toString() ?? '',
      city: j['city']?.toString() ?? j['location']?.toString() ?? '',
      skills: List<String>.from((j['skills'] as List?)?.map((e) => e.toString()) ?? const []),
      salaryExpectation: j['salaryExpectation']?.toString() ?? '',
      email: j['email']?.toString(),
      experience: parsedExp,
      education: (j['education'] as List?) ?? const [],
      profilePhotoUrl: j['profilePhotoUrl']?.toString() ?? j['profilePhoto']?.toString() ?? j['photoUrl']?.toString(),
      resumeUrl: resume,
      documents: rawDocs,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.company,
    required this.jobTitle,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.messages,
    this.applicationId,
    this.jobId,
    this.seekerName,
    this.seekerAvatarUrl,
    this.companyAvatarUrl,
  });
  final String id, company, jobTitle, lastMessage, lastMessageAt;
  final int unreadCount;
  final List<ChatMessage> messages;
  final String? applicationId;
  final String? jobId;
  final String? seekerName;
  final String? seekerAvatarUrl;
  final String? companyAvatarUrl;

  Conversation copyWith({
    String? id,
    String? company,
    String? jobTitle,
    String? lastMessage,
    String? lastMessageAt,
    int? unreadCount,
    List<ChatMessage>? messages,
    String? applicationId,
    String? jobId,
    String? seekerName,
    String? seekerAvatarUrl,
    String? companyAvatarUrl,
  }) {
    return Conversation(
      id: id ?? this.id,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
      applicationId: applicationId ?? this.applicationId,
      jobId: jobId ?? this.jobId,
      seekerName: seekerName ?? this.seekerName,
      seekerAvatarUrl: seekerAvatarUrl ?? this.seekerAvatarUrl,
      companyAvatarUrl: companyAvatarUrl ?? this.companyAvatarUrl,
    );
  }

  /// The backend returns seeker/company/job objects nested in the conversation.
  /// [currentUserId] is used to determine the display name: if the current user
  /// is the company, show the seeker name, and vice versa.
  factory Conversation.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Extract nested objects
    final seekerObj = json['seeker'] is Map ? Map<String, dynamic>.from(json['seeker']) : null;
    final companyObj = json['company'] is Map ? Map<String, dynamic>.from(json['company']) : null;
    final jobObj = json['job'] is Map ? Map<String, dynamic>.from(json['job']) : null;
    final jobCompanyObj = jobObj != null && jobObj['company'] is Map
        ? Map<String, dynamic>.from(jobObj['company'])
        : null;

    // Determine company name: prefer job.company.name -> company.name -> company.companyName -> clean company.fullName
    final rawCompanyName = jobCompanyObj?['name']?.toString() ??
        companyObj?['name']?.toString() ??
        companyObj?['companyName']?.toString() ??
        (companyObj?['fullName']?.toString() != null
            ? companyObj!['fullName'].toString().replaceAll(RegExp(r'\s+Admin$', caseSensitive: false), '')
            : null) ??
        json['companyName']?.toString() ??
        'Company';

    final companyIdStr = json['companyId']?.toString() ?? companyObj?['id']?.toString();
    final seekerIdStr = json['seekerId']?.toString() ?? seekerObj?['id']?.toString();

    // Determine if current user is the company
    bool isCompanyUser = false;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      if (seekerIdStr != null && seekerIdStr.isNotEmpty && currentUserId == seekerIdStr) {
        isCompanyUser = false;
      } else if (companyIdStr != null && companyIdStr.isNotEmpty && currentUserId == companyIdStr) {
        isCompanyUser = true;
      } else if (jobCompanyObj?['id']?.toString() != null && currentUserId == jobCompanyObj!['id'].toString()) {
        isCompanyUser = true;
      } else {
        isCompanyUser = (seekerObj != null && (seekerIdStr == null || currentUserId != seekerIdStr));
      }
    } else {
      isCompanyUser = seekerObj != null;
    }

    // Determine display name for the other participant
    String displayName;
    if (json['company'] is String) {
      final str = json['company'] as String;
      displayName = str.endsWith(' Admin') ? str.replaceAll(RegExp(r'\s+Admin$', caseSensitive: false), '') : str;
    } else if (isCompanyUser) {
      // Company viewing: show Candidate / Job Seeker Name!
      displayName = seekerObj?['fullName']?.toString() ??
          seekerObj?['name']?.toString() ??
          json['seekerName']?.toString() ??
          'Job Seeker';
    } else {
      // Candidate viewing: show Company Name!
      displayName = rawCompanyName;
    }

    // Job title extraction
    String jobTitle;
    if (json['jobTitle'] is String) {
      jobTitle = json['jobTitle'] as String;
    } else {
      jobTitle = jobObj?['title']?.toString() ?? 'Job';
    }

    // Last message time formatting
    final rawTime = json['lastMessageAt']?.toString() ?? json['updatedAt']?.toString() ?? '';
    String formattedTime = rawTime;
    if (rawTime.isNotEmpty) {
      try {
        final dt = DateTime.parse(rawTime).toLocal();
        final now = DateTime.now();
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          formattedTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else {
          formattedTime = '${dt.day}/${dt.month}/${dt.year}';
        }
      } catch (_) {}
    }

    // Unread count: pick the right field based on the current user role
    int unread = 0;
    if (currentUserId != null && currentUserId == json['companyId']?.toString()) {
      unread = (json['unreadCountCompany'] as num?)?.toInt() ?? 0;
    } else {
      unread = (json['unreadCountSeeker'] as num?)?.toInt() ?? json['unreadCount'] as int? ?? 0;
    }

    // Parse inline messages if any
    final messagesList = (json['messages'] as List?)
        ?.map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item), currentUserId: currentUserId))
        .toList() ?? const [];

    return Conversation(
      id: json['id']?.toString() ?? '',
      company: displayName,
      jobTitle: jobTitle,
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageAt: formattedTime,
      unreadCount: unread,
      messages: messagesList,
      applicationId: json['applicationId']?.toString(),
      jobId: json['jobId']?.toString() ?? jobObj?['id']?.toString(),
      seekerName: seekerObj?['fullName']?.toString(),
      seekerAvatarUrl: seekerObj?['avatarUrl']?.toString(),
      companyAvatarUrl: companyObj?['avatarUrl']?.toString(),
    );
  }
}

class ChatMessage {
  const ChatMessage({required this.id, required this.text, required this.isMine, required this.time, this.isRead = false});
  final String id, text, time;
  final bool isMine;
  final bool isRead;

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Determine if this message was sent by the current user
    final senderObj = json['sender'] is Map ? Map<String, dynamic>.from(json['sender']) : null;
    final senderId = json['senderId']?.toString() ??
        senderObj?['id']?.toString() ??
        json['userId']?.toString() ??
        json['authorId']?.toString() ??
        '';

    final isMine = json['isMine'] as bool? ??
        (currentUserId != null &&
            currentUserId.isNotEmpty &&
            senderId.isNotEmpty &&
            senderId.toLowerCase() == currentUserId.toLowerCase());

    // Format timestamp
    final rawTime = json['createdAt']?.toString() ?? json['time']?.toString() ?? '';
    String formattedTime = rawTime;
    if (rawTime.isNotEmpty && rawTime.contains('T')) {
      try {
        final dt = DateTime.parse(rawTime).toLocal();
        formattedTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isMine: isMine,
      time: formattedTime,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

class WorkerNotification {
  const WorkerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    required this.isRead,
    this.referenceId,
    this.isPushed = false,
  });

  final String id, title, body, type, time;
  final bool isRead;
  final String? referenceId;
  final bool isPushed;

  factory WorkerNotification.fromJson(Map<String, dynamic> json) => WorkerNotification(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: (json['body'] ?? json['message'])?.toString() ?? '',
        type: (json['event'] ?? json['type'])?.toString() ?? 'general',
        time: (json['createdAt'] ?? json['time'])?.toString() ?? '',
        isRead: json['isRead'] as bool? ?? false,
        referenceId: json['referenceId']?.toString(),
        isPushed: json['isPushed'] as bool? ?? false,
      );
}
