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
    this.projectType = 'Full-time',
    this.experienceLevel = 'Any',
  });
  final String id, title, company, location;
  final int dailyPay;
  final List<String> skills;
  final String description;
  final List<String> requirements;
  final bool saved, applied;
  final String? applicationId;
  final String? applicationStatus;
  // e.g. 'Full-time', 'Contract', 'Daily Wage'
  final String projectType;
  // e.g. 'Fresher', 'Experienced', 'Any'
  final String experienceLevel;
  factory Job.fromJson(Map<String, dynamic> j) {
    int parsePay(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
      return 0;
    }

    final pay = parsePay(j['dailyPay']) != 0 ? parsePay(j['dailyPay']) : parsePay(j['compensation']);

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
      projectType: j['projectType']?.toString() ?? 'Full-time',
      experienceLevel: j['experienceLevel']?.toString() ?? 'Any',
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
    this.profilePhotoUrl,
    this.documents = const [],
  });
  final String name, phone, city, salaryExpectation;
  final List<String> skills;
  final String? profilePhotoUrl;
  final List<Map<String, dynamic>> documents;
  factory WorkerProfile.fromJson(Map<String, dynamic> j) => WorkerProfile(
    name: j['name'],
    phone: j['phone'],
    city: j['city'],
    skills: List<String>.from(j['skills'] ?? []),
    salaryExpectation: j['salaryExpectation'],
    profilePhotoUrl: j['profilePhotoUrl'],
    documents: List<Map<String, dynamic>>.from(j['documents'] ?? const []),
  );
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

  /// Parse a conversation from the real backend API response.
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
