import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/ports/update_user_tier_port.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/usecases/update_user_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUpdateUserTierPort extends Mock implements UpdateUserTierPort {}

const _userId = 7;
const _tierId = 3;

void main() {
  group('UpdateUserTierUseCase', () {
    late _MockUpdateUserTierPort port;
    late UpdateUserTierUseCase useCase;

    setUp(() {
      port = _MockUpdateUserTierPort();
      useCase = UpdateUserTierUseCase(port);
    });

    test(
      'superuser: delegates to the port with the integer id and passes '
      'the result through',
      () async {
        when(
          () => port(userId: _userId, tierId: _tierId),
        ).thenAnswer((_) async => const Right(unit));

        final result = await useCase(
          userId: _userId,
          tierId: _tierId,
          isSuperuser: true,
        );

        expect(result, const Right<Failure, Unit>(unit));
        verify(() => port(userId: _userId, tierId: _tierId)).called(1);
      },
    );

    test(
      'non-superuser: returns Left(PermissionDenied) and never calls the port',
      () async {
        final result = await useCase(
          userId: _userId,
          tierId: _tierId,
          isSuperuser: false,
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<PermissionDenied>()),
          (_) => fail('Expected Left(PermissionDenied)'),
        );
        verifyNever(
          () => port(
            userId: any(named: 'userId'),
            tierId: any(named: 'tierId'),
          ),
        );
      },
    );
  });
}
