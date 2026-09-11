/// Change this when the real backend is ready.
class ApiConfig {
  ApiConfig._();

  // static const String baseUrl = 'https://api.buildhire.example/v1';
  static const String baseUrl = 'https://marigold-axis-staging.ngrok-free.dev/api/v1';

  /// Keep true while developing UI without a backend.
  static const bool useDummyApi = false;
  static const Duration connectTimeout = Duration(seconds: 20);
}

