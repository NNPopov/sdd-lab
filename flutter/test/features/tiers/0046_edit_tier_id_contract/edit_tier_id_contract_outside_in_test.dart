import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_state.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/data/dto/edit_tier_request_dto.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/data/edit_tier_adapter.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/entities/edit_tier_data.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/usecases/edit_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTiersApiClient extends Mock implements TiersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockTiersApiClient apiClient;
  late _MockAppLogger logger;
  late EditTierAdapter adapter;
  late EditTierUseCase useCase;
  late EditTierCubit cubit;

  setUpAll(() {
    registerFallbackValue(const EditTierRequestDto(name: ''));
  });

  setUp(() {
    apiClient = _MockTiersApiClient();
    logger = _MockAppLogger();
    adapter = EditTierAdapter(apiClient, logger);
    useCase = EditTierUseCase(adapter);
    cubit = EditTierCubit(useCase);
  });

  tearDown(() async => cubit.close());

  group('edit_tier_id_contract outside-in', () {
    test(
      'Scenario 1: submit tierId=1 — server 204 — emits [submitting, success(premium)]',
      () async {
        when(() => apiClient.patchTier(1, any())).thenAnswer((_) async {});

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const EditTierState.submitting(),
            isA<EditTierSuccess>(),
          ]),
        );

        await cubit.submit(
          data: EditTierData(tierId: 1, name: 'premium'),
          isSuperuser: true,
        );
        await expectation;

        final success = cubit.state as EditTierSuccess;
        expect(success.newName, 'premium');
        verify(
          () =>
              apiClient.patchTier(1, const EditTierRequestDto(name: 'premium')),
        ).called(1);
      },
    );

    test(
      'Scenario 2: submit tierId=1 — server 404 — emits [submitting, failure(NotFoundFailure)]',
      () async {
        when(() => apiClient.patchTier(1, any())).thenThrow(
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
            const EditTierState.submitting(),
            isA<EditTierFailure>(),
          ]),
        );

        await cubit.submit(
          data: EditTierData(tierId: 1, name: 'premium'),
          isSuperuser: true,
        );
        await expectation;

        final error = cubit.state as EditTierFailure;
        expect(error.failure, isA<NotFoundFailure>());
        verify(() => apiClient.patchTier(1, any())).called(1);
      },
    );
  });
}
