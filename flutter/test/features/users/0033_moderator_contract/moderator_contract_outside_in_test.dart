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

DioException _makeDioError(int statusCode) => DioException(
  requestOptions: RequestOptions(),
  response: Response(
    requestOptions: RequestOptions(),
    statusCode: statusCode,
    data: <String, dynamic>{},
  ),
);

void main() {
  late _MockUsersApiClient api;
  late _MockAppLogger logger;
  late ModeratorManagementAdapter adapter;
  late AssignModeratorUseCase assignUseCase;
  late RevokeModeratorUseCase revokeUseCase;
  late AssignModeratorCubit cubit;

  setUp(() {
    api = _MockUsersApiClient();
    logger = _MockAppLogger();

    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);

    adapter = ModeratorManagementAdapter(api, logger);
    assignUseCase = AssignModeratorUseCase(adapter);
    revokeUseCase = RevokeModeratorUseCase(adapter);
    cubit = AssignModeratorCubit(assignUseCase, revokeUseCase);
  });

  tearDown(() async {
    await cubit.close();
  });

  test(
    'assign success — emits [loading, success(isModerator: true)]',
    () async {
      when(() => api.assignModerator('alice')).thenAnswer((_) async {});

      // expectLater must be set up BEFORE the action to avoid stream timing issues.
      final stateExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AssignModeratorLoading>(),
          isA<AssignModeratorSuccess>().having(
            (s) => s.isModerator,
            'isModerator',
            true,
          ),
        ]),
      );

      await cubit.assign('alice');
      await stateExpectation;

      verify(() => api.assignModerator('alice')).called(1);
    },
  );

  test(
    'assign conflict (409) — emits [loading, error(ConflictFailure)]',
    () async {
      when(() => api.assignModerator('alice')).thenThrow(_makeDioError(409));

      // expectLater must be set up BEFORE the action to avoid stream timing issues.
      final stateExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AssignModeratorLoading>(),
          isA<AssignModeratorError>().having(
            (s) => s.failure,
            'failure',
            isA<ConflictFailure>(),
          ),
        ]),
      );

      await cubit.assign('alice');
      await stateExpectation;

      verify(() => api.assignModerator('alice')).called(1);
    },
  );
}
