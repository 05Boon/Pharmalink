import 'package:dio/dio.dart';
import '../core/network/auth_interceptor.dart';
import '../models/stock_request_model.dart';

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
}
