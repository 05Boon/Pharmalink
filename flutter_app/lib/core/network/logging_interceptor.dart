import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final fullUrl = options.path.startsWith('http')
        ? options.path
        : '${options.baseUrl}${options.path}';
        
    print('--> [${options.method}] $fullUrl');
    
    final authHeader = options.headers['Authorization'];
    if (authHeader != null && authHeader is String && authHeader.isNotEmpty) {
      print('--> Authorization: Bearer is attached');
    } else {
      print('--> Authorization: Bearer is NOT attached');
    }
    
    if (options.data != null) {
      print('--> Request Data: ${options.data}');
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('<-- STATUS: ${response.statusCode}');
    print('<-- RESPONSE BODY: ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('<-- ERROR STATUS: ${err.response?.statusCode ?? "N/A"}');
    print('<-- ERROR DATA: ${err.response?.data}');
    super.onError(err, handler);
  }
}
