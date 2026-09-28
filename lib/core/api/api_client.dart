import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../main.dart';
import '../../screens/auth/login_screen.dart';
import 'api_config.dart';
import 'dummy_api_interceptor.dart';

class ApiClient {
  static String? accessToken;

  ApiClient._()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.connectTimeout,
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
   // if (ApiConfig.useDummyApi) dio.interceptors.add(DummyApiInterceptor());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          const storage = FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );
          try {
            final token = await storage.read(key: 'accessToken');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          // ignore: avoid_print
          print('🌐 [API REQ] ${options.method} ${options.baseUrl}${options.path}');
          if (options.data != null) {
            // ignore: avoid_print
            print('   Payload: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print('✅ [API RES] ${response.requestOptions.method} ${response.requestOptions.path} (${response.statusCode})');
          // ignore: avoid_print
          print('   Data: ${response.data}');
          handler.next(response);
        },
        onError: (e, handler) async {
          // ignore: avoid_print
          print('❌ [API ERR] ${e.requestOptions.method} ${e.requestOptions.path} (${e.response?.statusCode})');
          // ignore: avoid_print
          print('   Error Data: ${e.response?.data ?? e.message}');
          if (e.response?.statusCode == 401) {
            const storage = FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );
            final msg = e.response?.data?['message']?.toString() ?? '';
            if (msg.contains('Session expired') || msg.contains('Unauthorized') || msg.contains('blocked')) {
              await storage.deleteAll();
              final navState = navigatorKey.currentState;
              if (navState != null && navState.mounted) {
                ScaffoldMessenger.of(navState.context).showSnackBar(
                  const SnackBar(
                    content: Text('Session expired. Please log in again.'),
                    backgroundColor: Colors.red,
                  ),
                );
                navState.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
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
