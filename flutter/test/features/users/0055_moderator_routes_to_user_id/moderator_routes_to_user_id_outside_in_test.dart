import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/moderator_contract/application/assign_moderator_cubit.dart';
import 'package:flutter_application_1/features/users/moderator_contract/application/assign_moderator_state.dart';
import 'package:flutter_application_1/features/users/moderator_contract/data/moderator_management_adapter.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/usecases/assign_moderator_usecase.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/usecases/revoke_moderator_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

// The viewed user being promoted/demoted — identity is the integer id.
const _userId = 7;

DioException _dioError(int statusCode) {
  final options = RequestOptions(path: '/user/$_userId/assign-moderator');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
    ),
  );
}

void main() {
  late _MockUsersApiClient apiClient;
  late _MockAppLogger logger;

  // The moderator vertical — wired real end to end. One cubit serves both
  // assign and revoke; no AuthCubit is needed (no identity comparison).
  late ModeratorManagementAdapter adapter;
  late AssignModeratorUseCase assignUseCase;
  late RevokeModeratorUseCase revokeUseCase;
  late AssignModeratorCubit cubit;

  setUp(() {
    apiClient = _MockUsersApiClient();
    logger = _MockAppLogger();

    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);

    adapter = ModeratorManagementAdapter(apiClient, logger);
    assignUseCase = AssignModeratorUseCase(adapter);
    revokeUseCase = RevokeModeratorUseCase(adapter);
    cubit = AssignModeratorCubit(assignUseCase, revokeUseCase);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('moderator_routes_to_user_id outside-in', () {
    test(
      'Scenario 1: assign(7) calls assignModerator(7) with the integer id and '
      'emits [loading, success(isModerator: true)]',
      () async {
        when(() => apiClient.assignModerator(_userId)).thenAnswer((_) async {});

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const AssignModeratorState.loading(),
            isA<AssignModeratorSuccess>().having(
              (s) => s.isModerator,
              'isModerator',
              true,
            ),
          ]),
        );

        await cubit.assign(_userId);
        await expectation;

        verify(() => apiClient.assignModerator(_userId)).called(1);
      },
    );

    test(
      'Scenario 2: revoke(7) calls revokeModerator(7) with the integer id and '
      'emits [loading, success(isModerator: false)]',
      () async {
        when(() => apiClient.revokeModerator(_userId)).thenAnswer((_) async {});

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const AssignModeratorState.loading(),
            isA<AssignModeratorSuccess>().having(
              (s) => s.isModerator,
              'isModerator',
              false,
            ),
          ]),
        );

        await cubit.revoke(_userId);
        await expectation;

        verify(() => apiClient.revokeModerator(_userId)).called(1);
      },
    );

    test(
      'Scenario 3: assign(7) maps a 409 to ConflictFailure and emits '
      '[loading, error(ConflictFailure)]',
      () async {
        when(
          () => apiClient.assignModerator(_userId),
        ).thenThrow(_dioError(409));

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const AssignModeratorState.loading(),
            isA<AssignModeratorError>().having(
              (s) => s.failure,
              'failure',
              isA<ConflictFailure>(),
            ),
          ]),
        );

        await cubit.assign(_userId);
        await expectation;

        verify(() => apiClient.assignModerator(_userId)).called(1);
      },
    );
  });
}
