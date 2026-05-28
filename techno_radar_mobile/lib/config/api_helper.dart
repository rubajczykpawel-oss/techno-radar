import 'package:shared_preferences/shared_preferences.dart';

class ApiHelper {
  static const String localBaseUrl = 'http://127.0.0.1:8000';

  static const String prodBaseUrl =
      'https://web-production-5db5f.up.railway.app';

  static const String baseUrl = prodBaseUrl;

  static Future<Map<String, String>> headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("is_admin") ?? false;
  }
}
