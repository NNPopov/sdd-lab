import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/erase_db_user/domain/ports/erase_db_user_port.dart';
import 'package:flutter_application_1/features/users/erase_db_user/domain/usecases/erase_db_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEraseDbUserPort extends Mock implements EraseDbUserPort {}

void main() {
  group('EraseDbUserUseCase', () {
    late _MockEraseDbUserPort port;
    late EraseDbUserUseCase useCase;

    setUp(() {
      port = _MockEraseDbUserPort();
      useCase = EraseDbUserUseCase(port);
    });

    test(
      'returns Right(unit) and calls port when isSuperuser is true',
      () async {
        when(() => port(1)).thenAnswer((_) async => const Right(unit));

        final result = await useCase(
          userId: 1,
          isSuperuser: true,
        );

        expect(result, const Right<Failure, Unit>(unit));
        verify(() => port(1)).called(1);
      },
    );

    test(
      'returns Left(PermissionDenied) and does NOT call port '
      'when isSuperuser is false',
      () async {
        final result = await useCase(
          userId: 1,
          isSuperuser: false,
        );

        expect(result, const Left<Failure, Unit>(Failure.permissionDenied()));
        verifyNever(() => port(any()));
      },
    );
  });
}
