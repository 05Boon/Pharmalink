import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class HealthApiService {
  const HealthApiService();

  Future<Map<String, dynamic>> getHealth() async {
    final response = await http.get(Uri.parse(ApiConfig.healthUrl));

    if (response.statusCode != 200) {
      throw Exception('Health check failed with status ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
