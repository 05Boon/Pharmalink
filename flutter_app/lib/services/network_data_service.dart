import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class NetworkDataService {
  NetworkDataService._();

  static final http.Client _client = http.Client();

  static Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = AuthService.accessToken;
    if (withAuth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => item.map((key, val) => MapEntry('$key', val)))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static List<Map<String, dynamic>> _extractList(dynamic decoded) {
    if (decoded is List) {
      return _toMapList(decoded);
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['items'] ?? decoded['results'];
      if (data != null) {
        return _toMapList(data);
      }
    }

    return <Map<String, dynamic>>[];
  }

  static Future<List<Map<String, dynamic>>> _getList(String url) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }

    final decoded = _decodeBody(response.body);
    return _extractList(decoded);
  }

  static Future<Map<String, dynamic>> _getMap(String url) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }

    final decoded = _decodeBody(response.body);
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return decoded;
    }

    throw Exception('Unexpected response format');
  }

  static Future<Map<String, dynamic>> getOwnerDashboardData() async {
    return _getMap('${ApiConfig.baseUrl}/dashboard');
  }

  static Future<List<Map<String, dynamic>>> searchDrugs(String query) async {
    final encoded = Uri.encodeQueryComponent(query.trim());
    return _getList('${ApiConfig.drugsSearchUrl}?query=$encoded');
  }

  static Future<List<Map<String, dynamic>>> getIncomingRequests() async {
    return _getList(ApiConfig.requestsUrl);
  }

  static Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    return _getList(ApiConfig.transactionsUrl);
  }

  static Future<Map<String, dynamic>> getSentRequestDetails() async {
    return _getMap('${ApiConfig.requestsUrl}/sent/current');
  }

  static Future<Map<String, dynamic>> getAcceptedRequestDetails() async {
    return _getMap('${ApiConfig.requestsUrl}/accepted/current');
  }

  static Future<Map<String, dynamic>> getAdminDashboardData() async {
    return _getMap('${ApiConfig.baseUrl}/admin/dashboard');
  }

  static Future<List<Map<String, dynamic>>> getPharmacies() async {
    return _getList('${ApiConfig.baseUrl}/admin/pharmacies');
  }

  static Future<Map<String, dynamic>> getOnboardingDetail(
      String pharmacyId) async {
    return _getMap('${ApiConfig.baseUrl}/admin/pharmacies/$pharmacyId');
  }

  static Future<List<Map<String, dynamic>>> getMonitorTransactions() async {
    return _getList('${ApiConfig.baseUrl}/admin/transactions');
  }

  static Future<List<Map<String, dynamic>>> getAuditLogs() async {
    return _getList('${ApiConfig.baseUrl}/admin/logs');
  }

  static Future<List<Map<String, dynamic>>> getReportCards() async {
    return _getList('${ApiConfig.baseUrl}/admin/reports');
  }
}
