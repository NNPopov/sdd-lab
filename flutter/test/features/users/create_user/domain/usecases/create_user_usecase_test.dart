import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/create_user/domain/entities/new_user_data.dart';
import 'package:flutter_application_1/features/users/create_user/domain/ports/create_user_port.dart';
import 'package:flutter_application_1/features/users/create_user/domain/usecases/create_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateUserPort extends Mock implements CreateUserPort {}

void main() {
  group('CreateUserUseCase', () {
    late _MockCreateUserPort port;
    late CreateUserUseCase useCase;

    const data = NewUserData(
      name: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
      password: 'Password1!',
    );

    const user = User(
      id: 1,
      name: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
      isModerator: false,
    );

    setUpAll(() {
      registerFallbackValue(data);
    });

    setUp(() {
      port = _MockCreateUserPort();
      useCase = CreateUserUseCase(port);
    });

    test('returns Right(user) when port succeeds', () async {
      when(() => port(any())).thenAnswer((_) async => const Right(user));

      final result = await useCase(data);

      result.fold(
        (l) => fail('Expected Right, got Left($l)'),
        (r) {
          expect(r.id, 1);
          expect(r.username, 'testuser');
        },
      );
    });

    test('returns Left(ConflictFailure) when port returns conflict', () async {
      const failure = Failure.conflict(message: 'Username already taken');
      when(() => port(any())).thenAnswer((_) async => const Left(failure));

      final result = await useCase(data);

      result.fold(
        (l) => expect(l, isA<ConflictFailure>()),
        (r) => fail('Expected Left, got Right($r)'),
      );
    });
  });
}
