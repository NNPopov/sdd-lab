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
      'when userId matches currentUserId',
      () async {
        when(() => port(1)).thenAnswer((_) async => const Right(unit));

        final result = await useCase(
          userId: 1,
          currentUserId: 1,
        );

        expect(result, const Right<Failure, Unit>(unit));
        verify(() => port(1)).called(1);
      },
    );

    test(
      'returns Left(PermissionDenied) and does NOT call port '
      'when userId != currentUserId',
      () async {
        final result = await useCase(
          userId: 2,
          currentUserId: 1,
        );

        expect(result, const Left<Failure, Unit>(Failure.permissionDenied()));
        verifyNever(() => port(any()));
      },
    );
  });
}
