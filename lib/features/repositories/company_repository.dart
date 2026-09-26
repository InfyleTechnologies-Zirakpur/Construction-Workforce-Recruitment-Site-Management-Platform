import '../../core/api/api_client.dart';
import 'package:dio/dio.dart';

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
      if (phone != null) 'phone': phone,
      'role': 'company',
    });
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  Future<Map<String, dynamic>> loginCompany({required String email, required String password}) async {
    final r = await _client.dio.post('/auth/login', data: {'email': email, 'password': password});
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  Future<Map<String, dynamic>> createCompanyProfile(Map<String, dynamic> body) async {
    final r = await _client.dio.post('/companies', data: body);
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> body) async {
    final r = await _client.dio.post('/jobs', data: body);
    return Map<String, dynamic>.from(r.data['data'] ?? r.data);
  }

  Future<List<Map<String, dynamic>>> myApplications() async {
    final r = await _client.dio.get('/applications');
    final d = r.data['data'];
    if (d is Map && d['data'] is List) return List<Map<String, dynamic>>.from(d['data']);
    if (d is List) return List<Map<String, dynamic>>.from(d);
    return [];
  }
}
