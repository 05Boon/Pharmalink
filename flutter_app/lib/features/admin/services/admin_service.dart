import '../../../core/network/auth_interceptor.dart';
import '../../../config/api_config.dart';
import '../models/outbreak_analytic_model.dart';
import '../models/pharmacy_node_model.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'report_download_stub.dart'
  if (dart.library.html) 'report_download_web.dart';

class AdminService {
  // Fetches all registered pharmacy nodes for the admin table.
  static Future<List<PharmacyNode>> fetchPharmacies() async {
    final response = await dio.get('${ApiConfig.baseUrl}/admin/pharmacies');
    if (response.statusCode == 200) {
      final list = response.data as List<dynamic>;
      return list.map((item) => PharmacyNode.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load pharmacies: ${response.statusCode}');
    }
  }

  // Updates a pharmacy account status (ACTIVE/SUSPENDED).
  static Future<PharmacyNode> updatePharmacyStatus(String pharmacyId, String status) async {
    final response = await dio.patch(
      '${ApiConfig.baseUrl}/admin/pharmacies/$pharmacyId/status',
      data: {'account_status': status},
    );
    if (response.statusCode == 200) {
      return PharmacyNode.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update status: ${response.statusCode}');
    }
  }

  // Loads outbreak centroids aggregated by requested drug and timeframe.
  static Future<List<OutbreakAnalytic>> fetchOutbreaks({int days = 7}) async {
    final response = await dio.get(
      '${ApiConfig.baseUrl}/admin/analytics/outbreaks',
      queryParameters: {'days': days},
    );
    if (response.statusCode == 200) {
      final list = response.data as List<dynamic>;
      return list.map((item) => OutbreakAnalytic.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load outbreaks: ${response.statusCode}');
    }
  }

  // Triggers backend report generation and returns the full report payload.
  static Future<Map<String, dynamic>> generateReport({int days = 7}) async {
    final response = await dio.post(
      '${ApiConfig.baseUrl}/admin/reports/generate',
      queryParameters: {'days': days},
      data: <String, dynamic>{},
    );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to generate report: ${response.statusCode}');
    }
  }

  // Downloads generated report in CSV format for spreadsheet-friendly sharing.
  static Future<void> downloadReportCsv({
    int days = 7,
    Map<String, dynamic>? reportData,
  }) async {
    try {
      final response = await dio.get<List<int>>(
        '${ApiConfig.baseUrl}/admin/reports/export',
        queryParameters: {'days': days},
        // Request raw bytes so the browser can download a real file.
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to download report: ${response.statusCode}');
      }

      final bytes = Uint8List.fromList(response.data!);
      if (bytes.isEmpty) {
        throw Exception('Downloaded report is empty.');
      }

      final disposition = response.headers.value('content-disposition') ?? '';
      // Prefer server-provided filename when available.
      final fileNameMatch = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
      final filename = fileNameMatch?.group(1) ?? 'admin_report_${days}d.csv';

      downloadBytes(bytes, filename, 'text/csv;charset=utf-8');
      return;
    } on DioException catch (error) {
      // Fallback for environments where /reports/export is not deployed yet.
      if (error.response?.statusCode != 404) {
        rethrow;
      }
    }

    final report = reportData ?? await generateReport(days: days);
    final csv = _buildCsvFromReport(report, days);
    final fallbackBytes = Uint8List.fromList(utf8.encode(csv));
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fallbackFilename = 'admin_report_${days}d_$timestamp.csv';
    downloadBytes(fallbackBytes, fallbackFilename, 'text/csv;charset=utf-8');
  }

  static String _buildCsvFromReport(Map<String, dynamic> report, int days) {
    final generatedAt = '${report['generated_at'] ?? ''}';
    final timeframe = report['timeframe_days'] ?? days;

    final cards = (report['cards'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        const <Map<String, dynamic>>[];

    final topDrugs = (report['top_requested_drugs'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        const <Map<String, dynamic>>[];

    final topDrugsByArea = (report['top_requested_drugs_by_area'] as List?)
        ?.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList() ??
      const <Map<String, dynamic>>[];

    final lines = <String>[
      'section,key,value',
      'summary,${_csvEscape('generated_at')},${_csvEscape(generatedAt)}',
      'summary,${_csvEscape('timeframe_days')},${_csvEscape('$timeframe')}',
      '',
      'cards,title,description,icon',
      ...cards.map(
        (card) =>
            'cards,${_csvEscape('${card['title'] ?? ''}')},${_csvEscape('${card['description'] ?? ''}')},${_csvEscape('${card['icon'] ?? ''}')}',
      ),
      '',
      'top_requested_drugs,drug_name,request_count',
      ...topDrugs.map(
        (item) =>
            'top_requested_drugs,${_csvEscape('${item['drug_name'] ?? ''}')},${_csvEscape('${item['request_count'] ?? 0}')}',
      ),
      '',
      'top_requested_drugs_by_area,area_label,area_latitude,area_longitude,top_drug,request_count,total_requests_in_area',
      ...topDrugsByArea.map(
        (item) =>
            'top_requested_drugs_by_area,${_csvEscape('${item['area_label'] ?? ''}')},${_csvEscape('${item['area_latitude'] ?? 0.0}')},${_csvEscape('${item['area_longitude'] ?? 0.0}')},${_csvEscape('${item['top_drug'] ?? ''}')},${_csvEscape('${item['request_count'] ?? 0}')},${_csvEscape('${item['total_requests_in_area'] ?? 0}')}',
      ),
    ];

    return lines.join('\n');
  }

  static String _csvEscape(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }
}
