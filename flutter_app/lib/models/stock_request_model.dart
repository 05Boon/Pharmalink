import 'alert_notification_model.dart';

class StockRequest {
  final String requestId;
  final String pharmacyId;
  final String requestedDrug;
  final int requiredQuantity;
  final int searchRadiusMeters;
  final String requestStatus;
  final DateTime createdAt;
  final List<AlertNotification> alerts;

  StockRequest({
    required this.requestId,
    required this.pharmacyId,
    required this.requestedDrug,
    required this.requiredQuantity,
    required this.searchRadiusMeters,
    required this.requestStatus,
    required this.createdAt,
    required this.alerts,
  });

  factory StockRequest.fromJson(Map<String, dynamic> json) {
    return StockRequest(
      requestId: json['request_id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      requestedDrug: json['requested_drug'] as String,
      requiredQuantity: json['required_quantity'] as int,
      searchRadiusMeters: json['search_radius_meters'] as int,
      requestStatus: json['request_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((item) => AlertNotification.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'pharmacy_id': pharmacyId,
      'requested_drug': requestedDrug,
      'required_quantity': requiredQuantity,
      'search_radius_meters': searchRadiusMeters,
      'request_status': requestStatus,
      'created_at': createdAt.toIso8601String(),
      'alerts': alerts.map((item) => item.toJson()).toList(),
    };
  }
}
