import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/auth/infrastructure/token_holder.dart';

class AuthInterceptor extends InterceptorsWrapper {
  AuthInterceptor(this._tokens, this._onUnauthorized);

  final TokenHolder _tokens;
  final void Function() _onUnauthorized;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isLogin = options.path.endsWith('/login');
    final token = _tokens.current;
    if (!isLogin && token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      final isLogin = err.requestOptions.path.endsWith('/login');
      if (!isLogin) {
        _onUnauthorized();
      }
    }
    handler.next(err);
  }
}
