import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/alert_notification.dart';
import '../models/inventory_item.dart';
import '../models/stock_request.dart';
import 'app_dio.dart';
import 'auth_service.dart';

class NetworkDataService {
  NetworkDataService._();

  static final Dio _dio = AppDio.instance;

  static bool _isOpenRequestStatus(String status) {
    // Shared filter for actionable request states in responder views.
    final normalized = status.trim().toUpperCase();
    if (normalized.isEmpty) return true;
    return normalized != 'FULFILLED' &&
        normalized != 'ACCEPTED' &&
        normalized != 'DECLINED' &&
        normalized != 'CLOSED';
  }

  static String? _currentPharmacyId() {
    // Resolve active pharmacy identity from auth cache/session.
    final cachedId = '${AuthService.currentUser?['id'] ?? ''}'.trim();
    if (cachedId.isNotEmpty) {
      return cachedId;
    }

    final sessionId = '${AuthService.getMe()?['id'] ?? ''}'.trim();
    if (sessionId.isNotEmpty) {
      return sessionId;
    }

    return null;
  }

  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static dynamic _normalizeResponseData(dynamic data) {
    if (data is String) {
      return _decodeBody(data);
    }
    return data;
  }

  static void _throwForBadStatus(Response<dynamic> response) {
    final statusCode = response.statusCode ?? 0;
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    throw Exception('Request failed with status $statusCode');
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

  static T _extractModel<T>(
    dynamic decoded,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return decode(data);
      }
      return decode(decoded);
    }

