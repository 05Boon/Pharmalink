class InventoryItem {
  final String? itemId;
  final String pharmacyId;
  final String drugName;
  final int stockQuantity;
  final Map<String, dynamic> raw;

  const InventoryItem({
    required this.itemId,
    required this.pharmacyId,
    required this.drugName,
    required this.stockQuantity,
    required this.raw,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      itemId: _asNullableString(json['item_id'] ?? json['id']),
      pharmacyId: _asString(json['pharmacy_id'], fallback: ''),
      drugName: _asString(json['drug_name'] ?? json['drug'], fallback: '-'),
      stockQuantity: _asInt(json['stock_quantity'] ?? json['qty']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...raw,
      'item_id': itemId,
      'pharmacy_id': pharmacyId,
      'drug_name': drugName,
      'stock_quantity': stockQuantity,
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
