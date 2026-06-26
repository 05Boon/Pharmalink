class StockRequest {
  final String? requestId;
  final String from;
  final String drugName;
  final int quantity;
  final String createdAt;
  final String status;
  final Map<String, dynamic> raw;

  const StockRequest({
    required this.requestId,
    required this.from,
    required this.drugName,
    required this.quantity,
    required this.createdAt,
    required this.status,
    required this.raw,
  });

  factory StockRequest.fromJson(Map<String, dynamic> json) {
    final quantityCandidate = json['qty'] ?? json['quantity'];
    return StockRequest(
      requestId: _asNullableString(json['request_id'] ?? json['id']),
      from: _asString(json['from'] ?? json['source'], fallback: '-'),
      drugName: _asString(json['drug'] ?? json['drug_name'], fallback: '-'),
      quantity: _asInt(quantityCandidate),
      createdAt: _asString(json['time'] ?? json['created_at'], fallback: '-'),
      status: _asString(json['status'], fallback: 'Pending'),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...raw,
      'request_id': requestId,
      'from': from,
      'drug_name': drugName,
      'quantity': quantity,
      'created_at': createdAt,
      'status': status,
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

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
