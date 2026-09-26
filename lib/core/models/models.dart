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
    this.projectType = 'Full-time',
    this.experienceLevel = 'Any',
  });
  final String id, title, company, location;
  final int dailyPay;
  final List<String> skills;
  final String description;
  final List<String> requirements;
  final bool saved, applied;
  // e.g. 'Full-time', 'Contract', 'Daily Wage'
  final String projectType;
  // e.g. 'Fresher', 'Experienced', 'Any'
  final String experienceLevel;
  factory Job.fromJson(Map<String, dynamic> j) => Job(
    id: j['id'],
    title: j['title'],
    company: j['company'],
    location: j['location'],
    dailyPay: j['dailyPay'],
    skills: List<String>.from(j['skills'] ?? []),
    description: j['description'] ?? '',
    requirements: List<String>.from(j['requirements'] ?? []),
    saved: j['saved'] ?? false,
    applied: j['applied'] ?? false,
    projectType: j['projectType'] ?? 'Full-time',
    experienceLevel: j['experienceLevel'] ?? 'Any',
  );
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
  const Conversation({required this.id, required this.company, required this.jobTitle, required this.lastMessage, required this.lastMessageAt, required this.unreadCount, required this.messages});
  final String id, company, jobTitle, lastMessage, lastMessageAt;
  final int unreadCount;
  final List<ChatMessage> messages;
  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String, company: json['company'] as String, jobTitle: json['jobTitle'] as String,
    lastMessage: json['lastMessage'] as String, lastMessageAt: json['lastMessageAt'] as String,
    unreadCount: json['unreadCount'] as int? ?? 0,
    messages: (json['messages'] as List? ?? const []).map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item))).toList(),
  );
}

class ChatMessage {
  const ChatMessage({required this.id, required this.text, required this.isMine, required this.time});
  final String id, text, time;
  final bool isMine;
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(id: json['id'] as String, text: json['text'] as String, isMine: json['isMine'] as bool, time: json['time'] as String);
}

class WorkerNotification {
  const WorkerNotification({required this.id, required this.title, required this.body, required this.type, required this.time, required this.isRead});
  final String id, title, body, type, time;
  final bool isRead;
  factory WorkerNotification.fromJson(Map<String, dynamic> json) => WorkerNotification(id: json['id'] as String, title: json['title'] as String, body: json['body'] as String, type: json['type'] as String, time: json['time'] as String, isRead: json['isRead'] as bool? ?? false);
}
