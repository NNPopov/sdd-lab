import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_cubit.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_state.dart';
import 'package:flutter_application_1/features/users/delete_user/domain/usecases/delete_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeleteUserUseCase extends Mock implements DeleteUserUseCase {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  group('DeleteUserCubit', () {
    late _MockDeleteUserUseCase deleteUser;
    late _MockAuthCubit authCubit;

    setUp(() {
      deleteUser = _MockDeleteUserUseCase();
      authCubit = _MockAuthCubit();
      when(
        () => authCubit.forceLogout(notifyUser: any(named: 'notifyUser')),
      ).thenAnswer((_) async {});
      when(() => authCubit.currentUser).thenReturn(
        const CurrentUser(
          username: 'testuser',
          email: '',
          name: '',
          isSuperuser: false,
          isModerator: false,
        ),
      );
    });

    DeleteUserCubit build() => DeleteUserCubit(deleteUser, authCubit);

    group('requestConfirmation', () {
      blocTest<DeleteUserCubit, DeleteUserState>(
        'emits [confirming]',
        build: build,
        act: (c) => c.requestConfirmation(),
        expect: () => [const DeleteUserState.confirming()],
      );
    });

    group('cancel', () {
      blocTest<DeleteUserCubit, DeleteUserState>(
        'emits [initial] when called from confirming',
        build: build,
        seed: () => const DeleteUserState.confirming(),
        act: (c) => c.cancel(),
        expect: () => [const DeleteUserState.initial()],
      );

      blocTest<DeleteUserCubit, DeleteUserState>(
        'does nothing when not in confirming state',
        build: build,
        seed: () => const DeleteUserState.initial(),
        act: (c) => c.cancel(),
        expect: () => <DeleteUserState>[],
      );
    });

    group('confirmAndDelete', () {
      blocTest<DeleteUserCubit, DeleteUserState>(
        'emits [deleting, success] and calls '
        'forceLogout(notifyUser: false) on success',
        build: () {
          when(
            () => deleteUser(
              username: any(named: 'username'),
              currentUsername: any(named: 'currentUsername'),
            ),
          ).thenAnswer((_) async => const Right(unit));
          return build();
        },
        act: (c) => c.confirmAndDelete('testuser'),
        expect: () => [
          const DeleteUserState.deleting(),
          const DeleteUserState.success(),
        ],
        verify: (_) => verify(
          () => authCubit.forceLogout(notifyUser: false),
        ).called(1),
      );

      blocTest<DeleteUserCubit, DeleteUserState>(
        'emits [deleting, failure(ForbiddenFailure)] '
        'and does NOT call forceLogout',
        build: () {
          when(
            () => deleteUser(
              username: any(named: 'username'),
              currentUsername: any(named: 'currentUsername'),
            ),
          ).thenAnswer(
            (_) async => const Left(Failure.forbidden(message: 'Forbidden')),
          );
          return build();
        },
        act: (c) => c.confirmAndDelete('testuser'),
        expect: () => [
          const DeleteUserState.deleting(),
          const DeleteUserState.failure(
            Failure.forbidden(message: 'Forbidden'),
          ),
        ],
        verify: (_) => verifyNever(
          () => authCubit.forceLogout(notifyUser: any(named: 'notifyUser')),
        ),
      );

      blocTest<DeleteUserCubit, DeleteUserState>(
        'emits [deleting, failure(UnauthorizedFailure)] on 401',
        build: () {
          when(
            () => deleteUser(
              username: any(named: 'username'),
              currentUsername: any(named: 'currentUsername'),
            ),
          ).thenAnswer(
            (_) async =>
                const Left(Failure.unauthorized(message: 'Session expired')),
          );
          return build();
        },
        act: (c) => c.confirmAndDelete('testuser'),
        expect: () => [
          const DeleteUserState.deleting(),
          const DeleteUserState.failure(
            Failure.unauthorized(message: 'Session expired'),
          ),
        ],
        verify: (_) => verifyNever(
          () => authCubit.forceLogout(notifyUser: any(named: 'notifyUser')),
        ),
      );

      blocTest<DeleteUserCubit, DeleteUserState>(
        'emits [deleting, failure(UnknownFailure)] on unexpected error',
        build: () {
          when(
            () => deleteUser(
              username: any(named: 'username'),
              currentUsername: any(named: 'currentUsername'),
            ),
          ).thenAnswer(
            (_) async => const Left(Failure.unknown()),
          );
          return build();
        },
        act: (c) => c.confirmAndDelete('testuser'),
        expect: () => [
          const DeleteUserState.deleting(),
          const DeleteUserState.failure(Failure.unknown()),
        ],
        verify: (_) => verifyNever(
          () => authCubit.forceLogout(notifyUser: any(named: 'notifyUser')),
        ),
      );

      blocTest<DeleteUserCubit, DeleteUserState>(
        'emits [deleting, failure(PermissionDenied)] '
        'when use-case returns PermissionDenied',
        build: () {
          when(
            () => deleteUser(
              username: any(named: 'username'),
              currentUsername: any(named: 'currentUsername'),
            ),
          ).thenAnswer(
            (_) async => const Left(Failure.permissionDenied()),
          );
          return build();
        },
        act: (c) => c.confirmAndDelete('other_user'),
        expect: () => [
          const DeleteUserState.deleting(),
          const DeleteUserState.failure(Failure.permissionDenied()),
        ],
        verify: (_) => verifyNever(
          () => authCubit.forceLogout(notifyUser: any(named: 'notifyUser')),
        ),
      );
    });
  });
}
