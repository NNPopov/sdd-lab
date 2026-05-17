import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/auth/infrastructure/auth_interceptor.dart';
import 'package:flutter_application_1/core/auth/infrastructure/token_holder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class _MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late TokenHolder tokens;
  late bool callbackCalled;
  late AuthInterceptor interceptor;

  setUp(() {
    tokens = TokenHolder();
    callbackCalled = false;
    interceptor = AuthInterceptor(tokens, () => callbackCalled = true);
  });

  group('onRequest', () {
    test('does NOT add Authorization header for /login even with token', () {
      tokens.current = 'mytoken';
      final options = RequestOptions(path: '/api/login');
      final handler = _MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });

    test('adds Authorization header for /users when token present', () {
      tokens.current = 'mytoken';
      final options = RequestOptions(path: '/api/users');
      final handler = _MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer mytoken');
      verify(() => handler.next(options)).called(1);
    });

    test('does NOT add Authorization header for /users when no token', () {
      final options = RequestOptions(path: '/api/users');
      final handler = _MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });
  });

  group('onError', () {
    test('calls callback on 401 for /users', () {
      final requestOptions = RequestOptions(path: '/api/users');
      final err = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      final handler = _MockErrorInterceptorHandler();

      interceptor.onError(err, handler);

      expect(callbackCalled, isTrue);
      verify(() => handler.next(err)).called(1);
    });

    test('does NOT call callback on 401 for /login', () {
      final requestOptions = RequestOptions(path: '/api/login');
      final err = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      final handler = _MockErrorInterceptorHandler();

      interceptor.onError(err, handler);

      expect(callbackCalled, isFalse);
      verify(() => handler.next(err)).called(1);
    });

    test('does NOT call callback on 500', () {
      final requestOptions = RequestOptions(path: '/api/users');
      final err = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 500,
        ),
      );
      final handler = _MockErrorInterceptorHandler();

      interceptor.onError(err, handler);

      expect(callbackCalled, isFalse);
      verify(() => handler.next(err)).called(1);
    });
  });
}
