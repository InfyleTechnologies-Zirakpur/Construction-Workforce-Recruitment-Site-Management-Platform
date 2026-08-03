import '../../core/api/api_client.dart';
import '../../core/models/models.dart';
import 'package:dio/dio.dart';

class WorkerRepository {
  WorkerRepository({ApiClient? client})
    : _client = client ?? ApiClient.instance;
  final ApiClient _client;
  Future<void> requestOtp(String phone) async =>
      _client.dio.post('/auth/request-otp', data: {'phone': phone});
  Future<void> verifyOtp({required String phone, required String otp}) async =>
      _client.dio.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp});
  Future<List<Job>> fetchJobs({String? query}) async {
    final response = await _client.dio.get(
      '/jobs',
      queryParameters: query == null ? null : {'search': query},
    );
    return (response.data['data']['items'] as List)
        .map((e) => Job.fromJson(e))
        .toList();
  }

  Future<void> apply(String id) async => _client.dio.post(
    '/jobs/$id/applications',
    data: {'coverNote': 'I am interested in this job.'},
  );
  Future<void> save(String id) async => _client.dio.post('/jobs/$id/save');
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
    final response = await _client.dio.post('/documents', data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: filename), 'type': type}), options: Options(contentType: 'multipart/form-data'));
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
  Future<List<Conversation>> conversations() async {
    final response = await _client.dio.get('/conversations');
    return (response.data['data']['items'] as List).map((item) => Conversation.fromJson(Map<String, dynamic>.from(item))).toList();
  }
  Future<void> sendMessage(String conversationId, String text) async => _client.dio.post('/conversations/$conversationId/messages', data: {'text': text});
  Future<List<WorkerNotification>> notifications() async {
    final response = await _client.dio.get('/notifications');
    return (response.data['data']['items'] as List).map((item) => WorkerNotification.fromJson(Map<String, dynamic>.from(item))).toList();
  }
  Future<void> markNotificationRead(String id) async => _client.dio.patch('/notifications/$id', data: {'isRead': true});
}
