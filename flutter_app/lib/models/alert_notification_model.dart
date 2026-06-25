class AlertNotification {
  final String alertId;
  final String requestId;
  final String receivingPharmacyId;
  final String alertStatus;
  final DateTime deliveredAt;

  AlertNotification({
    required this.alertId,
    required this.requestId,
    required this.receivingPharmacyId,
    required this.alertStatus,
    required this.deliveredAt,
  });

  factory AlertNotification.fromJson(Map<String, dynamic> json) {
    return AlertNotification(
      alertId: json['alert_id'] as String,
      requestId: json['request_id'] as String,
      receivingPharmacyId: json['receiving_pharmacy_id'] as String,
      alertStatus: json['alert_status'] as String,
      deliveredAt: DateTime.parse(json['delivered_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_id': alertId,
      'request_id': requestId,
      'receiving_pharmacy_id': receivingPharmacyId,
      'alert_status': alertStatus,
      'delivered_at': deliveredAt.toIso8601String(),
    };
  }
}
