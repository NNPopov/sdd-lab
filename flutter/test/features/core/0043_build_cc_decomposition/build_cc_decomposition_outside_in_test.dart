import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/create_user_request_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/user_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_cubit.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_state.dart';
import 'package:flutter_application_1/features/users/create_user/data/create_user_adapter.dart';
import 'package:flutter_application_1/features/users/create_user/domain/entities/new_user_data.dart';
import 'package:flutter_application_1/features/users/create_user/domain/usecases/create_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

DioException _makeDioError(int statusCode, [Map<String, dynamic>? data]) =>
    DioException(
      requestOptions: RequestOptions(),
      response: Response(
        requestOptions: RequestOptions(),
        statusCode: statusCode,
        data: data ?? <String, dynamic>{},
      ),
    );

void main() {
  late _MockUsersApiClient api;
  late _MockAppLogger logger;
  late CreateUserCubit cubit;

  const submitData = NewUserData(
    name: 'New User',
    username: 'newuser',
    email: 'new@example.com',
    password: 'Password1!',
  );

  setUpAll(() {
    registerFallbackValue(
      const CreateUserRequestDto(
        name: '',
        username: '',
        email: '',
        password: '',
      ),
    );
  });

  setUp(() {
    api = _MockUsersApiClient();
    logger = _MockAppLogger();
    // Wire real: Adapter → UseCase → Cubit (system under test).
    final adapter = CreateUserAdapter(api, logger);
    final useCase = CreateUserUseCase(adapter);
    cubit = CreateUserCubit(useCase);
  });

  tearDown(() => cubit.close());

  group('0043 build_cc_decomposition — CreateUser chain outside-in', () {
    test(
      'scenario 1: server 200 — cubit emits [submitting, success]',
      () async {
        const userDto = UserDto(
          id: 1,
          name: 'New User',
          username: 'newuser',
          email: 'new@example.com',
          isModerator: false,
        );
        when(() => api.createUser(any())).thenAnswer((_) async => userDto);

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const CreateUserState.submitting(),
            isA<CreateUserSuccess>(),
          ]),
        );
        await cubit.submit(submitData);
        await expectation;

        final state = cubit.state as CreateUserSuccess;
        expect(state.user.username, 'newuser');
        verifyNever(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        );
      },
    );

    test(
      'scenario 2: server 422 — cubit emits [submitting, CreateUserValidationError] '
      'with the server message; not CreateUserFailure',
      () async {
        when(() => api.createUser(any())).thenThrow(
          _makeDioError(422, {'detail': 'That username is taken'}),
        );

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const CreateUserState.submitting(),
            isA<CreateUserValidationError>().having(
              (s) => s.message,
              'message',
              'That username is taken',
            ),
          ]),
        );
        await cubit.submit(submitData);
        await expectation;

        verifyNever(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        );
      },
    );

    test(
      'scenario 3: unexpected exception — cubit emits [submitting, failure(UnknownFailure)] '
      'and logger.error is called once',
      () async {
        when(() => api.createUser(any())).thenThrow(StateError('unexpected'));
        when(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).thenReturn(null);

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const CreateUserState.submitting(),
            isA<CreateUserFailure>().having(
              (s) => s.failure,
              'failure',
              isA<UnknownFailure>(),
            ),
          ]),
        );
        await cubit.submit(submitData);
        await expectation;

        verify(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      },
    );
  });
}
