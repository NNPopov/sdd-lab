import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/delete_user/domain/ports/delete_user_port.dart';
import 'package:flutter_application_1/features/users/delete_user/domain/usecases/delete_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeleteUserPort extends Mock implements DeleteUserPort {}

void main() {
  group('DeleteUserUseCase', () {
    late _MockDeleteUserPort port;
    late DeleteUserUseCase useCase;

    setUp(() {
      port = _MockDeleteUserPort();
      useCase = DeleteUserUseCase(port);
    });

    test(
      'returns Right(unit) and calls port '
      'when username matches currentUsername',
      () async {
        when(() => port('testuser')).thenAnswer((_) async => const Right(unit));

        final result = await useCase(
          username: 'testuser',
          currentUsername: 'testuser',
        );

        expect(result, const Right<Failure, Unit>(unit));
        verify(() => port('testuser')).called(1);
      },
    );

    test(
      'returns Left(PermissionDenied) and does NOT call port '
      'when username != currentUsername',
      () async {
        final result = await useCase(
          username: 'other_user',
          currentUsername: 'testuser',
        );

        expect(result, const Left<Failure, Unit>(Failure.permissionDenied()));
        verifyNever(() => port(any()));
      },
    );
  });
}
