class AlertNotification {
  final String? alertId;
  final String? requestId;
  final String? pharmacyId;
  final String status;
  final String createdAt;
  final Map<String, dynamic> raw;

  const AlertNotification({
    required this.alertId,
    required this.requestId,
    required this.pharmacyId,
    required this.status,
    required this.createdAt,
    required this.raw,
  });

  factory AlertNotification.fromJson(Map<String, dynamic> json) {
    return AlertNotification(
      alertId: _asNullableString(json['alert_id'] ?? json['id']),
      requestId: _asNullableString(json['request_id']),
      pharmacyId: _asNullableString(json['pharmacy_id']),
      status: _asString(json['status'], fallback: '-'),
      createdAt: _asString(json['created_at'] ?? json['time'], fallback: '-'),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...raw,
      'alert_id': alertId,
      'request_id': requestId,
      'pharmacy_id': pharmacyId,
      'status': status,
      'created_at': createdAt,
    };
  }

  static String _asString(dynamic value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    if (value != null) {
      return '$value';
    }
    return fallback;
  }

  static String? _asNullableString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    if (value != null) {
      return '$value';
    }
    return null;
  }
}
