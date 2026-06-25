class InventoryItem {
  final String itemId;
  final String pharmacyId;
  final String drugName;
  final String? drugCategory;
  final int stockQuantity;
  final DateTime lastUpdated;

  InventoryItem({
    required this.itemId,
    required this.pharmacyId,
    required this.drugName,
    this.drugCategory,
    required this.stockQuantity,
    required this.lastUpdated,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      itemId: json['item_id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      drugName: json['drug_name'] as String,
      drugCategory: json['drug_category'] as String?,
      stockQuantity: json['stock_quantity'] as int,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'pharmacy_id': pharmacyId,
      'drug_name': drugName,
      'drug_category': drugCategory,
      'stock_quantity': stockQuantity,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
