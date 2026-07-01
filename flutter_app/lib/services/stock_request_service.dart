import '../core/network/auth_interceptor.dart';
import '../models/stock_request.dart';
import '../models/alert_notification.dart';

class StockRequestService {
  final String baseUrl;

  StockRequestService(this.baseUrl);

  /// Creates a stock request and broadcasts alerts to neighboring pharmacies
  Future<StockRequest> createStockRequest({
    required String requestedDrug,
    required int requiredQuantity,
    int searchRadiusMeters = 2000,
  }) async {
    final response = await dio.post(
      '$baseUrl/broadcasts/request',
      data: {
        'requested_drug': requestedDrug,
        'required_quantity': requiredQuantity,
        'search_radius_meters': searchRadiusMeters,
      },
    );

    if (response.statusCode == 201) {
      return StockRequest.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create stock request');
    }
  }

  /// Fetches all active (PENDING) stock requests created by the authenticated pharmacy
  Future<List<StockRequest>> fetchMyRequests() async {
    final response = await dio.get('$baseUrl/broadcasts/active-requests');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((item) => StockRequest.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load active requests');
    }
  }

  /// Fetches unread alert notifications sent to the authenticated pharmacy
  Future<List<AlertNotification>> fetchMyAlerts() async {
    final response = await dio.get('$baseUrl/broadcasts/alerts/unread');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((item) => AlertNotification.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load unread alerts');
    }
  }
}
