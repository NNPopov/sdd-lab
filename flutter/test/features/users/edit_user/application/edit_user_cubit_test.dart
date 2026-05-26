import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/edit_user/application/edit_user_cubit.dart';
import 'package:flutter_application_1/features/users/edit_user/application/edit_user_state.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/entities/user_update.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/usecases/get_user_for_edit_usecase.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/usecases/update_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetUserForEditUseCase extends Mock
    implements GetUserForEditUseCase {}

class _MockUpdateUserUseCase extends Mock implements UpdateUserUseCase {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  group('EditUserCubit', () {
    late _MockGetUserForEditUseCase getUser;
    late _MockUpdateUserUseCase updateUser;
    late _MockAuthCubit authCubit;

    const user = User(
      id: 1,
      name: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
      isModerator: false,
    );

    const update = UserUpdate(name: 'Updated Name');

    setUpAll(() {
      registerFallbackValue(update);
      registerFallbackValue(user);
    });

    setUp(() {
      getUser = _MockGetUserForEditUseCase();
      updateUser = _MockUpdateUserUseCase();
      authCubit = _MockAuthCubit();
      // Default: all ids are "me".
      when(() => authCubit.isMe(any())).thenReturn(true);
    });

    EditUserCubit build() => EditUserCubit(getUser, updateUser, authCubit);

    group('loadInitial', () {
      blocTest<EditUserCubit, EditUserState>(
        'emits [loadingInitialData, loaded] on success',
        build: () {
          when(() => getUser(any())).thenAnswer((_) async => const Right(user));
          return build();
        },
        act: (c) => c.loadInitial(1),
        expect: () => [
          const EditUserState.loadingInitialData(),
          const EditUserState.loaded(user),
        ],
      );

      blocTest<EditUserCubit, EditUserState>(
        'emits [loadingInitialData, loadError] on API failure',
        build: () {
          when(() => getUser(any())).thenAnswer(
            (_) async => const Left(Failure.network()),
          );
          return build();
        },
        act: (c) => c.loadInitial(1),
        expect: () => [
          const EditUserState.loadingInitialData(),
          const EditUserState.loadError(Failure.network()),
        ],
      );

      blocTest<EditUserCubit, EditUserState>(
        'emits [loadingInitialData, loadError(ForbiddenFailure)] '
        'when id is not the current user',
        build: () {
          when(() => authCubit.isMe(99)).thenReturn(false);
          return build();
        },
        act: (c) => c.loadInitial(99),
        expect: () => [
          const EditUserState.loadingInitialData(),
          const EditUserState.loadError(
            Failure.forbidden(
              message: 'You can only edit your own profile',
            ),
          ),
        ],
        verify: (_) => verifyNever(() => getUser(any())),
      );
    });

    group('submit', () {
      blocTest<EditUserCubit, EditUserState>(
        'emits [submitting, success] on success',
        build: () {
          when(
            () => updateUser(
              original: any(named: 'original'),
              update: any(named: 'update'),
            ),
          ).thenAnswer((_) async => const Right(user));
          return build();
        },
        seed: () => const EditUserState.loaded(user),
        act: (c) => c.submit(update),
        expect: () => [
          const EditUserState.submitting(user),
          const EditUserState.success(user),
        ],
      );

      blocTest<EditUserCubit, EditUserState>(
        'emits [submitting, submitError] with ConflictFailure',
        build: () {
          const failure = Failure.conflict(message: 'Username taken');
          when(
            () => updateUser(
              original: any(named: 'original'),
              update: any(named: 'update'),
            ),
          ).thenAnswer((_) async => const Left(failure));
          return build();
        },
        seed: () => const EditUserState.loaded(user),
        act: (c) => c.submit(update),
        expect: () => [
          const EditUserState.submitting(user),
          const EditUserState.submitError(
            user,
            Failure.conflict(message: 'Username taken'),
          ),
        ],
      );

      blocTest<EditUserCubit, EditUserState>(
        'emits [submitting, submitError] with FieldValidationFailure',
        build: () {
          const failure = FieldValidationFailure(fields: {'email': 'Invalid'});
          when(
            () => updateUser(
              original: any(named: 'original'),
              update: any(named: 'update'),
            ),
          ).thenAnswer((_) async => const Left(failure));
          return build();
        },
        seed: () => const EditUserState.loaded(user),
        act: (c) => c.submit(update),
        expect: () => [
          const EditUserState.submitting(user),
          const EditUserState.submitError(
            user,
            FieldValidationFailure(fields: {'email': 'Invalid'}),
          ),
        ],
      );

      blocTest<EditUserCubit, EditUserState>(
        'emits [submitting, submitError] with UnauthorizedFailure',
        build: () {
          const failure = Failure.unauthorized(message: 'Session expired');
          when(
            () => updateUser(
              original: any(named: 'original'),
              update: any(named: 'update'),
            ),
          ).thenAnswer((_) async => const Left(failure));
          return build();
        },
        seed: () => const EditUserState.loaded(user),
        act: (c) => c.submit(update),
        expect: () => [
          const EditUserState.submitting(user),
          const EditUserState.submitError(
            user,
            Failure.unauthorized(message: 'Session expired'),
          ),
        ],
      );

      blocTest<EditUserCubit, EditUserState>(
        'emits [submitting, submitError] with ForbiddenFailure',
        build: () {
          const failure = Failure.forbidden(message: 'Forbidden');
          when(
            () => updateUser(
              original: any(named: 'original'),
              update: any(named: 'update'),
            ),
          ).thenAnswer((_) async => const Left(failure));
          return build();
        },
        seed: () => const EditUserState.loaded(user),
        act: (c) => c.submit(update),
        expect: () => [
          const EditUserState.submitting(user),
          const EditUserState.submitError(
            user,
            Failure.forbidden(message: 'Forbidden'),
          ),
        ],
      );

      blocTest<EditUserCubit, EditUserState>(
        'does nothing when called from initial state',
        build: build,
        act: (c) => c.submit(update),
        expect: () => <EditUserState>[],
      );
    });
  });
}
