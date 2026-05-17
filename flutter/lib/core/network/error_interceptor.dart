import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => Failure.network(message: err.message),
      DioExceptionType.badResponse => Failure.server(
        statusCode: err.response?.statusCode,
        message: err.message,
      ),
      _ => Failure.unknown(error: err),
    };
    // Attach parsed Failure to the error so data-layer repositories can use it
    // without re-parsing. Access via: err.error as Failure
    handler.next(
      err.copyWith(error: failure),
    );
  }
}
