import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/entities/user_tier.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/ports/get_user_tier_port.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/usecases/get_user_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetUserTierPort extends Mock implements GetUserTierPort {}

const _userId = 7;
const _tier = UserTier(tierName: 'Gold');

void main() {
  group('GetUserTierUseCase', () {
    late _MockGetUserTierPort port;
    late GetUserTierUseCase useCase;

    setUp(() {
      port = _MockGetUserTierPort();
      useCase = GetUserTierUseCase(port);
    });

    test(
      'delegates to the port with the integer id and passes Right through',
      () async {
        when(() => port(_userId)).thenAnswer((_) async => const Right(_tier));

        final result = await useCase(_userId);

        expect(result, const Right<Failure, UserTier>(_tier));
        verify(() => port(_userId)).called(1);
      },
    );

    test('passes a Left from the port straight through (no guard)', () async {
      const failure = Failure.notFound(message: 'Tier not assigned');
      when(() => port(_userId)).thenAnswer((_) async => const Left(failure));

      final result = await useCase(_userId);

      expect(result, const Left<Failure, UserTier>(failure));
      verify(() => port(_userId)).called(1);
    });
  });
}
