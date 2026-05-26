import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_state.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/domain/usecases/delete_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeleteTierUseCase extends Mock implements DeleteTierUseCase {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  group('DeleteTierCubit', () {
    late _MockDeleteTierUseCase deleteTier;
    late _MockAuthCubit authCubit;

    setUp(() {
      deleteTier = _MockDeleteTierUseCase();
      authCubit = _MockAuthCubit();
      when(() => authCubit.currentUser).thenReturn(
        const CurrentUser(
          id: 1,
          username: 'superuser',
          email: '',
          name: '',
          isSuperuser: true,
          isModerator: false,
        ),
      );
    });

    DeleteTierCubit build() => DeleteTierCubit(deleteTier, authCubit);

    group('requestConfirmation', () {
      blocTest<DeleteTierCubit, DeleteTierState>(
        'emits [confirming]',
        build: build,
        act: (c) => c.requestConfirmation(),
        expect: () => [const DeleteTierState.confirming()],
      );
    });

    group('cancel', () {
      blocTest<DeleteTierCubit, DeleteTierState>(
        'emits [initial] when called from confirming',
        build: build,
        seed: () => const DeleteTierState.confirming(),
        act: (c) => c.cancel(),
        expect: () => [const DeleteTierState.initial()],
      );

      blocTest<DeleteTierCubit, DeleteTierState>(
        'does nothing when not in confirming state',
        build: build,
        seed: () => const DeleteTierState.initial(),
        act: (c) => c.cancel(),
        expect: () => <DeleteTierState>[],
      );
    });

    group('confirmAndDelete', () {
      blocTest<DeleteTierCubit, DeleteTierState>(
        'emits [deleting, success] on success',
        build: () {
          when(
            () => deleteTier(
              id: any(named: 'id'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer((_) async => const Right(unit));
          return build();
        },
        act: (c) => c.confirmAndDelete(1),
        expect: () => [
          const DeleteTierState.deleting(),
          const DeleteTierState.success(),
        ],
      );

      blocTest<DeleteTierCubit, DeleteTierState>(
        'emits [deleting, notFound] on NotFoundFailure (404)',
        build: () {
          when(
            () => deleteTier(
              id: any(named: 'id'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer((_) async => const Left(Failure.notFound()));
          return build();
        },
        act: (c) => c.confirmAndDelete(1),
        expect: () => [
          const DeleteTierState.deleting(),
          const DeleteTierState.notFound(),
        ],
      );

      blocTest<DeleteTierCubit, DeleteTierState>(
        'emits [deleting, failure(ForbiddenFailure)] on 403',
        build: () {
          when(
            () => deleteTier(
              id: any(named: 'id'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer(
            (_) async => const Left(Failure.forbidden(message: 'Forbidden')),
          );
          return build();
        },
        act: (c) => c.confirmAndDelete(1),
        expect: () => [
          const DeleteTierState.deleting(),
          const DeleteTierState.failure(
            Failure.forbidden(message: 'Forbidden'),
          ),
        ],
      );

      blocTest<DeleteTierCubit, DeleteTierState>(
        'emits [deleting, failure(UnknownFailure)] on unexpected error',
        build: () {
          when(
            () => deleteTier(
              id: any(named: 'id'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer((_) async => const Left(Failure.unknown()));
          return build();
        },
        act: (c) => c.confirmAndDelete(1),
        expect: () => [
          const DeleteTierState.deleting(),
          const DeleteTierState.failure(Failure.unknown()),
        ],
      );

      blocTest<DeleteTierCubit, DeleteTierState>(
        'emits [deleting, failure(PermissionDenied)] when isSuperuser=false',
        build: () {
          when(() => authCubit.currentUser).thenReturn(
            const CurrentUser(
              id: 1,
              username: 'regularuser',
              email: '',
              name: '',
              isSuperuser: false,
              isModerator: false,
            ),
          );
          when(
            () => deleteTier(
              id: any(named: 'id'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer(
            (_) async => const Left(Failure.permissionDenied()),
          );
          return build();
        },
        act: (c) => c.confirmAndDelete(1),
        expect: () => [
          const DeleteTierState.deleting(),
          const DeleteTierState.failure(Failure.permissionDenied()),
        ],
      );
    });
  });
}
