import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/erase_db_user/application/erase_db_user_cubit.dart';
import 'package:flutter_application_1/features/users/erase_db_user/application/erase_db_user_state.dart';
import 'package:flutter_application_1/features/users/erase_db_user/domain/usecases/erase_db_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEraseDbUserUseCase extends Mock implements EraseDbUserUseCase {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  group('EraseDbUserCubit', () {
    late _MockEraseDbUserUseCase eraseDbUser;
    late _MockAuthCubit authCubit;

    setUp(() {
      eraseDbUser = _MockEraseDbUserUseCase();
      authCubit = _MockAuthCubit();
      when(
        () => authCubit.forceLogout(notifyUser: any(named: 'notifyUser')),
      ).thenAnswer((_) async {});
      when(() => authCubit.currentUser).thenReturn(
        const CurrentUser(
          id: 1,
          username: 'testuser',
          email: '',
          name: '',
          isSuperuser: true,
          isModerator: false,
        ),
      );
    });

    EraseDbUserCubit build() => EraseDbUserCubit(eraseDbUser, authCubit);

    group('requestConfirmation', () {
      blocTest<EraseDbUserCubit, EraseDbUserState>(
        'emits [confirming]',
        build: build,
        act: (c) => c.requestConfirmation(),
        expect: () => [const EraseDbUserState.confirming()],
      );
    });

    group('cancel', () {
      blocTest<EraseDbUserCubit, EraseDbUserState>(
        'emits [initial] when called from confirming',
        build: build,
        seed: () => const EraseDbUserState.confirming(),
        act: (c) => c.cancel(),
        expect: () => [const EraseDbUserState.initial()],
      );

      blocTest<EraseDbUserCubit, EraseDbUserState>(
        'does nothing when not in confirming state',
        build: build,
        seed: () => const EraseDbUserState.initial(),
        act: (c) => c.cancel(),
        expect: () => <EraseDbUserState>[],
      );
    });

    group('confirmAndDelete', () {
      blocTest<EraseDbUserCubit, EraseDbUserState>(
        'emits [deleting, success] and calls '
        'forceLogout(notifyUser: false) on success',
        build: () {
          when(
            () => eraseDbUser(
              userId: any(named: 'userId'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer((_) async => const Right(unit));
          return build();
        },
        act: (c) => c.confirmAndDelete(1),
        expect: () => [
          const EraseDbUserState.deleting(),
          const EraseDbUserState.success(),
        ],
        verify: (_) => verify(
          () => authCubit.forceLogout(notifyUser: false),
        ).called(1),
      );

      blocTest<EraseDbUserCubit, EraseDbUserState>(
        'emits [deleting, failure(ForbiddenFailure)] '
        'and does NOT call forceLogout',
        build: () {
          when(
            () => eraseDbUser(
              userId: any(named: 'userId'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer(
            (_) async => const Left(Failure.forbidden(message: 'Forbidden')),
          );
          return build();
        },
        act: (c) => c.confirmAndDelete(1),
        expect: () => [
          const EraseDbUserState.deleting(),
          const EraseDbUserState.failure(
            Failure.forbidden(message: 'Forbidden'),
          ),
        ],
        verify: (_) => verifyNever(
          () => authCubit.forceLogout(notifyUser: any(named: 'notifyUser')),
        ),
      );

      blocTest<EraseDbUserCubit, EraseDbUserState>(
        'emits [deleting, failure(UnauthorizedFailure)] on 401',
        build: () {
          when(
            () => eraseDbUser(
              userId: any(named: 'userId'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer(
            (_) async =>
                const Left(Failure.unauthorized(message: 'Session expired')),
          );
          return build();
        },
        act: (c) => c.confirmAndDelete(1),
        expect: () => [
          const EraseDbUserState.deleting(),
          const EraseDbUserState.failure(
            Failure.unauthorized(message: 'Session expired'),
          ),
        ],
        verify: (_) => verifyNever(
          () => authCubit.forceLogout(notifyUser: any(named: 'notifyUser')),
        ),
      );

      blocTest<EraseDbUserCubit, EraseDbUserState>(
        'emits [deleting, failure(UnknownFailure)] on unexpected error',
        build: () {
          when(
            () => eraseDbUser(
              userId: any(named: 'userId'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer(
            (_) async => const Left(Failure.unknown()),
          );
          return build();
        },
        act: (c) => c.confirmAndDelete(1),
        expect: () => [
          const EraseDbUserState.deleting(),
          const EraseDbUserState.failure(Failure.unknown()),
        ],
        verify: (_) => verifyNever(
          () => authCubit.forceLogout(notifyUser: any(named: 'notifyUser')),
        ),
      );

      blocTest<EraseDbUserCubit, EraseDbUserState>(
        'emits [deleting, failure(PermissionDenied)] '
        'when use-case returns PermissionDenied',
        build: () {
          when(
            () => eraseDbUser(
              userId: any(named: 'userId'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer(
            (_) async => const Left(Failure.permissionDenied()),
          );
          return build();
        },
        act: (c) => c.confirmAndDelete(1),
        expect: () => [
          const EraseDbUserState.deleting(),
          const EraseDbUserState.failure(Failure.permissionDenied()),
        ],
        verify: (_) => verifyNever(
          () => authCubit.forceLogout(notifyUser: any(named: 'notifyUser')),
        ),
      );
    });
  });
}
