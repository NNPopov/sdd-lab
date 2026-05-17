import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_state.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/entities/user_tier.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/usecases/get_user_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetUserTierUseCase extends Mock implements GetUserTierUseCase {}

final _tier = UserTier(
  tierName: 'Free',
  tierCreatedAt: DateTime.utc(2026, 4, 25, 15, 55),
);

void main() {
  group('GetUserTierCubit', () {
    late _MockGetUserTierUseCase useCase;
    late GetUserTierCubit cubit;

    setUp(() {
      useCase = _MockGetUserTierUseCase();
      cubit = GetUserTierCubit(useCase);
    });

    tearDown(() => cubit.close());

    blocTest<GetUserTierCubit, GetUserTierState>(
      'load emits [loading, loaded] on success',
      build: () {
        when(() => useCase('alice')).thenAnswer((_) async => Right(_tier));
        return cubit;
      },
      act: (c) => c.load('alice'),
      expect: () => [
        const GetUserTierState.loading(),
        GetUserTierState.loaded(_tier),
      ],
    );

    blocTest<GetUserTierCubit, GetUserTierState>(
      'load emits [loading, error] on failure',
      build: () {
        when(() => useCase('alice')).thenAnswer(
          (_) async =>
              const Left(Failure.notFound(message: 'Tier not assigned')),
        );
        return cubit;
      },
      act: (c) => c.load('alice'),
      expect: () => [
        const GetUserTierState.loading(),
        const GetUserTierState.error(
          Failure.notFound(message: 'Tier not assigned'),
        ),
      ],
    );

    blocTest<GetUserTierCubit, GetUserTierState>(
      'second load overwrites result of first',
      build: () {
        var callCount = 0;
        when(() => useCase('alice')).thenAnswer((_) async {
          callCount++;
          return callCount == 1
              ? Right<Failure, UserTier>(_tier)
              : const Right<Failure, UserTier>(UserTier(tierName: 'Pro'));
        });
        return cubit;
      },
      act: (c) async {
        await c.load('alice');
        await c.load('alice');
      },
      expect: () => [
        const GetUserTierState.loading(),
        GetUserTierState.loaded(_tier),
        const GetUserTierState.loading(),
        const GetUserTierState.loaded(UserTier(tierName: 'Pro')),
      ],
    );
  });
}
