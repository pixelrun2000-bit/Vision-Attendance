class ApiConfig {
  static const String baseUrl = "http://192.168.1.2:3001";

  static Uri loginUrl() {
    return Uri.parse("$baseUrl/api/auth/login");
  }
}
final url = ApiConfig.loginUrl();