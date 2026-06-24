import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/app_environment.dart';
import 'auth_service.dart';
import 'mock_data_store.dart';

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

  static Future<List<Map<String, dynamic>>> _safeGetList(
    String url,
    List<Map<String, String>> fallback,
  ) async {
    if (AppEnvironment.useMockData) {
      return fallback.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: _headers(),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallback.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      final decoded = _decodeBody(response.body);
      final list = _extractList(decoded);

      if (list.isEmpty) {
        return fallback.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      return list;
    } catch (_) {
      return fallback.map((item) => Map<String, dynamic>.from(item)).toList();
    }
  }

  static Future<Map<String, dynamic>> getOwnerDashboardData() async {
    final requests = await getIncomingRequests();
    final transactions = await getTransactionHistory();

    final activeQueries = MockDataStore.ownerActiveQueries
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return {
      'stats': {
        'active_queries': '${activeQueries.length}',
        'requests_received': '${requests.length}',
        'completed':
            '${transactions.where((txn) => '${txn['status']}'.toLowerCase() == 'completed').length}',
      },
      'recent_requests': requests,
      'active_queries': activeQueries,
    };
  }

  static Future<List<Map<String, dynamic>>> searchDrugs(String query) async {
    final encoded = Uri.encodeQueryComponent(query.trim());
    return _safeGetList(
      '${ApiConfig.drugsSearchUrl}?query=$encoded',
      MockDataStore.searchResults,
    );
  }

  static Future<List<Map<String, dynamic>>> getIncomingRequests() async {
    return _safeGetList(ApiConfig.requestsUrl, MockDataStore.incomingRequests);
  }

  static Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    return _safeGetList(
        ApiConfig.transactionsUrl, MockDataStore.transactionHistory);
  }

  static Future<Map<String, dynamic>> getSentRequestDetails() async {
    return Map<String, dynamic>.from(MockDataStore.sentRequest);
  }

  static Future<Map<String, dynamic>> getAcceptedRequestDetails() async {
    return Map<String, dynamic>.from(MockDataStore.acceptedRequest);
  }

  static Future<Map<String, dynamic>> getAdminDashboardData() async {
    final recentTransactions = await _safeGetList(
      ApiConfig.transactionsUrl,
      MockDataStore.adminRecentTransactions,
    );

    return {
      'stats': Map<String, dynamic>.from(MockDataStore.adminStats),
      'recent_transactions': recentTransactions,
      'pending_approvals': MockDataStore.adminPendingApprovals
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      'system_health': MockDataStore.adminSystemHealth
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    };
  }

  static Future<List<Map<String, dynamic>>> getPharmacies() async {
    return _safeGetList(ApiConfig.meUrl, MockDataStore.pharmacies);
  }

  static Future<Map<String, dynamic>> getOnboardingDetail(
      String pharmacyId) async {
    final detail = Map<String, dynamic>.from(MockDataStore.onboardingDetail);
    detail['id'] = pharmacyId;
    return detail;
  }

  static Future<List<Map<String, dynamic>>> getMonitorTransactions() async {
    return _safeGetList(
        ApiConfig.transactionsUrl, MockDataStore.monitorTransactions);
  }

  static Future<List<Map<String, dynamic>>> getAuditLogs() async {
    return _safeGetList(ApiConfig.requestsUrl, MockDataStore.auditLogs);
  }

  static Future<List<Map<String, dynamic>>> getReportCards() async {
    return MockDataStore.reportCards
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
