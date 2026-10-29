import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_client.dart';
import '../../core/models/models.dart';

class ResumeStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _resumesKey = 'user_created_resumes';

  /// Standard network timeout for remote cloud database transactions
  static final _networkOptions = Options(
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );

  
  
  static Future<List<ResumeModel>> loadResumes() async {
    // 1. Try fetching from backend with short timeout
    try {
      final response = await ApiClient.instance.dio.get(
        '/resumes',
        options: _networkOptions,
      );
      final payload = response.data;
      final data = payload is Map ? (payload['data'] ?? payload) : payload;
      List<dynamic>? rawList;
      if (data is Map && data['items'] is List) {
        rawList = data['items'] as List;
      } else if (data is List) {
        rawList = data;
      }

      if (rawList != null) {
        final backendList = rawList
            .whereType<Map>()
            .map((e) => ResumeModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final localList = await _loadFromLocal();
        final localMap = {for (final r in localList) r.id: r};

        final mergedList = backendList.map((r) {
          final local = localMap[r.id];
          if (local != null && local.localPath != null && (r.localPath == null || r.localPath!.isEmpty)) {
            return r.copyWith(localPath: local.localPath);
          }
          return r;
        }).toList();

        for (final loc in localList) {
          if (!mergedList.any((r) => r.id == loc.id)) {
            mergedList.add(loc);
          }
        }

        // Cache to local storage
        await saveResumes(mergedList, syncWithBackend: false);
        return mergedList;
      }
    } catch (_) {}

    // 2. Fall back to local secure storage cache
    return _loadFromLocal();
  }

  static Future<List<ResumeModel>> _loadFromLocal() async {
    try {
      final jsonStr = await _storage.read(key: _resumesKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => ResumeModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Saves list of resumes locally
  static Future<void> saveResumes(List<ResumeModel> resumes, {bool syncWithBackend = true}) async {
    try {
      final encoded = jsonEncode(resumes.map((r) => r.toJson()).toList());
      await _storage.write(key: _resumesKey, value: encoded);
    } catch (_) {}
  }

  /// Adds or updates a resume both locally (instantly) and on backend
  static Future<ResumeModel> addOrUpdateResume(ResumeModel resume) async {
    // 1. Save to local storage first (instant responsiveness)
    final list = await _loadFromLocal();
    final index = list.indexWhere((r) => r.id == resume.id);
    if (index >= 0) {
      list[index] = resume;
    } else {
      list.insert(0, resume);
    }
    await saveResumes(list, syncWithBackend: false);

    // 2. Sync with backend POST /resumes
    try {
      final res = await ApiClient.instance.dio.post(
        '/resumes',
        data: resume.toJson(),
        options: _networkOptions,
      );
      // ignore: avoid_print
      print('✅ [ResumeStorageService] POST /resumes status: ${res.statusCode}');
      final payload = res.data;
      final data = payload is Map ? (payload['data'] ?? payload) : payload;
      if (data is Map) {
        final serverResume = ResumeModel.fromJson(Map<String, dynamic>.from(data));
        final merged = serverResume.copyWith(
          localPath: resume.localPath ?? serverResume.localPath,
          isUploadedFile: resume.isUploadedFile,
        );
        final idx = list.indexWhere((r) => r.id == merged.id);
        if (idx >= 0) {
          list[idx] = merged;
        } else {
          list.insert(0, merged);
        }
        await saveResumes(list, syncWithBackend: false);
        return merged;
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ [ResumeStorageService] POST /resumes error: $e');
    }
    return resume;
  }

  /// Deletes a resume both locally and from backend
  static Future<void> deleteResume(String id) async {
    // 1. Delete locally first
    final list = await _loadFromLocal();
    list.removeWhere((r) => r.id == id);
    await saveResumes(list, syncWithBackend: false);

    // 2. Attempt backend DELETE /resumes/:id
    try {
      await ApiClient.instance.dio.delete(
        '/resumes/$id',
        options: _networkOptions,
      );
    } catch (_) {}
  }
}
