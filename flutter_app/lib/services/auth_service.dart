import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AuthService {
  static Map<String, dynamic>? _currentUser;
  static String? _accessToken;

  static Map<String, String> _headers({bool withAuth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth && _accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  static Map<String, dynamic>? _decodeJsonBody(String body) {
    if (body.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _failure({
    required String code,
    required String message,
  }) {
    return {
      'ok': false,
      'error': {'code': code, 'message': message}
    };
  }

  static Map<String, dynamic> _successFromBody(Map<String, dynamic>? body) {
    if (body == null) {
      return {'ok': true, 'message': 'Success'};
    }

    if (body.containsKey('ok')) {
      return body;
    }

    return {
      'ok': true,
      'data': body,
      'message': body['message'] ?? 'Success',
    };
  }

  static String _extractErrorMessage(Map<String, dynamic>? body, int statusCode) {
    if (body == null) {
      return 'Request failed with status $statusCode';
    }

    final error = body['error'];
    if (error is Map<String, dynamic> && error['message'] is String) {
      return error['message'] as String;
    }

    if (body['message'] is String) {
      return body['message'] as String;
    }

    return 'Request failed with status $statusCode';
  }

  static void _cacheLoginState(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is! Map<String, dynamic>) return;

    final tokenCandidate = data['access_token'] ?? data['token'] ?? data['jwt'];
    if (tokenCandidate is String && tokenCandidate.isNotEmpty) {
      _accessToken = tokenCandidate;
    }

    final userCandidate = data['pharmacy'] ?? data['user'] ?? data['me'];
    if (userCandidate is Map<String, dynamic>) {
      _currentUser = userCandidate;
      return;
    }

    if (data.containsKey('id') || data.containsKey('email') || data.containsKey('name')) {
      _currentUser = {
        'id': data['id'],
        'name': data['name'],
        'email': data['email'],
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: _headers(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final body = _decodeJsonBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _failure(
          code: 'REGISTER_FAILED',
          message: _extractErrorMessage(body, response.statusCode),
        );
      }

      return _successFromBody(body);
    } catch (e) {
      return _failure(code: 'REGISTER_FAILED', message: e.toString());
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final body = _decodeJsonBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _failure(
          code: 'INVALID_CREDENTIALS',
          message: _extractErrorMessage(body, response.statusCode),
        );
      }

      final result = _successFromBody(body);
      if (result['ok'] == true) {
        _cacheLoginState(result);
      }

      return result;
    } catch (e) {
      return _failure(code: 'LOGIN_FAILED', message: e.toString());
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.logoutUrl),
        headers: _headers(withAuth: true),
      );

      final body = _decodeJsonBody(response.body);
      _accessToken = null;
      _currentUser = null;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _failure(
          code: 'LOGOUT_FAILED',
          message: _extractErrorMessage(body, response.statusCode),
        );
      }

      return {'ok': true, 'message': 'Logged out'};
    } catch (e) {
      _accessToken = null;
      _currentUser = null;
      return _failure(code: 'LOGOUT_FAILED', message: e.toString());
    }
  }

  static Map<String, dynamic>? getMe() {
    return _currentUser;
  }

  static bool isLoggedIn() {
    return _currentUser != null;
  }
}