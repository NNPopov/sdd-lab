import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_cubit.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_state.dart';
import 'package:flutter_application_1/features/users/delete_user/data/delete_user_adapter.dart';
import 'package:flutter_application_1/features/users/delete_user/domain/usecases/delete_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockUsersApiClient apiClient;
  late _MockAppLogger logger;
  late _MockAuthCubit authCubit;
  late DeleteUserAdapter adapter;
  late DeleteUserUseCase useCase;
  late DeleteUserCubit cubit;

  setUp(() {
    apiClient = _MockUsersApiClient();
    logger = _MockAppLogger();
    authCubit = _MockAuthCubit();
    adapter = DeleteUserAdapter(apiClient, logger);
    useCase = DeleteUserUseCase(adapter);
    cubit = DeleteUserCubit(useCase, authCubit);
    when(() => authCubit.currentUser).thenReturn(
      const CurrentUser(
        id: 1,
        username: 'admin',
        email: 'admin@example.com',
        name: 'Admin',
        isSuperuser: true,
        isModerator: false,
      ),
    );
  });

  tearDown(() async => cubit.close());

  group('delete_user_route_to_user_id outside-in', () {
    test(
      'Scenario 1: confirmAndDelete(1) — matching id — emits [deleting, success] '
      'and calls deleteUser(1) with the integer id',
      () async {
        when(() => apiClient.deleteUser(1)).thenAnswer((_) async {});
        when(
          () => authCubit.forceLogout(notifyUser: false),
        ).thenAnswer((_) async {});

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const DeleteUserState.deleting(),
            const DeleteUserState.success(),
          ]),
        );

        await cubit.confirmAndDelete(1);
        await expectation;

        verify(() => apiClient.deleteUser(1)).called(1);
        verify(() => authCubit.forceLogout(notifyUser: false)).called(1);
      },
    );

    test(
      'Scenario 2: confirmAndDelete(2) — non-matching id — emits '
      '[deleting, failure(PermissionDenied)] and never calls the API',
      () async {
        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const DeleteUserState.deleting(),
            const DeleteUserState.failure(Failure.permissionDenied()),
          ]),
        );

        await cubit.confirmAndDelete(2);
        await expectation;

        verifyNever(() => apiClient.deleteUser(any()));
        verifyNever(() => authCubit.forceLogout(notifyUser: false));
      },
    );
  });
}
