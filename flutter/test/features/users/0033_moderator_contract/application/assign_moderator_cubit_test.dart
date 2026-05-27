import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/moderator_contract/application/assign_moderator_cubit.dart';
import 'package:flutter_application_1/features/users/moderator_contract/application/assign_moderator_state.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/usecases/assign_moderator_usecase.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/usecases/revoke_moderator_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAssignUseCase extends Mock implements AssignModeratorUseCase {}

class _MockRevokeUseCase extends Mock implements RevokeModeratorUseCase {}

void main() {
  late _MockAssignUseCase assignUseCase;
  late _MockRevokeUseCase revokeUseCase;

  setUp(() {
    assignUseCase = _MockAssignUseCase();
    revokeUseCase = _MockRevokeUseCase();
  });

  AssignModeratorCubit build() =>
      AssignModeratorCubit(assignUseCase, revokeUseCase);

  group('assign', () {
    blocTest<AssignModeratorCubit, AssignModeratorState>(
      'emits [loading, success(isModerator: true)] on Right',
      build: build,
      setUp: () {
        when(
          () => assignUseCase(7),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (c) => c.assign(7),
      expect: () => [
        const AssignModeratorState.loading(),
        const AssignModeratorState.success(isModerator: true),
      ],
    );

    blocTest<AssignModeratorCubit, AssignModeratorState>(
      'emits [loading, error(failure)] on Left',
      build: build,
      setUp: () {
        when(
          () => assignUseCase(7),
        ).thenAnswer(
          (_) async =>
              const Left(Failure.conflict(message: 'already a moderator')),
        );
      },
      act: (c) => c.assign(7),
      expect: () => [
        const AssignModeratorState.loading(),
        isA<AssignModeratorError>().having(
          (s) => s.failure,
          'failure',
          isA<ConflictFailure>(),
        ),
      ],
    );
  });

  group('revoke', () {
    blocTest<AssignModeratorCubit, AssignModeratorState>(
      'emits [loading, success(isModerator: false)] on Right',
      build: build,
      setUp: () {
        when(
          () => revokeUseCase(7),
        ).thenAnswer((_) async => const Right(null));
      },
      act: (c) => c.revoke(7),
      expect: () => [
        const AssignModeratorState.loading(),
        const AssignModeratorState.success(isModerator: false),
      ],
    );

    blocTest<AssignModeratorCubit, AssignModeratorState>(
      'emits [loading, error(failure)] on Left',
      build: build,
      setUp: () {
        when(
          () => revokeUseCase(7),
        ).thenAnswer(
          (_) async => const Left(Failure.forbidden(message: 'denied')),
        );
      },
      act: (c) => c.revoke(7),
      expect: () => [
        const AssignModeratorState.loading(),
        isA<AssignModeratorError>().having(
          (s) => s.failure,
          'failure',
          isA<ForbiddenFailure>(),
        ),
      ],
    );
  });
}
