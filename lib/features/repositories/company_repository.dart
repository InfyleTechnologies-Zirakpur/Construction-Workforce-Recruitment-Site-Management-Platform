import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';

class CompanyRepository {
  CompanyRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  Future<Map<String, dynamic>> registerCompany({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final r = await _client.dio.post('/auth/register', data: {
      'fullName': fullName,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'role': 'company',
    });
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  // --- COMPANY EMAIL OTP SIGNUP (new flow per integration/COMPANY_AUTH_AND_SIGNUP.md) ---
  Future<Map<String, dynamic>> sendCompanySignupOtp({
    required String name,
    required String email,
  }) async {
    final r = await _client.dio.post('/auth/signup/company/send-otp', data: {
      'name': name,
      'email': email,
      'role': 'company',
    });
    final raw = Map<String, dynamic>.from(r.data is Map ? r.data : {});
    if (raw['data'] is Map) {
      final inner = Map<String, dynamic>.from(raw['data'] as Map);
      return {...raw, ...inner};
    }
    return raw;
  }

  Future<Map<String, dynamic>> verifyCompanySignupOtp({
    required String email,
    required String otp,
  }) async {
    final r = await _client.dio.post('/auth/signup/company/verify-otp', data: {
      'email': email,
      'otp': otp,
    });
    final raw = Map<String, dynamic>.from(r.data is Map ? r.data : {});
    if (raw['data'] is Map) {
      final inner = Map<String, dynamic>.from(raw['data'] as Map);
      return {...raw, ...inner};
    }
    return raw;
  }

  Future<Map<String, dynamic>> setCompanySignupPassword({
    required String signupToken,
    required String password,
    required String confirmPassword,
  }) async {
    final r = await _client.dio.post('/auth/signup/company/set-password', data: {
      'signupToken': signupToken,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    final raw = Map<String, dynamic>.from(r.data is Map ? r.data : {});
    if (raw['data'] is Map) {
      final inner = Map<String, dynamic>.from(raw['data'] as Map);
      return {...raw, ...inner};
    }
    return raw;
  }

  Future<Map<String, dynamic>> loginCompany({required String email, required String password}) async {
    final r = await _client.dio.post('/auth/login', data: {
      'method': 'email',
      'email': email,
      'password': password,
    });
    final raw = Map<String, dynamic>.from(r.data is Map ? r.data : {});
    if (raw['data'] is Map) {
      final inner = Map<String, dynamic>.from(raw['data'] as Map);
      return {...raw, ...inner};
    }
    return raw;
  }

  /// GET /companies/user/:userId or GET /companies/user/ - Retrieve company profile by user id or currently logged-in user
  Future<Map<String, dynamic>?> getCompanyByUserId([String? userId]) async {
    try {
      final path = (userId != null && userId.trim().isNotEmpty)
          ? '/companies/user/${userId.trim()}'
          : '/companies/user/';
      final r = await _client.dio.get(path);
      final raw = r.data;
      if (raw is Map) {
        var d = raw['data'] ?? raw;
        if (d is Map && d['data'] is Map) {
          d = d['data'];
        }
        if (d is Map) return Map<String, dynamic>.from(d);
      }
      return null;
    } catch (_) {
      try {
        final altPath = (userId != null && userId.trim().isNotEmpty)
            ? '/companies/user/${userId.trim()}'
            : '/companies/user';
        final r = await _client.dio.get(altPath);
        final raw = r.data;
        if (raw is Map) {
          var d = raw['data'] ?? raw;
          if (d is Map && d['data'] is Map) {
            d = d['data'];
          }
          if (d is Map) return Map<String, dynamic>.from(d);
        }
      } catch (_) {}
      return null;
    }
  }

  /// GET /companies/user/ - Retrieve company profile for the currently logged-in company user
  Future<Map<String, dynamic>?> getMyCompanyProfile() async {
    return getCompanyByUserId(null);
  }

  // --- AUTH / SESSION ---

  /// POST /auth/logout — invalidates server session + device token.
  /// Works for both `company` and `job_seeker` roles (same endpoint).
  /// Best-effort: never throws, local session is cleared by caller anyway.
  Future<void> logout({String? fcmToken}) async {
    try {
      await _client.dio.post('/auth/logout', data: {
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      });
    } catch (_) {}
  }

  // --- COMPANY PROFILE APIS ---

  /// 1. POST /api/v1/companies - Register a new company profile
  Future<Map<String, dynamic>> createCompanyProfile(Map<String, dynamic> body) async {
    final r = await _client.dio.post('/companies', data: body);
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  /// 2. GET /api/v1/companies/my-profiles - Retrieve company profiles owned by current logged-in company user
  Future<List<Map<String, dynamic>>> getMyProfiles() async {
    final r = await _client.dio.get('/companies/my-profiles');
    final d = r.data['data'];
    if (d is Map && d['data'] is List) return List<Map<String, dynamic>>.from(d['data']);
    if (d is List) return List<Map<String, dynamic>>.from(d);
    return [];
  }

  /// 3. GET /api/v1/companies - List all company profiles (Admin / Directory)
  Future<Map<String, dynamic>> listCompanies({int page = 1, int limit = 10, String? status}) async {
    final r = await _client.dio.get('/companies', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  /// 4. GET /api/v1/companies/:id - View single company details by UUID
  Future<Map<String, dynamic>> getCompanyById(String id) async {
    final r = await _client.dio.get('/companies/$id');
    final raw = r.data;
    if (raw is Map) {
      var d = raw['data'] ?? raw;
      if (d is Map && d['data'] is Map) {
        d = d['data'];
      }
      if (d is Map) return Map<String, dynamic>.from(d);
    }
    return <String, dynamic>{};
  }

  /// 5. PATCH /api/v1/companies/:id - Update company profile details
  Future<Map<String, dynamic>> updateCompanyProfile(String id, Map<String, dynamic> body) async {
    final r = await _client.dio.patch('/companies/$id', data: body);
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  /// 6. PATCH /api/v1/companies/:id/verify - Admin verification / rejection of company profile
  Future<Map<String, dynamic>> verifyCompany(String id, {required String verificationStatus, String? verificationRemarks}) async {
    final r = await _client.dio.patch('/companies/$id/verify', data: {
      'verificationStatus': verificationStatus,
      if (verificationRemarks != null) 'verificationRemarks': verificationRemarks,
    });
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  // --- JOB MANAGEMENT APIS FOR COMPANY ---

  /// 1. POST /jobs - CREATE JOB POSTING
  Future<Map<String, dynamic>> createJob(Map<String, dynamic> body) async {
    try {
      final cleanBody = Map<String, dynamic>.from(body)
        ..remove('category')
        ..remove('salary')
        ..remove('jobType')
        ..remove('type')
        ..remove('experience')
        ..remove('experienceRequired');
      final r = await _client.dio.post('/jobs', data: cleanBody);
      return Map<String, dynamic>.from(r.data['data'] ?? r.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        // Fallback: strip extra metadata fields if rejected by older backend schema
        final stripped = Map<String, dynamic>.from(body)
          ..remove('category')
          ..remove('salary')
          ..remove('jobType')
          ..remove('type')
          ..remove('experience')
          ..remove('experienceRequired')
          ..remove('projectType')
          ..remove('experienceLevel');
        if (stripped.length < body.length) {
          final r2 = await _client.dio.post('/jobs', data: stripped);
          return Map<String, dynamic>.from(r2.data['data'] ?? r2.data);
        }
      }
      rethrow;
    }
  }

  /// 2. GET /jobs - LIST COMPANY JOBS
  Future<List<Map<String, dynamic>>> getCompanyJobs({
    int page = 1,
    int limit = 50,
    String? search,
    String? location,
    num? minDailyPay,
    String? skill,
    String? projectType,
    String? experienceLevel,
  }) async {
    final r = await _client.dio.get('/jobs', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (location != null && location.isNotEmpty) 'location': location,
      if (minDailyPay != null) 'minDailyPay': minDailyPay,
      if (skill != null && skill.isNotEmpty) 'skill': skill,
      if (projectType != null && projectType.isNotEmpty) 'projectType': projectType,
      if (experienceLevel != null && experienceLevel.isNotEmpty) 'experienceLevel': experienceLevel,
    });
    final d = r.data['data'];
    if (d is Map && d['data'] is List) return List<Map<String, dynamic>>.from(d['data']);
    if (d is List) return List<Map<String, dynamic>>.from(d);
    if (r.data['items'] is List) return List<Map<String, dynamic>>.from(r.data['items']);
    return [];
  }

  /// 3. GET /jobs/:id - GET JOB DETAILS BY ID
  Future<Map<String, dynamic>> getJobById(String id) async {
    final r = await _client.dio.get('/jobs/$id');
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  /// 4. PATCH /jobs/:id - UPDATE JOB POSTING
  Future<Map<String, dynamic>> updateJob(String id, Map<String, dynamic> body) async {
    try {
      final cleanBody = Map<String, dynamic>.from(body)
        ..remove('category')
        ..remove('salary')
        ..remove('jobType')
        ..remove('type')
        ..remove('experience')
        ..remove('experienceRequired');
      final r = await _client.dio.patch('/jobs/$id', data: cleanBody);
      return Map<String, dynamic>.from(r.data['data'] ?? r.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        final stripped = Map<String, dynamic>.from(body)
          ..remove('category')
          ..remove('salary')
          ..remove('jobType')
          ..remove('type')
          ..remove('experience')
          ..remove('experienceRequired')
          ..remove('projectType')
          ..remove('experienceLevel');
        if (stripped.length < body.length) {
          final r2 = await _client.dio.patch('/jobs/$id', data: stripped);
          return Map<String, dynamic>.from(r2.data['data'] ?? r2.data);
        }
      }
      rethrow;
    }
  }

  /// 5. POST /jobs/:id/close - CLOSE JOB POSTING
  Future<Map<String, dynamic>> closeJob(String id) async {
    final r = await _client.dio.post('/jobs/$id/close');
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  // --- APPLICATION MANAGEMENT APIS FOR COMPANY ---

  /// 10. GET /applications - LIST JOB APPLICATIONS SUBMITTED TO COMPANY JOBS
  Future<List<Map<String, dynamic>>> getCompanyApplications({
    String? status,
    String? jobId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final r = await _client.dio.get('/applications', queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
        if (jobId != null && jobId.isNotEmpty) 'jobId': jobId,
      });
      final raw = r.data;
      if (raw is Map) {
        final d = raw['data'];
        if (d is List) return List<Map<String, dynamic>>.from(d);
        if (d is Map && d['data'] is List) return List<Map<String, dynamic>>.from(d['data']);
        if (d is Map && d['items'] is List) return List<Map<String, dynamic>>.from(d['items']);
        if (d is Map && d['applications'] is List) return List<Map<String, dynamic>>.from(d['applications']);
        if (raw['items'] is List) return List<Map<String, dynamic>>.from(raw['items']);
        if (raw['applications'] is List) return List<Map<String, dynamic>>.from(raw['applications']);
      }
      if (raw is List) return List<Map<String, dynamic>>.from(raw);
    } catch (_) {}

    // Fallback: if jobId is provided and /applications didn't return or failed, try /jobs/:jobId/applications
    if (jobId != null && jobId.isNotEmpty) {
      try {
        final r = await _client.dio.get('/jobs/$jobId/applications');
        final raw = r.data;
        if (raw is Map) {
          final d = raw['data'];
          if (d is List) return List<Map<String, dynamic>>.from(d);
          if (d is Map && d['data'] is List) return List<Map<String, dynamic>>.from(d['data']);
          if (d is Map && d['items'] is List) return List<Map<String, dynamic>>.from(d['items']);
        }
        if (raw is List) return List<Map<String, dynamic>>.from(raw);
      } catch (_) {}
    }

    return [];
  }

  /// 11. GET /applications/:id - GET APPLICATION DETAILS BY ID
  Future<Map<String, dynamic>> getApplicationById(String id) async {
    final r = await _client.dio.get('/applications/$id');
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  /// 12. PATCH /applications/:id/status - UPDATE APPLICATION STATUS
  /// Supports both `reviewRemarks` (per integration doc) and legacy `remark`.
  Future<Map<String, dynamic>> updateApplicationStatus(
    String id, {
    required String status,
    String? remark,
    String? reviewRemarks,
  }) async {
    final note = (reviewRemarks ?? remark)?.trim();
    final body = <String, dynamic>{
      'status': status,
      if (note != null && note.isNotEmpty) ...{
        'reviewRemarks': note,
        'remark': note,
      },
    };

    try {
      final r = await _client.dio.patch('/applications/$id/status', data: body);
      return Map<String, dynamic>.from(r.data['data'] ?? r.data);
    } on DioException catch (e) {
      // If the backend rejects the remarks fields (422), retry with just status
      if (e.response?.statusCode == 422 && body.length > 1) {
        final fallback = await _client.dio.patch('/applications/$id/status', data: {'status': status});
        return Map<String, dynamic>.from(fallback.data['data'] ?? fallback.data);
      }
      rethrow;
    }
  }

  /// 13. POST /applications/bulk-shortlist - BULK SHORTLIST APPLICATIONS
  Future<Map<String, dynamic>> bulkShortlistApplications(List<String> applicationIds) async {
    final r = await _client.dio.post('/applications/bulk-shortlist', data: {
      'applicationIds': applicationIds,
    });
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  // --- ANALYTICS AND REPORTS API FOR COMPANY ---

  /// 16. GET /reports/operations/jobs-applications - JOB & APPLICATION ANALYTICS
  Future<Map<String, dynamic>> getReports() async {
    try {
      final r = await _client.dio.get('/reports/operations/jobs-applications');
      final raw = r.data;
      if (raw is Map) {
        final d1 = raw['data'];
        if (d1 is Map && d1['data'] is Map) {
          return Map<String, dynamic>.from(d1['data']);
        }
        if (d1 is Map) {
          return Map<String, dynamic>.from(d1);
        }
        return Map<String, dynamic>.from(raw);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  // Backward compatibility alias
  Future<List<Map<String, dynamic>>> myApplications() => getCompanyApplications();

  // --- NOTIFICATION MANAGEMENT (ADMIN & BROADCAST) ---

  /// API 7: GET /notifications/admin - ADMIN LIST ALL PLATFORM NOTIFICATIONS
  Future<Map<String, dynamic>> getAdminNotifications({
    int page = 1,
    int limit = 20,
    String? event,
    String? userId,
    String? search,
  }) async {
    final r = await _client.dio.get('/notifications/admin', queryParameters: {
      'page': page,
      'limit': limit,
      if (event != null && event.isNotEmpty) 'event': event,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  /// API 8: POST /notifications/send - SEND ADMIN ANNOUNCEMENT / TARGETED NOTIFICATION
  Future<Map<String, dynamic>> sendNotification({
    required String title,
    required String body,
    required String event,
    List<String>? userIds,
    String? referenceId,
  }) async {
    final r = await _client.dio.post('/notifications/send', data: {
      'title': title,
      'body': body,
      'event': event,
      if (userIds != null && userIds.isNotEmpty) 'userIds': userIds,
      if (referenceId != null && referenceId.isNotEmpty) 'referenceId': referenceId,
    });
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  // --- CONVERSATION / CHAT APIS FOR COMPANY ---

  /// GET /conversations - LIST ALL CONVERSATIONS
  Future<List<Map<String, dynamic>>> getConversations() async {
    final r = await _client.dio.get('/conversations');
    final raw = r.data;
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) return List<Map<String, dynamic>>.from(d);
      if (d is Map && d['data'] is List) return List<Map<String, dynamic>>.from(d['data']);
      if (d is Map && d['items'] is List) return List<Map<String, dynamic>>.from(d['items']);
    }
    if (raw is List) return List<Map<String, dynamic>>.from(raw);
    return [];
  }

  /// GET /conversations/:id - GET SINGLE CONVERSATION
  Future<Map<String, dynamic>> getConversationById(String id) async {
    final r = await _client.dio.get('/conversations/$id');
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  /// GET /conversations/:id/messages - FETCH MESSAGES
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final r = await _client.dio.get('/conversations/$conversationId/messages');
    final raw = r.data;
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) return List<Map<String, dynamic>>.from(d);
      if (d is Map && d['data'] is List) return List<Map<String, dynamic>>.from(d['data']);
      if (d is Map && d['items'] is List) return List<Map<String, dynamic>>.from(d['items']);
    }
    if (raw is List) return List<Map<String, dynamic>>.from(raw);
    return [];
  }

  /// POST /conversations/:id/messages - SEND MESSAGE
  Future<Map<String, dynamic>> sendMessage(String conversationId, String text) async {
    final r = await _client.dio.post('/conversations/$conversationId/messages', data: {'text': text});
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  /// PATCH /conversations/:id/read - MARK CONVERSATION READ
  Future<void> markConversationRead(String conversationId) async {
    await _client.dio.patch('/conversations/$conversationId/read');
  }
}
