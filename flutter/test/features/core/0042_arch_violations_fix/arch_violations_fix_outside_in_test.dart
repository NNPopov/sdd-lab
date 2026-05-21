import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/create_tier/application/create_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/create_tier/application/create_tier_state.dart';
import 'package:flutter_application_1/features/tiers/create_tier/data/create_tier_adapter.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/entities/new_tier_data.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/usecases/create_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockPermissionCubit extends MockCubit<Set<Permission>>
    implements PermissionCubit {}

void main() {
  late _MockDio dio;
  late _MockAppLogger logger;
  late _MockPermissionCubit permissionCubit;
  late TiersApiClient apiClient;
  late CreateTierAdapter adapter;
  late CreateTierUseCase useCase;
  late CreateTierCubit cubit;

  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

  setUp(() {
    dio = _MockDio();
    logger = _MockAppLogger();
    permissionCubit = _MockPermissionCubit();

    when(() => dio.options).thenReturn(BaseOptions());
    when(() => permissionCubit.has(Permission.manageTiers)).thenReturn(true);

    apiClient = TiersApiClient(dio);
    adapter = CreateTierAdapter(apiClient, logger);
    useCase = CreateTierUseCase(adapter, permissionCubit);
    cubit = CreateTierCubit(useCase);
  });

  tearDown(() => cubit.close());

  test(
    'Scenario 1: successful tier creation emits Submitting then Success',
    () async {
      when(() => dio.fetch<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/tier'),
          data: {
            'id': 1,
            'name': 'Gold',
            'created_at': '2025-01-15T10:00:00',
          },
          statusCode: 200,
        ),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CreateTierSubmitting>(),
          isA<CreateTierSuccess>(),
        ]),
      );

      await cubit.submit(const NewTierData(name: 'Gold'));
      await expectation;

      final success = cubit.state as CreateTierSuccess;
      expect(success.tier.id, 1);
      expect(success.tier.name, 'Gold');
      verify(() => dio.fetch<Map<String, dynamic>>(any())).called(1);
    },
  );

  test(
    'Scenario 2: 422 ValidationFailure lands in Cubit state, not thrown',
    () async {
      when(() => dio.fetch<Map<String, dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/tier'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/tier'),
            statusCode: 422,
            data: {
              'detail': [
                {
                  'loc': ['body', 'name'],
                  'msg': 'Name already taken',
                  'type': 'value_error',
                },
              ],
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CreateTierSubmitting>(),
          isA<CreateTierFailure>(),
        ]),
      );

      await cubit.submit(const NewTierData(name: 'Gold'));
      await expectation;

      final state = cubit.state as CreateTierFailure;
      expect(state.failure, isA<ValidationFailure>());
      final validationFailure = state.failure as ValidationFailure;
      expect(validationFailure.fieldErrors['name'], 'Name already taken');
      verify(() => dio.fetch<Map<String, dynamic>>(any())).called(1);
    },
  );
}
