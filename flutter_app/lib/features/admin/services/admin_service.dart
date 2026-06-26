import '../../../core/network/auth_interceptor.dart';
import '../../../config/api_config.dart';
import '../models/outbreak_analytic_model.dart';
import '../models/pharmacy_node_model.dart';

class AdminService {
  static Future<List<PharmacyNode>> fetchPharmacies() async {
    final response = await dio.get('${ApiConfig.baseUrl}/api/admin/pharmacies');
    if (response.statusCode == 200) {
      final list = response.data as List<dynamic>;
      return list.map((item) => PharmacyNode.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load pharmacies: ${response.statusCode}');
    }
  }

  static Future<PharmacyNode> updatePharmacyStatus(String pharmacyId, String status) async {
    final response = await dio.patch(
      '${ApiConfig.baseUrl}/api/admin/pharmacies/$pharmacyId/status',
      data: {'account_status': status},
    );
    if (response.statusCode == 200) {
      return PharmacyNode.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update status: ${response.statusCode}');
    }
  }

  static Future<List<OutbreakAnalytic>> fetchOutbreaks({int days = 7}) async {
    final response = await dio.get(
      '${ApiConfig.baseUrl}/api/admin/analytics/outbreaks',
      queryParameters: {'days': days},
    );
    if (response.statusCode == 200) {
      final list = response.data as List<dynamic>;
      return list.map((item) => OutbreakAnalytic.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load outbreaks: ${response.statusCode}');
    }
  }
}
