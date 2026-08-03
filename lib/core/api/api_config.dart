/// Change this when the real backend is ready.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://api.buildhire.example/v1';

  /// Keep true while developing UI without a backend.
  static const bool useDummyApi = true;
  static const Duration connectTimeout = Duration(seconds: 20);
}
