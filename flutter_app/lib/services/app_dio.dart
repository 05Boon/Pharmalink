import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/logging_interceptor.dart';
import 'auth_service.dart';

class AppDio {
  AppDio._();

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      // Keep status validation in service layer for consistent error handling.
      validateStatus: (_) => true,
    ),
  )..interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthService.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
      LoggingInterceptor(),
    ]);
}

