import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_client.dart';
import '../../core/models/models.dart';
import 'worker_chat_repository.dart';
import 'worker_feed_repository.dart';

export 'worker_chat_repository.dart';
export 'worker_feed_repository.dart';

class WorkerRepository with WorkerChatRepositoryMixin, WorkerFeedRepositoryMixin {
  WorkerRepository({ApiClient? client})
    : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  @override
  ApiClient get client => _client;

  @override
  Future<String?> getCurrentUserId() => _getCurrentUserId();
  /// Step 1: Send OTP for Job Seeker signup (POST /auth/signup/send-otp)
  Future<Map<String, dynamic>> signupSendOtp({
    required String firstName,
    required String lastName,
    required String contact,
    required List<String> skills,
  }) async {
    final cleanDigits = contact.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigitPhone = cleanDigits.length > 10
        ? cleanDigits.substring(cleanDigits.length - 10)
        : cleanDigits;
    final payload = {
      'name': firstName.trim(),
      'lastName': lastName.trim(),
      'phone': tenDigitPhone,
      'role': 'job_seeker',
      'skill': skills.isNotEmpty ? skills : ['Mason'],
    };
    final r = await _client.dio.post('/auth/signup/send-otp', data: payload);
    final d = r.data is Map ? (r.data['data'] ?? r.data) : null;
    if (d is Map) return Map<String, dynamic>.from(d);
    return const {'otpSent': true};
  }

  /// Step 2: Verify OTP for Job Seeker signup (POST /auth/signup/verify-otp)
  Future<Map<String, dynamic>> signupVerifyOtp({
    required String contact,
    required String otp,
  }) async {
    final cleanDigits = contact.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigitPhone = cleanDigits.length > 10
        ? cleanDigits.substring(cleanDigits.length - 10)
        : cleanDigits;
    final payload = {
      'phone': tenDigitPhone,
      'otp': otp.trim(),
    };
    final r = await _client.dio.post('/auth/signup/verify-otp', data: payload);
    final d = r.data is Map ? (r.data['data'] ?? r.data) : null;
    if (d is Map) return Map<String, dynamic>.from(d);
    return Map<String, dynamic>.from(r.data);
  }

  /// Step 3: Set Password for Job Seeker signup (POST /auth/signup/set-password)
  Future<Map<String, dynamic>> signupSetPassword({
    required String signupToken,
    required String password,
    required String confirmPassword,
  }) async {
    final payload = {
      'signupToken': signupToken.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
    };
    final r = await _client.dio.post('/auth/signup/set-password', data: payload);
    final d = r.data is Map ? (r.data['data'] ?? r.data) : null;
    if (d is Map) return Map<String, dynamic>.from(d);
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final isEmail = phone.contains('@');
    final payload = isEmail
        ? {'email': phone.trim().toLowerCase(), 'phone': phone.trim()}
        : {'phone': phone.trim()};
    final r = await _client.dio.post('/auth/request-otp', data: payload);
    final d = r.data is Map ? r.data['data'] : null;
    if (d is Map) return Map<String, dynamic>.from(d);
    return const {'otpSent': true};
  }
  Future<Map<String, dynamic>> verifyOtp({required String phone, required String otp}) async {
    final isEmail = phone.contains('@');
    final payload = isEmail
        ? {'email': phone.trim().toLowerCase(), 'phone': phone.trim(), 'otp': otp}
        : {'phone': phone.trim(), 'otp': otp};
    final r = await _client.dio.post('/auth/verify-otp', data: payload);
    return Map<String, dynamic>.from(r.data['data']);
  }

  /// Step 5: Sign in (POST /auth/login) with method: "phone" | "email"
  Future<Map<String, dynamic>> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    final cleanInput = phone.trim();
    final isEmail = cleanInput.contains('@');

    if (isEmail) {
      final r = await _client.dio.post('/auth/login', data: {
        'method': 'email',
        'email': cleanInput.toLowerCase(),
        'password': password,
      });
      // Response is top-level: { user, accessToken, refreshToken, expiresIn }
      final d = r.data is Map ? (r.data['data'] ?? r.data) : null;
      if (d is Map) return Map<String, dynamic>.from(d);
      return const {};
    }

    final sanitizedDigits = cleanInput.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigitPhone = sanitizedDigits.length > 10
        ? sanitizedDigits.substring(sanitizedDigits.length - 10)
        : sanitizedDigits;

