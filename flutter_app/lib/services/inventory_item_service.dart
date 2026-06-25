import 'package:dio/dio.dart';
import '../core/network/auth_interceptor.dart';
import '../models/inventory_item_model.dart';

class InventoryItemService {
  final String baseUrl;

  InventoryItemService(this.baseUrl);

  /// Retrieves the authenticated pharmacy's stock items
  Future<List<InventoryItem>> getInventory() async {
    final response = await dio.get('$baseUrl/inventory');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((item) => InventoryItem.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load inventory');
    }
  }

  /// Adds a new drug or updates the quantity if it already exists
  Future<InventoryItem> addOrUpdateInventory({
    required String drugName,
    String? drugCategory,
    required int stockQuantity,
  }) async {
    final response = await dio.post(
      '$baseUrl/inventory',
      data: {
        'drug_name': drugName,
        'drug_category': drugCategory,
        'stock_quantity': stockQuantity,
      },
    );

    if (response.statusCode == 201) {
      return InventoryItem.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to add/update stock');
    }
  }

  /// Updates stock level of a specific inventory item
  Future<InventoryItem> updateStockLevel({
    required String itemId,
    required int stockQuantity,
  }) async {
    final response = await dio.patch(
      '$baseUrl/inventory/$itemId',
      data: {
        'stock_quantity': stockQuantity,
      },
    );

    if (response.statusCode == 200) {
      return InventoryItem.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update stock level');
    }
  }
}
