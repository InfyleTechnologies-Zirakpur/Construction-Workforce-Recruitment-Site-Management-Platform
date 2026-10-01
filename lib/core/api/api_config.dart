class ApiConfig {
  ApiConfig._();

  // Real backend — Render / Local
// static const String baseUrl = 'https://constructor-backend-bhah.onrender.com/api/v1';
 static const String baseUrl = 'http://192.168.1.8:3000/api/v1';
  static const bool useDummyApi = false;
  static const Duration connectTimeout = Duration(seconds: 30);
}


