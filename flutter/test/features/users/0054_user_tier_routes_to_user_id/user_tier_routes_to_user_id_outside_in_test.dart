import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_state.dart';
import 'package:flutter_application_1/features/users/get_user_tier/data/dto/user_tier_dto.dart';
import 'package:flutter_application_1/features/users/get_user_tier/data/get_user_tier_adapter.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/usecases/get_user_tier_usecase.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_state.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/dto/paginated_tier_options_dto.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/dto/tier_option_dto.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/dto/update_user_tier_request_dto.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/fetch_tiers_adapter.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/update_user_tier_adapter.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/usecases/fetch_tiers_usecase.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/usecases/update_user_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

// The viewed user whose tier is read/updated — identity is the integer id.
const _userId = 7;

CurrentUser _currentUser({required bool isSuperuser}) => CurrentUser(
  id: 1,
  username: 'admin',
  email: 'admin@example.com',
  name: 'Admin',
  isSuperuser: isSuperuser,
  isModerator: false,
);

DioException _dioError(int statusCode) {
  final options = RequestOptions(path: '/user/$_userId/tier');
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
  late _MockAuthCubit authCubit;

  // Read vertical — wired real end to end.
  late GetUserTierAdapter getAdapter;
  late GetUserTierUseCase getUseCase;
  late GetUserTierCubit getCubit;

  // Write vertical — wired real end to end (fetch_tiers wired only to reach
  // the tiersLoaded state; it is not under migration).
  late UpdateUserTierAdapter updateAdapter;
  late UpdateUserTierUseCase updateUseCase;
  late FetchTiersAdapter fetchTiersAdapter;
  late FetchTiersUseCase fetchTiersUseCase;
  late UpdateUserTierCubit updateCubit;

  setUpAll(() {
    registerFallbackValue(const UpdateUserTierRequestDto(tierId: 0));
  });

  setUp(() {
    apiClient = _MockUsersApiClient();
    logger = _MockAppLogger();
    authCubit = _MockAuthCubit();

    getAdapter = GetUserTierAdapter(apiClient, logger);
    getUseCase = GetUserTierUseCase(getAdapter);
    getCubit = GetUserTierCubit(getUseCase);

    updateAdapter = UpdateUserTierAdapter(apiClient, logger);
    updateUseCase = UpdateUserTierUseCase(updateAdapter);
    fetchTiersAdapter = FetchTiersAdapter(apiClient, logger);
    fetchTiersUseCase = FetchTiersUseCase(fetchTiersAdapter);
    updateCubit = UpdateUserTierCubit(
      fetchTiersUseCase,
      updateUseCase,
      authCubit,
    );

    // The dropdown source — one selectable tier (id 3).
    when(
      () => apiClient.getTiersForSelection(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedTierOptionsDto(
        items: [TierOptionDto(id: 3, name: 'Gold')],
      ),
    );
  });

  tearDown(() async {
    await getCubit.close();
    await updateCubit.close();
  });

  group('user_tier_routes_to_user_id outside-in', () {
    test(
      'Scenario 1: read path — load(7) emits [loading, loaded] and calls '
      'getUserTier(7) with the integer id',
      () async {
        when(() => apiClient.getUserTier(_userId)).thenAnswer(
          (_) async => const UserTierDto(tierId: 3, tierName: 'Gold'),
        );

        final expectation = expectLater(
          getCubit.stream,
          emitsInOrder([
            const GetUserTierState.loading(),
            isA<GetUserTierLoaded>(),
          ]),
        );

        await getCubit.load(_userId);
        await expectation;

        verify(() => apiClient.getUserTier(_userId)).called(1);
        final loaded = getCubit.state as GetUserTierLoaded;
        expect(loaded.tier.tierName, 'Gold');
      },
    );

    test(
      'Scenario 2: read path — 404 maps to NotFoundFailure '
      '("Tier not assigned")',
      () async {
        when(() => apiClient.getUserTier(_userId)).thenThrow(_dioError(404));

        final expectation = expectLater(
          getCubit.stream,
          emitsInOrder([
            const GetUserTierState.loading(),
            isA<GetUserTierError>(),
          ]),
        );

        await getCubit.load(_userId);
        await expectation;

        verify(() => apiClient.getUserTier(_userId)).called(1);
        final error = getCubit.state as GetUserTierError;
        expect(error.failure, isA<NotFoundFailure>());
      },
    );

    test(
      'Scenario 3: write path — superuser submit(7) calls patchUserTier(7, …) '
      'and ends in success',
      () async {
        when(
          () => authCubit.currentUser,
        ).thenReturn(_currentUser(isSuperuser: true));
        when(
          () => apiClient.patchUserTier(_userId, any()),
        ).thenAnswer((_) async {});

        final expectation = expectLater(
          updateCubit.stream,
          emitsInOrder([
            isA<UpdateUserTierLoadingTiers>(),
            isA<UpdateUserTierTiersLoaded>(),
            isA<UpdateUserTierTiersLoaded>(),
            isA<UpdateUserTierSubmitting>(),
            isA<UpdateUserTierSuccess>(),
          ]),
        );

        await updateCubit.loadTiers();
        updateCubit.selectTier(3);
        await updateCubit.submit(_userId);
        await expectation;

        verify(() => apiClient.patchUserTier(_userId, any())).called(1);
      },
    );

    test(
      'Scenario 4: write path — non-superuser submit(7) is refused by the '
      'guard, no PATCH is sent',
      () async {
        when(
          () => authCubit.currentUser,
        ).thenReturn(_currentUser(isSuperuser: false));

        final expectation = expectLater(
          updateCubit.stream,
          emitsInOrder([
            isA<UpdateUserTierLoadingTiers>(),
            isA<UpdateUserTierTiersLoaded>(),
            isA<UpdateUserTierTiersLoaded>(),
            isA<UpdateUserTierSubmitting>(),
            isA<UpdateUserTierError>(),
          ]),
        );

        await updateCubit.loadTiers();
        updateCubit.selectTier(3);
        await updateCubit.submit(_userId);
        await expectation;

        final error = updateCubit.state as UpdateUserTierError;
        expect(error.failure, isA<PermissionDenied>());
        verifyNever(() => apiClient.patchUserTier(any(), any()));
      },
    );
  });
}
