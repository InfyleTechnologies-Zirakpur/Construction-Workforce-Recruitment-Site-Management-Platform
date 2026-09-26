class ApiConfig {
  ApiConfig._();

  // Real backend — Render
  static const String baseUrl = 'https://constructor-backend-bhah.onrender.com/api/v1';
  static const bool useDummyApi = false;
  static const Duration connectTimeout = Duration(seconds: 30);
}