    final r = await _client.dio.post('/auth/login', data: {
      'method': 'phone',
      'phone': tenDigitPhone,
      'password': password,
    });
    // Response is top-level: { user, accessToken, refreshToken, expiresIn }
    final d = r.data is Map ? (r.data['data'] ?? r.data) : null;
    if (d is Map) return Map<String, dynamic>.from(d);
    return const {};
  }

  Future<Map<String, dynamic>> setPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    final isEmail = phone.contains('@');
    final payload = isEmail
        ? {'email': phone.trim().toLowerCase(), 'phone': phone, 'otp': otp, 'newPassword': newPassword}
        : {'phone': phone, 'otp': otp, 'newPassword': newPassword};
    try {
      final r = await _client.dio.post('/auth/reset-password', data: payload);
      final d = r.data is Map ? (r.data['data'] ?? r.data) : null;
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {
      try {
        final r = await _client.dio.post('/auth/set-password', data: isEmail
            ? {'email': phone.trim().toLowerCase(), 'phone': phone, 'password': newPassword}
            : {'phone': phone, 'password': newPassword});
        final d = r.data is Map ? (r.data['data'] ?? r.data) : null;
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return const {'success': true};
  }
  Future<List<Job>> fetchJobs({String? query, String? location}) async {
    final Map<String, Job> jobMap = {};

    // 1. Fetch main jobs list
    try {
      final qParams = <String, dynamic>{};
      if (query != null && query.trim().isNotEmpty) {
        qParams['search'] = query.trim();
      }
      if (location != null && location.trim().isNotEmpty) {
        qParams['location'] = location.trim();
      }
      final response = await _client.dio.get(
        '/jobs',
        queryParameters: qParams.isEmpty ? null : qParams,
      );
      final payload = response.data;
      final items = payload['data'] != null 
          ? (payload['data']['items'] ?? payload['data']) 
          : payload['items'] ?? [];

      if (items is List) {
        for (final item in items) {
          if (item is Map) {
            try {
              final job = Job.fromJson(Map<String, dynamic>.from(item));
              if (job.id.isNotEmpty) {
                jobMap[job.id] = job;
              }
            } catch (itemErr) {
            }
          }
        }
      }
    } catch (e) {
    
      print('=== FETCH JOBS ERROR: $e ===');
    }

    try {
      final savedResponse = await _client.dio.get('/jobs/saved/list');
      final payload = savedResponse.data;
      final items = payload['data'] != null
          ? (payload['data']['items'] ?? payload['data'])
          : payload['items'] ?? [];
      if (items is List) {
        for (final item in items) {
          if (item is Map) {
            final sJob = Job.fromJson(Map<String, dynamic>.from(item));
            if (sJob.id.isNotEmpty) {
              final existing = jobMap[sJob.id];
              jobMap[sJob.id] = Job(
                id: sJob.id,
                title: sJob.title.isNotEmpty ? sJob.title : (existing?.title ?? 'Job Title'),
                company: sJob.company.isNotEmpty ? sJob.company : (existing?.company ?? 'Company'),
                location: sJob.location.isNotEmpty ? sJob.location : (existing?.location ?? 'Location'),
                dailyPay: sJob.dailyPay != 0 ? sJob.dailyPay : (existing?.dailyPay ?? 0),
                skills: sJob.skills.isNotEmpty ? sJob.skills : (existing?.skills ?? []),
                description: sJob.description.isNotEmpty ? sJob.description : (existing?.description ?? ''),
                requirements: sJob.requirements.isNotEmpty ? sJob.requirements : (existing?.requirements ?? []),
                saved: true,
                applied: existing?.applied ?? sJob.applied,
                applicationId: existing?.applicationId ?? sJob.applicationId,
                applicationStatus: existing?.applicationStatus ?? sJob.applicationStatus,
                projectType: sJob.projectType,
                experienceLevel: sJob.experienceLevel,
              );
            }
          }
        }
      }
    } catch (_) {}

    try {
      final appResponse = await _client.dio.get('/applications');
      final payload = appResponse.data;
      dynamic rawApps;
      if (payload is Map) {
        final d = payload['data'];
        if (d is List) {
          rawApps = d;
        } else if (d is Map) {
          rawApps = d['data'] ?? d['items'];
        } else {
          rawApps = payload['items'];
        }
      } else if (payload is List) {
        rawApps = payload;
      }

      if (rawApps is List) {
        for (final item in rawApps) {
          if (item is Map) {
            final appData = Map<String, dynamic>.from(item);
            final appId = appData['id']?.toString();
            final appStatus = appData['status']?.toString();
            final appRemarks = appData['reviewRemarks']?.toString() ??
                appData['remark']?.toString() ??
                appData['remarks']?.toString();
            final jobData = appData['job'] is Map ? Map<String, dynamic>.from(appData['job']) : null;
            final jobId = appData['jobId']?.toString() ?? jobData?['id']?.toString() ?? '';

            if (jobId.isNotEmpty) {
              final existing = jobMap[jobId];
              final aJob = jobData != null ? Job.fromJson(jobData) : null;
              jobMap[jobId] = Job(
                id: jobId,
                title: existing?.title ?? aJob?.title ?? 'Applied Role',
                company: existing?.company ?? aJob?.company ?? 'Company',
                location: existing?.location ?? aJob?.location ?? 'Location',
                dailyPay: (existing?.dailyPay ?? 0) != 0 ? (existing?.dailyPay ?? 0) : (aJob?.dailyPay ?? 0),
                skills: existing?.skills ?? aJob?.skills ?? [],
                description: existing?.description ?? aJob?.description ?? '',
                requirements: existing?.requirements ?? aJob?.requirements ?? [],
                saved: existing?.saved ?? false,
                applied: true,
                applicationId: appId ?? existing?.applicationId,
                applicationStatus: appStatus ?? existing?.applicationStatus ?? 'pending',
                reviewRemarks: appRemarks ?? existing?.reviewRemarks,
                projectType: existing?.projectType ?? aJob?.projectType ?? 'Full-time',
                experienceLevel: existing?.experienceLevel ?? aJob?.experienceLevel ?? 'Any',
              );
            }
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FETCH APPLICATIONS ERROR]: $e');
    }

    final resultList = jobMap.values.toList();
    // ignore: avoid_print
    print('--------------------------------------------------');
    // ignore: avoid_print
    print('📦 [REPOSITORY] Merged Jobs Count: ${resultList.length}');
    for (int i = 0; i < resultList.length; i++) {
      final j = resultList[i];
      // ignore: avoid_print
      print('  [$i] ID: ${j.id} | Title: "${j.title}" | Company: "${j.company}" | Pay: ₹${j.dailyPay} | Saved: ${j.saved} | Applied: ${j.applied} | Status: ${j.applicationStatus}');
    }
    // ignore: avoid_print
    print('--------------------------------------------------');
    return resultList;
  }

  Future<void> apply(String id, {Map<String, dynamic>? details}) async {
    final note = details?['coverNote']?.toString().trim();
    final safeNote = (note != null && note.isNotEmpty) ? note : 'I am interested in this job.';

    final hasExtra = details != null && details.keys.any((k) => k != 'coverNote');

    if (!hasExtra) {
      await _client.dio.post(
        '/applications/jobs/$id/apply',
        data: {'coverNote': safeNote},
      );
      return;
    }

    try {
      await _client.dio.post(
        '/applications/jobs/$id/apply',
        data: {
          'coverNote': safeNote,
          if (details['expectedDailyWage'] != null) 'expectedDailyWage': details['expectedDailyWage'],
          if (details['skills'] != null) 'skills': details['skills'],
          if (details['experienceYears'] != null) 'experienceYears': details['experienceYears'],
          if (details['availableFrom'] != null) 'availableFrom': details['availableFrom'],
          if (details['contactPhone'] != null) 'contactPhone': details['contactPhone'],
        },
      );
    } on DioException catch (e) {
      // Deployed backend rejects extra fields with 422. Fallback to only coverNote.
      if (e.response?.statusCode == 422) {
        await _client.dio.post(
          '/applications/jobs/$id/apply',
          data: {'coverNote': safeNote},
        );
        return;
      }
      rethrow;
    }
  }
  Future<void> save(String id) async => _client.dio.post('/jobs/$id/save');
  Future<void> unsave(String id) async {
    try {
      await _client.dio.delete('/jobs/$id/save');
    } catch (_) {
      // Fallback: POST /jobs/:id/save toggles save state on some backend schemas
      await _client.dio.post('/jobs/$id/save');
    }
  }
  Future<List<Job>> fetchSavedJobs() async {
    try {
      final response = await _client.dio.get('/jobs/saved/list');
      final payload = response.data;
      final items = payload['data'] != null ? (payload['data']['items'] ?? payload['data']) : (payload['items'] ?? []);
      return (items as List).map((e) => Job.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, int>> getJobCounts() async {
    try {
      final response = await _client.dio.get('/jobs/counts');
      final payload = response.data;
      final data = payload is Map ? (payload['data'] ?? payload) : payload;
      if (data is Map) {
        final activeJobs = (data['activeJobs'] as num?)?.toInt() ?? 0;
        final newJobsToday = (data['newJobsToday'] as num?)?.toInt() ?? 0;
        return {
          'activeJobs': activeJobs,
          'newJobsToday': newJobsToday,
        };
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [WorkerRepository] getJobCounts API error: $e');
    }
    return {'activeJobs': 0, 'newJobsToday': 0};
  }

  Future<List<Map<String, dynamic>>> fetchApplications() async {
    try {
      final response = await _client.dio.get('/applications');
      final payload = response.data;
      dynamic rawApps;
      if (payload is Map) {
        final d = payload['data'];
        if (d is List) {
          rawApps = d;
        } else if (d is Map) {
          rawApps = d['data'] ?? d['items'];
        } else {
          rawApps = payload['items'];
        }
      } else if (payload is List) {
        rawApps = payload;
      }
      if (rawApps is List) {
        return List<Map<String, dynamic>>.from(rawApps.whereType<Map>());
      }
      return [];
    } catch (_) {
      return [];
    }
  }
  Future<void> withdrawApplication(String applicationId, {String? jobId}) async {
    try {
      await _client.dio.post('/applications/$applicationId/withdraw');
    } on DioException catch (e) {
      if ((e.response?.statusCode == 404 || e.response?.statusCode == 400) && jobId != null && jobId.isNotEmpty) {
        try {
          await _client.dio.post('/applications/jobs/$jobId/withdraw');
          return;
        } catch (_) {}
      }
      rethrow;
    }
  }
  Future<void> reportJob({required String jobId, required String reason}) async =>
      _client.dio.post('/jobs/$jobId/report', data: {'reason': reason});
  Future<WorkerProfile> profile() async =>
      WorkerProfile.fromJson((await _client.dio.get('/profile')).data['data']);
  Future<WorkerProfile> updateProfile(Map<String, dynamic> body) async =>
      WorkerProfile.fromJson(
        (await _client.dio.put('/profile', data: body)).data['data'],
      );

  static String _mimeForFilename(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _client.dio.post(
      '/profile/photo',
      data: FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(_mimeForFilename(filename)),
        ),
      }),
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = response.data['data'];
    if (data is Map && data['profilePhotoUrl'] is String) {
      return data['profilePhotoUrl'] as String;
    }
    throw Exception(
      'Photo upload failed: server returned no profilePhotoUrl (${response.data})',
    );
  }

  Future<Map<String, dynamic>> uploadDocument({
    required List<int> bytes,
    required String filename,
    required String type,
  }) async {
    // ignore: avoid_print
    print('uploadDocument -> /documents type=$type bytes=${bytes.length}');
    final response = await _client.dio.post(
      '/documents',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(_mimeForFilename(filename)),
        ),
        'type': type,
      }),
      options: Options(contentType: 'multipart/form-data'),
    );
    // ignore: avoid_print
    print('uploadDocument <- ${response.statusCode} ${response.data}');
    return Map<String, dynamic>.from(response.data['data']);
  }
  Future<Attendance> checkIn() async => Attendance.fromJson(
    (await _client.dio.post(
      '/attendance/check-in',
      data: {'latitude': 30.210, 'longitude': 74.945},
    )).data['data'],
  );
  Future<Attendance> checkOut() async => Attendance.fromJson(
    (await _client.dio.post(
      '/attendance/check-out',
      data: {'latitude': 30.210, 'longitude': 74.945},
    )).data['data'],
  );
  Future<List<Attendance>> attendance() async =>
      ((await _client.dio.get('/attendance')).data['data']['items'] as List)
          .map((e) => Attendance.fromJson(e))
          .toList();
  Future<Map<String, dynamic>> dashboard() async => Map<String, dynamic>.from(
    (await _client.dio.get('/dashboard')).data['data'],
  );
  /// Returns the current user's ID from stored secure storage or JWT token
  Future<String?> _getCurrentUserId() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    var uid = await storage.read(key: 'userId');
    if (uid == null || uid.isEmpty) {
      final token = await storage.read(key: 'accessToken');
      if (token != null && token.isNotEmpty) {
        uid = _parseUserIdFromJwt(token);
      }
    }
    return uid;
  }

  static String? _parseUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(resp);
      if (payload is Map) {
        return payload['sub']?.toString() ??
            payload['id']?.toString() ??
            payload['userId']?.toString() ??
            payload['user_id']?.toString();
      }
    } catch (_) {}
    return null;
  }

}

