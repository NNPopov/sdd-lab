import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_cubit.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_state.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/entities/tier_detail.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/usecases/get_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetTierUsecase extends Mock implements GetTierUsecase {}

void main() {
  group('TierDetailsCubit', () {
    late _MockGetTierUsecase usecase;

    final tier = TierDetail(
      id: 1,
      name: 'Free',
      createdAt: DateTime(2026, 4, 25),
    );

    setUp(() {
      usecase = _MockGetTierUsecase();
    });

    blocTest<TierDetailsCubit, TierDetailsState>(
      'load(id) → success → emits [loading, loaded(tier)]',
      build: () {
        when(() => usecase(any())).thenAnswer((_) async => Right(tier));
        return TierDetailsCubit(usecase);
      },
      act: (cubit) => cubit.load(1),
      expect: () => [
        const TierDetailsState.loading(),
        TierDetailsState.loaded(tier: tier),
      ],
    );

    blocTest<TierDetailsCubit, TierDetailsState>(
      'load(id) → NotFoundFailure → emits [loading, error(NotFoundFailure)]',
      build: () {
        when(
          () => usecase(any()),
        ).thenAnswer((_) async => const Left(Failure.notFound()));
        return TierDetailsCubit(usecase);
      },
      act: (cubit) => cubit.load(0),
      expect: () => [
        const TierDetailsState.loading(),
        const TierDetailsState.error(failure: Failure.notFound()),
      ],
    );

    blocTest<TierDetailsCubit, TierDetailsState>(
      'load(id) → PermissionDenied → emits [loading, error(PermissionDenied)]',
      build: () {
        when(
          () => usecase(any()),
        ).thenAnswer((_) async => const Left(Failure.permissionDenied()));
        return TierDetailsCubit(usecase);
      },
      act: (cubit) => cubit.load(1),
      expect: () => [
        const TierDetailsState.loading(),
        const TierDetailsState.error(failure: Failure.permissionDenied()),
      ],
    );

    blocTest<TierDetailsCubit, TierDetailsState>(
      'load(id) → UnknownFailure → emits [loading, error(UnknownFailure)]',
      build: () {
        when(
          () => usecase(any()),
        ).thenAnswer((_) async => const Left(Failure.unknown()));
        return TierDetailsCubit(usecase);
      },
      act: (cubit) => cubit.load(1),
      expect: () => [
        const TierDetailsState.loading(),
        const TierDetailsState.error(failure: Failure.unknown()),
      ],
    );

    blocTest<TierDetailsCubit, TierDetailsState>(
      'retry(id) → success → emits [loading, loaded(tier)]',
      build: () {
        when(() => usecase(any())).thenAnswer((_) async => Right(tier));
        return TierDetailsCubit(usecase);
      },
      act: (cubit) => cubit.retry(1),
      expect: () => [
        const TierDetailsState.loading(),
        TierDetailsState.loaded(tier: tier),
      ],
    );
  });
}
