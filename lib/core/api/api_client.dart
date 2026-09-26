import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';
import 'dummy_api_interceptor.dart';

class ApiClient {
  ApiClient._()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.connectTimeout,
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
    if (ApiConfig.useDummyApi) dio.interceptors.add(DummyApiInterceptor());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: 'accessToken');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // Single-session kick: 401 Session expired → clear and go to login
          if (e.response?.statusCode == 401) {
            const storage = FlutterSecureStorage();
            final msg = e.response?.data?['message']?.toString() ?? '';
            if (msg.contains('Session expired') || msg.contains('blocked')) {
              await storage.deleteAll();
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  final Dio dio;
  void clearAuth() {}
}
