import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_cubit.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_state.dart';
import 'package:flutter_application_1/features/tiers/tier_details/data/dto/tier_detail_dto.dart';
import 'package:flutter_application_1/features/tiers/tier_details/data/get_tier_adapter.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/usecases/get_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTiersApiClient extends Mock implements TiersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockPermissionCubit extends Mock implements PermissionCubit {}

void main() {
  late _MockTiersApiClient apiClient;
  late _MockAppLogger logger;
  late _MockPermissionCubit permissionCubit;
  late GetTierAdapter adapter;
  late GetTierUsecase usecase;
  late TierDetailsCubit cubit;

  setUp(() {
    apiClient = _MockTiersApiClient();
    logger = _MockAppLogger();
    permissionCubit = _MockPermissionCubit();
    adapter = GetTierAdapter(apiClient, logger);
    usecase = GetTierUsecase(adapter, permissionCubit);
    cubit = TierDetailsCubit(usecase);
    when(() => permissionCubit.has(Permission.manageTiers)).thenReturn(true);
  });

  tearDown(() async => cubit.close());

  group('tier_details_id_contract outside-in', () {
    test(
      'Scenario 1: load(3) — server 200 — emits [loading, loaded(tier)]',
      () async {
        when(() => apiClient.getTier(3)).thenAnswer(
          (_) async => TierDetailDto(
            id: 3,
            name: 'Free',
            createdAt: DateTime(2026, 4, 25),
          ),
        );

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const TierDetailsState.loading(),
            isA<TierDetailsLoaded>(),
          ]),
        );

        await cubit.load(3);
        await expectation;

        final loaded = cubit.state as TierDetailsLoaded;
        expect(loaded.tier.id, 3);
        expect(loaded.tier.name, 'Free');
        verify(() => apiClient.getTier(3)).called(1);
      },
    );

    test(
      'Scenario 2: load(3) — server 404 — emits [loading, error(NotFoundFailure)]',
      () async {
        when(() => apiClient.getTier(3)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/tier/3'),
            response: Response(
              requestOptions: RequestOptions(path: '/tier/3'),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const TierDetailsState.loading(),
            isA<TierDetailsError>(),
          ]),
        );

        await cubit.load(3);
        await expectation;

        final error = cubit.state as TierDetailsError;
        expect(error.failure, isA<NotFoundFailure>());
        verify(() => apiClient.getTier(3)).called(1);
      },
    );
  });
}
