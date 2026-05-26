import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/update_user_request_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/user_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/edit_user/application/edit_user_cubit.dart';
import 'package:flutter_application_1/features/users/edit_user/application/edit_user_state.dart';
import 'package:flutter_application_1/features/users/edit_user/data/get_user_for_edit_adapter.dart';
import 'package:flutter_application_1/features/users/edit_user/data/update_user_adapter.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/entities/user_update.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/usecases/get_user_for_edit_usecase.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/usecases/update_user_usecase.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_cubit.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_state.dart';
import 'package:flutter_application_1/features/users/user_details/data/get_user_adapter.dart';
import 'package:flutter_application_1/features/users/user_details/domain/usecases/get_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockAuthCubit extends Mock implements AuthCubit {}

// Fixtures. `alice` has integer id 42; `alice2` is the same user after renaming
// the handle (the PATCH body field), which must stay a string and never touch
// the id-based path identity.
const _aliceDto = UserDto(
  id: 42,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
);

const _alice = User(
  id: 42,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
  isModerator: false,
);

const _aliceRenamed = User(
  id: 42,
  name: 'Alice',
  username: 'alice2',
  email: 'alice@example.com',
  isModerator: false,
);

void main() {
  group('0050 user_details + edit_user route → user_id (outside-in)', () {
    late _MockUsersApiClient api;
    late _MockAppLogger logger;
    late _MockAuthCubit authCubit;
    late UserDetailsCubit userDetailsCubit;
    late EditUserCubit editUserCubit;

    setUpAll(() {
      registerFallbackValue(const UpdateUserRequestDto());
    });

    setUp(() {
      api = _MockUsersApiClient();
      logger = _MockAppLogger();
      authCubit = _MockAuthCubit();

      // user_details vertical, wired real end-to-end.
      final getUserUseCase = GetUserUseCase(GetUserAdapter(api, logger));
      userDetailsCubit = UserDetailsCubit(getUserUseCase);

      // edit_user vertical, wired real end-to-end.
      final getUserForEditUseCase = GetUserForEditUseCase(
        GetUserForEditAdapter(api, logger),
      );
      final updateUserUseCase = UpdateUserUseCase(
        UpdateUserAdapter(api, logger),
      );
      editUserCubit = EditUserCubit(
        getUserForEditUseCase,
        updateUserUseCase,
        authCubit,
      );
    });

    tearDown(() async {
      await userDetailsCubit.close();
      await editUserCubit.close();
    });

    test('reads, edit-reads, and updates all target the integer id', () async {
      when(() => api.getUser(any())).thenAnswer((_) async => _aliceDto);
      when(() => api.updateUser(any(), any())).thenAnswer((_) async {});
      when(() => authCubit.isMe(any())).thenReturn(true);

      final detailsExpectation = expectLater(
        userDetailsCubit.stream,
        emitsInOrder(<UserDetailsState>[
          const UserDetailsState.loading(),
          const UserDetailsState.loaded(_alice),
        ]),
      );
      final editExpectation = expectLater(
        editUserCubit.stream,
        emitsInOrder(<EditUserState>[
          const EditUserState.loadingInitialData(),
          const EditUserState.loaded(_alice),
          const EditUserState.submitting(_alice),
          const EditUserState.success(_aliceRenamed),
        ]),
      );

      await userDetailsCubit.load(42);
      await editUserCubit.loadInitial(42);
      await editUserCubit.submit(const UserUpdate(username: 'alice2'));

      await detailsExpectation;
      await editExpectation;

      // Read hit the new route with the integer id (details + edit-read).
      verify(() => api.getUser(42)).called(2);

      // Update hit the new route with the integer id, while the new handle
      // survived unchanged in the PATCH body.
      final captured = verify(
        () => api.updateUser(captureAny(), captureAny()),
      ).captured;
      expect(captured[0], 42);
      expect((captured[1] as UpdateUserRequestDto).username, 'alice2');
    });

    test('edit ownership is rejected by id, not by handle', () async {
      when(() => authCubit.isMe(any())).thenReturn(true);
      when(() => authCubit.isMe(99)).thenReturn(false);

      final expectation = expectLater(
        editUserCubit.stream,
        emitsInOrder(<EditUserState>[
          const EditUserState.loadingInitialData(),
          const EditUserState.loadError(
            Failure.forbidden(message: 'You can only edit your own profile'),
          ),
        ]),
      );

      await editUserCubit.loadInitial(99);
      await expectation;

      verifyNever(() => api.getUser(any()));
    });
  });
}
