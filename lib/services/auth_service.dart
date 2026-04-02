import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static String? _accessToken;
  static String? _refreshToken;

  static String? get accessToken => _accessToken;
  static bool get isLoggedIn => (_accessToken ?? '').isNotEmpty;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
  }

  static Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'nickname': nickname,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(_extractMessage(response.body, fallback: '회원가입에 실패했습니다.'));
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(response.body, fallback: '로그인에 실패했습니다.'));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? {};
    _accessToken = data['accessToken'] as String?;
    _refreshToken = data['refreshToken'] as String?;

    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(_accessTokenKey, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(_refreshTokenKey, _refreshToken!);
    }
  }

  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static String requireAccessToken() {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요합니다. 다시 로그인해주세요.');
    }
    return token;
  }

  static Map<String, String> authorizedHeaders({Map<String, String>? extra}) {
    return {'Authorization': 'Bearer ${requireAccessToken()}', ...?extra};
  }

  static String _extractMessage(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