    throw Exception('Unexpected response format');
  }

  static List<T> _extractModelList<T>(
    dynamic decoded,
    T Function(Map<String, dynamic>) decode,
  ) {
    final list = _extractList(decoded);
    return list.map(decode).toList();
  }

  static Future<List<Map<String, dynamic>>> _getList(String url) async {
    final response = await _dio.get(url);
    _throwForBadStatus(response);
    final decoded = _normalizeResponseData(response.data);
    return _extractList(decoded);
  }

  static Future<Map<String, dynamic>> _getMap(String url) async {
    final response = await _dio.get(url);
    _throwForBadStatus(response);
    final decoded = _normalizeResponseData(response.data);
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return decoded;
    }

    throw Exception('Unexpected response format');
  }

  static Future<List<T>> _getModelList<T>(
    String url,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final response = await _dio.get(url);
    _throwForBadStatus(response);
    final decoded = _normalizeResponseData(response.data);
    return _extractModelList(decoded, decode);
  }

  static Future<T> _getModel<T>(
    String url,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final response = await _dio.get(url);
    _throwForBadStatus(response);
    final decoded = _normalizeResponseData(response.data);
    return _extractModel(decoded, decode);
  }

  static Future<Map<String, dynamic>> _postMap(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(url, data: body);
    _throwForBadStatus(response);
    final decoded = _normalizeResponseData(response.data);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{'data': decoded};
  }

  static Future<Map<String, dynamic>> _patchMap(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch(url, data: body);
    _throwForBadStatus(response);
    final decoded = _normalizeResponseData(response.data);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{'data': decoded};
  }

  static Future<Map<String, dynamic>> _deleteMap(
    String url,
  ) async {
    final response = await _dio.delete(url);
    _throwForBadStatus(response);
    if (response.data == null || response.data.toString().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = _normalizeResponseData(response.data);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{'data': decoded};
  }

  static Future<Map<String, dynamic>> createStockRequestAndBroadcast({
    required String requestedDrug,
    required int requiredQuantity,
    required int searchRadiusMeters,
  }) async {
    // Core flow: creating a request triggers backend geo-search + auto-broadcast
    // to nearby pharmacies. The requester receives only a summary notification.
    return _postMap(
      '${ApiConfig.baseUrl}/broadcasts/request',
      <String, dynamic>{
        'requested_drug': requestedDrug,
        'required_quantity': requiredQuantity,
        'search_radius_meters': searchRadiusMeters * 1000,
      },
    );
  }

  static Future<Map<String, dynamic>> respondToIncomingRequest({
    required String requestId,
    required bool accepted,
  }) async {
    // Core flow: responders can accept/decline; backend enforces first-accept
    // winner semantics and emits fulfillment events to other responders.
    final status = accepted ? 'ACCEPTED' : 'DECLINED';
    final paths = <String>[
      '${ApiConfig.requestsUrl}/$requestId/respond',
      '${ApiConfig.requestsUrl}/$requestId/status',
      '${ApiConfig.requestsUrl}/$requestId',
    ];

    Object? lastError;
    for (final path in paths) {
      try {
        return await _patchMap(path, <String, dynamic>{
          'status': status,
          'decision': status,
          'action': status,
        });
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Failed to update request status: $lastError');
  }

  static Future<Map<String, dynamic>> reviewOnboardingPharmacy({
    required String pharmacyId,
    required bool approved,
  }) async {
    final status = approved ? 'APPROVED' : 'REJECTED';
    final paths = <String>[
      '${ApiConfig.baseUrl}/admin/pharmacies/$pharmacyId/onboarding',
      '${ApiConfig.baseUrl}/admin/pharmacies/$pharmacyId/review',
      '${ApiConfig.baseUrl}/admin/pharmacies/$pharmacyId/status',
    ];

    Object? lastError;
    for (final path in paths) {
      try {
        return await _patchMap(path, <String, dynamic>{
          'status': status,
          'approved': approved,
          'decision': status,
        });
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception('Failed to submit onboarding decision: $lastError');
  }

  static Future<List<StockRequest>> getIncomingRequestModels() async {
    final allRequests =
        await _getModelList(ApiConfig.requestsUrl, StockRequest.fromJson);
    final currentUserId = _currentPharmacyId();
    return allRequests.where((request) {
      if (!_isOpenRequestStatus(request.requestStatus)) {
        return false;
      }
      if (currentUserId == null) {
        return true;
      }
      return request.pharmacyId != currentUserId;
    }).toList();
  }

  static Future<StockRequest> getSentRequestModel() async {
    return _getModel(
      '${ApiConfig.requestsUrl}/sent/current',
      StockRequest.fromJson,
    );
  }

  static Future<StockRequest> getAcceptedRequestModel() async {
    return _getModel(
      '${ApiConfig.requestsUrl}/accepted/current',
      StockRequest.fromJson,
    );
  }

  static Future<List<InventoryItem>> getInventoryModelsForPharmacy(
    String pharmacyId,
  ) async {
    return _getModelList(
      '${ApiConfig.baseUrl}/admin/pharmacies/$pharmacyId/inventory',
      InventoryItem.fromJson,
    );
  }

  static Future<List<Map<String, dynamic>>> getMyInventory() async {
    return _getList('${ApiConfig.baseUrl}/inventory');
  }

  static Future<Map<String, dynamic>> addInventoryItem(
      Map<String, dynamic> data) async {
    return _postMap('${ApiConfig.baseUrl}/inventory', data);
  }

  static Future<Map<String, dynamic>> updateInventoryQuantity(
      String itemId, int quantity) async {
    return _patchMap(
        '${ApiConfig.baseUrl}/inventory/$itemId', {'stock_quantity': quantity});
  }

  static Future<void> deleteInventoryItem(String itemId) async {
    await _deleteMap('${ApiConfig.baseUrl}/inventory/$itemId');
  }

  static Future<List<AlertNotification>> getAlertNotificationModels() async {
    return _getModelList(
      '${ApiConfig.baseUrl}/alerts',
      AlertNotification.fromJson,
    );
  }

  static Future<Map<String, dynamic>> getOwnerDashboardData() async {
    // Owner home screen summary metrics and lists.
    return _getMap('${ApiConfig.baseUrl}/dashboard');
  }

  static Future<List<Map<String, dynamic>>> searchDrugs(String query) async {
    final encoded = Uri.encodeQueryComponent(query.trim());
    return _getList('${ApiConfig.drugsSearchUrl}?query=$encoded');
  }

  static Future<List<Map<String, dynamic>>> getIncomingRequests() async {
    // Responder inbox source: open requests not created by the current pharmacy.
    final requests = await _getList(ApiConfig.requestsUrl);
    final currentUserId = _currentPharmacyId();
    return requests.where((request) {
      final status = '${request['request_status'] ?? ''}';
      if (!_isOpenRequestStatus(status)) {
        return false;
      }

      if (currentUserId == null) {
        return true;
      }

      final pharmacyId = '${request['pharmacy_id'] ?? ''}';
      return pharmacyId != currentUserId;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    return _getList(ApiConfig.transactionsUrl);
  }

  static Future<Map<String, dynamic>> getSentRequestDetails() async {
    return _getMap('${ApiConfig.requestsUrl}/sent/current');
  }

  static Future<List<Map<String, dynamic>>> getSentRequestsDetails() async {
    return _getList('${ApiConfig.requestsUrl}/sent');
  }

  static Future<Map<String, dynamic>> getAcceptedRequestDetails() async {
    final request = await getAcceptedRequestModel();
    return request.toJson();
  }

  static Future<Map<String, dynamic>> getAdminDashboardData() async {
    return _getMap('${ApiConfig.baseUrl}/admin/dashboard');
  }

  static Future<List<Map<String, dynamic>>> getPharmacies() async {
    // Admin pharmacy management table source.
    return _getList('${ApiConfig.baseUrl}/admin/pharmacies');
  }

  static Future<void> deletePharmacy(String pharmacyId) async {
    // Admin destructive action with backend rule feedback surfaced to UI.
    try {
      await _deleteMap('${ApiConfig.baseUrl}/admin/pharmacies/$pharmacyId');
    } on DioException catch (error) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['detail'] != null) {
        throw Exception('${responseData['detail']}');
      }
      throw Exception('Failed to delete pharmacy.');
    }
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
}
