import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/network/error_interceptor.dart';

class DioClient {
  DioClient._();

  static Dio create({required String baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
    // AuthInterceptor is wired in main.dart after DI setup to avoid
    // circular dependency: AuthInterceptor → AuthCubit → AuthApiAdapter → Dio.
    dio.interceptors.add(ErrorInterceptor());
    return dio;
  }
}
