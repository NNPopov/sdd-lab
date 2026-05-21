import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/_shared/domain/entities/tier.dart';
import 'package:flutter_application_1/features/tiers/create_tier/application/create_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/create_tier/application/create_tier_state.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/entities/new_tier_data.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/usecases/create_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateTierUseCase extends Mock implements CreateTierUseCase {}

void main() {
  group('CreateTierCubit', () {
    late _MockCreateTierUseCase useCase;

    const data = NewTierData(name: 'free');
    const tier = Tier(id: 1, name: 'free');

    setUpAll(() {
      registerFallbackValue(data);
    });

    setUp(() {
      useCase = _MockCreateTierUseCase();
    });

    blocTest<CreateTierCubit, CreateTierState>(
      'emits [submitting, success(tier)] on successful submit',
      build: () {
        when(() => useCase(any())).thenAnswer((_) async => const Right(tier));
        return CreateTierCubit(useCase);
      },
      act: (cubit) => cubit.submit(data),
      expect: () => [
        const CreateTierState.submitting(),
        const CreateTierState.success(tier),
      ],
    );

    blocTest<CreateTierCubit, CreateTierState>(
      'emits [submitting, failure(failure)] on failed submit',
      build: () {
        const failure = Failure.conflict(message: 'Tier already exists');
        when(() => useCase(any())).thenAnswer((_) async => const Left(failure));
        return CreateTierCubit(useCase);
      },
      act: (cubit) => cubit.submit(data),
      expect: () => [
        const CreateTierState.submitting(),
        const CreateTierState.failure(
          Failure.conflict(message: 'Tier already exists'),
        ),
      ],
    );

    blocTest<CreateTierCubit, CreateTierState>(
      'clearError from failure emits [idle]',
      build: () => CreateTierCubit(useCase),
      seed: () => const CreateTierState.failure(Failure.network()),
      act: (cubit) => cubit.clearError(),
      expect: () => [const CreateTierState.idle()],
    );

    blocTest<CreateTierCubit, CreateTierState>(
      'clearError from idle emits [idle]',
      build: () => CreateTierCubit(useCase),
      act: (cubit) => cubit.clearError(),
      expect: () => [const CreateTierState.idle()],
    );
  });
}
