import 'package:dio/dio.dart';
import 'api_config.dart';
import 'dummy_api_interceptor.dart';

/// The only place that creates Dio. Repositories must use this client.
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
        onRequest: (options, handler) {
          // Add secure token here after login: options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  final Dio dio;
}
