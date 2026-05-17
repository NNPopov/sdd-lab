import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_state.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/entities/edit_tier_data.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/usecases/edit_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEditTierUseCase extends Mock implements EditTierUseCase {}

void main() {
  group('EditTierCubit', () {
    late _MockEditTierUseCase useCase;

    const data = EditTierData(tierCurrentName: 'free', newName: 'basic');

    setUpAll(() {
      registerFallbackValue(data);
    });

    setUp(() {
      useCase = _MockEditTierUseCase();
    });

    blocTest<EditTierCubit, EditTierState>(
      'emits [submitting, success(newName)] on successful submit',
      build: () {
        when(
          () => useCase(
            data: any(named: 'data'),
            isSuperuser: any(named: 'isSuperuser'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return EditTierCubit(useCase);
      },
      act: (cubit) => cubit.submit(data: data, isSuperuser: true),
      expect: () => [
        const EditTierState.submitting(),
        const EditTierState.success(newName: 'basic'),
      ],
    );

    blocTest<EditTierCubit, EditTierState>(
      'emits [submitting, failure(NotFoundFailure)] when port returns 404',
      build: () {
        when(
          () => useCase(
            data: any(named: 'data'),
            isSuperuser: any(named: 'isSuperuser'),
          ),
        ).thenAnswer((_) async => const Left(Failure.notFound()));
        return EditTierCubit(useCase);
      },
      act: (cubit) => cubit.submit(data: data, isSuperuser: true),
      expect: () => [
        const EditTierState.submitting(),
        const EditTierState.failure(Failure.notFound()),
      ],
    );

    blocTest<EditTierCubit, EditTierState>(
      'emits [submitting, failure(PermissionDenied)] when not superuser',
      build: () {
        when(
          () => useCase(
            data: any(named: 'data'),
            isSuperuser: any(named: 'isSuperuser'),
          ),
        ).thenAnswer(
          (_) async => const Left(Failure.permissionDenied()),
        );
        return EditTierCubit(useCase);
      },
      act: (cubit) => cubit.submit(data: data, isSuperuser: false),
      expect: () => [
        const EditTierState.submitting(),
        const EditTierState.failure(Failure.permissionDenied()),
      ],
    );
  });
}
