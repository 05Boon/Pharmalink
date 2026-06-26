import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:pharmacy_network/core/network/auth_interceptor.dart';
import 'package:pharmacy_network/features/admin/services/admin_service.dart';

class MockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path.contains('/api/admin/pharmacies')) {
      if (options.method == 'GET') {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: [
            {
              'pharmacy_id': 'mock-pharm-1',
              'business_name': 'Mock Pharm 1',
              'license_number': 'LIC-1',
              'email': 'pharm1@test.com',
              'phone_number': '0700111111',
              'latitude': -1.23,
              'longitude': 36.78,
              'account_status': 'ACTIVE',
              'created_at': '2026-06-26T00:00:00.000Z',
            }
          ],
        ));
        return;
      } else if (options.method == 'PATCH') {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'pharmacy_id': 'mock-pharm-1',
            'business_name': 'Mock Pharm 1',
            'license_number': 'LIC-1',
            'email': 'pharm1@test.com',
            'phone_number': '0700111111',
            'latitude': -1.23,
            'longitude': 36.78,
            'account_status': 'SUSPENDED',
            'created_at': '2026-06-26T00:00:00.000Z',
          },
        ));
        return;
      }
    } else if (options.path.contains('/api/admin/analytics/outbreaks')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: [
          {
            'requested_drug': 'Aspirin',
            'request_frequency': 5,
            'centroid_latitude': -1.234,
            'centroid_longitude': 36.789,
          }
        ],
      ));
      return;
    }
    super.onRequest(options, handler);
  }
}

void main() {
  final mockInterceptor = MockInterceptor();

  setUp(() {
    dio.interceptors.insert(0, mockInterceptor);
  });

  tearDown(() {
    dio.interceptors.remove(mockInterceptor);
  });

  group('AdminService Tests', () {
    test('fetchPharmacies parses nodes correctly', () async {
      final pharmacies = await AdminService.fetchPharmacies();
      expect(pharmacies, hasLength(1));
      expect(pharmacies.first.pharmacyId, 'mock-pharm-1');
      expect(pharmacies.first.businessName, 'Mock Pharm 1');
      expect(pharmacies.first.accountStatus, 'ACTIVE');
    });

    test('updatePharmacyStatus toggles status correctly', () async {
      final node = await AdminService.updatePharmacyStatus('mock-pharm-1', 'SUSPENDED');
      expect(node.pharmacyId, 'mock-pharm-1');
      expect(node.accountStatus, 'SUSPENDED');
    });

    test('fetchOutbreaks parses aggregation data correctly', () async {
      final outbreaks = await AdminService.fetchOutbreaks(days: 7);
      expect(outbreaks, hasLength(1));
      expect(outbreaks.first.requestedDrug, 'Aspirin');
      expect(outbreaks.first.requestFrequency, 5);
      expect(outbreaks.first.centroidLatitude, -1.234);
    });
  });
}
