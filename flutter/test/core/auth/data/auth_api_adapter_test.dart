import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/auth/data/auth_api_adapter.dart';
import 'package:flutter_application_1/core/auth/data/auth_api_client.dart';
import 'package:flutter_application_1/core/auth/data/dto/token_response_dto.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApiClient extends Mock implements AuthApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockAuthApiClient mockClient;
  late _MockAppLogger mockLogger;
  late AuthApiAdapter adapter;

  setUp(() {
    mockClient = _MockAuthApiClient();
    mockLogger = _MockAppLogger();
    adapter = AuthApiAdapter(mockClient, mockLogger);
  });

  group('login', () {
    test('returns Right(AuthSession) when API succeeds', () async {
      const dto = TokenResponseDto(
        accessToken: 'tok123',
        tokenType: 'bearer',
      );
      when(
        () => mockClient.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
          grantType: any(named: 'grantType'),
        ),
      ).thenAnswer((_) async => dto);

      final result = await adapter.login(username: 'alice', password: 'pass');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (session) {
          expect(session.accessToken, 'tok123');
          expect(session.username, 'alice');
        },
      );
    });

    test(
      'returns Left(InvalidCredentialsFailure) on 401 with detail',
      () async {
        final requestOptions = RequestOptions(path: '/login');
        when(
          () => mockClient.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
            grantType: any(named: 'grantType'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: requestOptions,
            response: Response(
              requestOptions: requestOptions,
              statusCode: 401,
              data: {'detail': 'Wrong username, email or password.'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await adapter.login(
          username: 'alice',
          password: 'wrong',
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) {
            expect(f, isA<InvalidCredentialsFailure>());
            expect(
              (f as InvalidCredentialsFailure).message,
              'Wrong username, email or password.',
            );
          },
          (_) => fail('expected Left'),
        );
      },
    );

    test('returns UnknownFailure on unexpected exception', () async {
      when(
        () => mockClient.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
          grantType: any(named: 'grantType'),
        ),
      ).thenThrow(TypeError());

      final result = await adapter.login(username: 'alice', password: 'pass');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnknownFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('logout', () {
    test('returns Right(unit) when API succeeds', () async {
      when(() => mockClient.logout()).thenAnswer((_) async {});

      final result = await adapter.logout();

      expect(result, const Right<Failure, Unit>(unit));
    });
  });
}
