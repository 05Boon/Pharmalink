import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logging_interceptor.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    super.onRequest(options, handler);
  }
}

// Global configured Dio client
final dio = Dio()..interceptors.addAll([AuthInterceptor(), LoggingInterceptor()]);

