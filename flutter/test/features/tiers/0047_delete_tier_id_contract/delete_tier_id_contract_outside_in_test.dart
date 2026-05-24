import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_state.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/data/delete_tier_adapter.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/domain/usecases/delete_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTiersApiClient extends Mock implements TiersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockTiersApiClient apiClient;
  late _MockAppLogger logger;
  late _MockAuthCubit authCubit;
  late DeleteTierAdapter adapter;
  late DeleteTierUseCase useCase;
  late DeleteTierCubit cubit;

  setUp(() {
    apiClient = _MockTiersApiClient();
    logger = _MockAppLogger();
    authCubit = _MockAuthCubit();
    adapter = DeleteTierAdapter(apiClient, logger);
    useCase = DeleteTierUseCase(adapter);
    cubit = DeleteTierCubit(useCase, authCubit);
    when(() => authCubit.currentUser).thenReturn(
      const CurrentUser(
        username: 'admin',
        email: 'admin@example.com',
        name: 'Admin',
        isSuperuser: true,
        isModerator: false,
      ),
    );
  });

  tearDown(() async => cubit.close());

  group('delete_tier_id_contract outside-in', () {
    test(
      'Scenario 1: confirmAndDelete(1) — server 204 — emits [deleting, success]',
      () async {
        when(() => apiClient.deleteTier(1)).thenAnswer((_) async {});

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const DeleteTierState.deleting(),
            const DeleteTierState.success(),
          ]),
        );

        await cubit.confirmAndDelete(1);
        await expectation;

        verify(() => apiClient.deleteTier(1)).called(1);
      },
    );

    test(
      'Scenario 2: confirmAndDelete(1) — server 404 — emits [deleting, notFound]',
      () async {
        when(() => apiClient.deleteTier(1)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/tier/1'),
            response: Response(
              requestOptions: RequestOptions(path: '/tier/1'),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const DeleteTierState.deleting(),
            const DeleteTierState.notFound(),
          ]),
        );

        await cubit.confirmAndDelete(1);
        await expectation;

        verify(() => apiClient.deleteTier(1)).called(1);
      },
    );
  });
}
