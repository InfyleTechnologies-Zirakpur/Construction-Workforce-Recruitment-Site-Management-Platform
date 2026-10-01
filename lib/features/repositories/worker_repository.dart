import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_client.dart';
import '../../core/models/models.dart';

class WorkerRepository {
  WorkerRepository({ApiClient? client})
    : _client = client ?? ApiClient.instance;
  final ApiClient _client;
  Future<void> requestOtp(String phone) async =>
      _client.dio.post('/auth/request-otp', data: {'phone': phone});
  Future<Map<String, dynamic>> verifyOtp({required String phone, required String otp}) async {
    final r = await _client.dio.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp});
    return Map<String, dynamic>.from(r.data['data']);
  }
  Future<List<Job>> fetchJobs({String? query}) async {
    final Map<String, Job> jobMap = {};

    // 1. Fetch main jobs list
    try {
      final response = await _client.dio.get(
        '/jobs',
        queryParameters: query == null ? null : {'search': query},
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
              // ignore: avoid_print
              print('⚠️ [JOB PARSE ERROR] Skipping malformed job item: $itemErr');
            }
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('=== FETCH JOBS ERROR: $e ===');
    }

    // 2. Fetch saved jobs list to ensure saved jobs are included
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

    // 3. Fetch applications to ensure applied jobs are included & statuses are updated
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
    final body = <String, dynamic>{
      'coverNote': (note != null && note.isNotEmpty) ? note : 'I am interested in this job.',
    };

    await _client.dio.post(
      '/applications/jobs/$id/apply',
      data: body,
    );
  }
  Future<void> save(String id) async => _client.dio.post('/jobs/$id/save');
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
  Future<String> uploadProfilePhoto({required List<int> bytes, required String filename}) async {
    final response = await _client.dio.post('/profile/photo', data: FormData.fromMap({'photo': MultipartFile.fromBytes(bytes, filename: filename)}), options: Options(contentType: 'multipart/form-data'));
    return response.data['data']['profilePhotoUrl'] as String;
  }
  Future<Map<String, dynamic>> uploadDocument({required List<int> bytes, required String filename, required String type}) async {
    final form = FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: filename), 'type': type});
    // Debug: ensure token is sent
    // ignore: avoid_print
    print('uploadDocument -> /documents type=$type bytes=${bytes.length}');
    final response = await _client.dio.post('/documents', data: form, options: Options(contentType: 'multipart/form-data'));
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

  Future<List<Conversation>> conversations() async {
    final response = await _client.dio.get('/conversations');
    final currentUserId = await _getCurrentUserId();
    final raw = response.data;
    List items = [];
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) {
        items = d;
      } else if (d is Map) {
        if (d['data'] is List) items = d['data'];
        else if (d['items'] is List) items = d['items'];
      }
    } else if (raw is List) {
      items = raw;
    }
    return items.map((item) => Conversation.fromJson(Map<String, dynamic>.from(item), currentUserId: currentUserId)).toList();
  }

  Future<Conversation?> getConversationById(String conversationId) async {
    try {
      final response = await _client.dio.get('/conversations/$conversationId');
      final currentUserId = await _getCurrentUserId();
      final raw = response.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      if (data is Map) {
        return Conversation.fromJson(Map<String, dynamic>.from(data), currentUserId: currentUserId);
      }
    } catch (_) {}
    return null;
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final response = await _client.dio.get('/conversations/$conversationId/messages');
    final currentUserId = await _getCurrentUserId();
    final raw = response.data;
    List items = [];
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) items = d;
      else if (d is Map && d['data'] is List) items = d['data'];
      else if (d is Map && d['items'] is List) items = d['items'];
    } else if (raw is List) {
      items = raw;
    }
    return items.map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item), currentUserId: currentUserId)).toList();
  }

  Future<void> sendMessage(String conversationId, String text) async =>
      _client.dio.post('/conversations/$conversationId/messages', data: {'text': text});

  Future<void> markConversationRead(String conversationId) async =>
      _client.dio.patch('/conversations/$conversationId/read');

  Future<List<WorkerNotification>> notifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _client.dio.get('/notifications', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final payload = response.data;
      dynamic itemsRaw;
      if (payload['data'] is Map) {
        if (payload['data']['data'] is Map && payload['data']['data']['items'] is List) {
          itemsRaw = payload['data']['data']['items'];
        } else if (payload['data']['items'] is List) {
          itemsRaw = payload['data']['items'];
        }
      } else if (payload['items'] is List) {
        itemsRaw = payload['items'];
      } else if (payload['data'] is List) {
        itemsRaw = payload['data'];
      }
      if (itemsRaw is List) {
        return itemsRaw.map((item) => WorkerNotification.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<int> unreadNotificationsCount() async {
    try {
      final response = await _client.dio.get('/notifications', queryParameters: {'page': 1, 'limit': 1});
      final payload = response.data;
      if (payload['data'] is Map && payload['data']['unreadCount'] != null) {
        return (payload['data']['unreadCount'] as num).toInt();
      }
      if (payload['data'] is Map && payload['data']['data'] is Map && payload['data']['data']['unreadCount'] != null) {
        return (payload['data']['data']['unreadCount'] as num).toInt();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markNotificationRead(String id) async =>
      _client.dio.patch('/notifications/$id/read');

  Future<void> markAllNotificationsRead() async =>
      _client.dio.patch('/notifications/read-all');

  Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
    try {
      final response = await _client.dio.post('/notifications/register-device', data: {
        'token': token,
        'platform': platform,
      });
      // ignore: avoid_print
      print('🔔 [WorkerRepository] registerDeviceToken response: ${response.statusCode}');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [WorkerRepository] registerDeviceToken failed: $e');
    }
  }

  Future<void> unregisterDeviceToken(String token) async {
    try {
      await _client.dio.delete('/notifications/unregister-device', data: {
        'token': token,
      });
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [WorkerRepository] unregisterDeviceToken failed: $e');
    }
  }

  Future<void> logout({String? fcmToken}) async {
    try {
      await _client.dio.post('/auth/logout', data: {
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      });
    } catch (_) {}
  }
}
