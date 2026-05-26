import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/data/auth_api_adapter.dart';
import 'package:flutter_application_1/core/auth/data/auth_api_client.dart';
import 'package:flutter_application_1/core/auth/data/dto/current_user_dto.dart';
import 'package:flutter_application_1/core/auth/domain/entities/auth_session.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/auth/domain/ports/token_storage_port.dart';
import 'package:flutter_application_1/core/auth/infrastructure/token_holder.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApiClient extends Mock implements AuthApiClient {}

class _MockTokenStoragePort extends Mock implements TokenStoragePort {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockAuthApiClient apiClient;
  late _MockTokenStoragePort storage;
  late _MockAppLogger logger;
  late TokenHolder tokens;
  late AuthApiAdapter adapter;
  late AuthCubit cubit;

  // A GET /user/me/-shaped payload carrying the user's numeric id.
  const meJson = <String, dynamic>{
    'id': 42,
    'name': 'Ada Lovelace',
    'username': 'ada',
    'email': 'ada@example.com',
    'is_superuser': false,
    'is_moderator': false,
  };

  const session = AuthSession(accessToken: 'tok', username: 'ada');

  setUp(() {
    apiClient = _MockAuthApiClient();
    storage = _MockTokenStoragePort();
    logger = _MockAppLogger();
    tokens = TokenHolder();
    adapter = AuthApiAdapter(apiClient, logger);
    cubit = AuthCubit(adapter, storage, tokens);
  });

  tearDown(() async => cubit.close());

  group('current_user_id_field outside-in', () {
    test(
      'Scenario 1: bootstrap carries id from /user/me/ into authenticated state',
      () async {
        when(() => storage.read()).thenAnswer((_) async => session);
        when(
          () => apiClient.getCurrentUser(),
        ).thenAnswer((_) async => CurrentUserDto.fromJson(meJson));

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([isA<AuthAuthenticated>()]),
        );

        await cubit.bootstrap();
        await expectation;

        final state = cubit.state as AuthAuthenticated;
        final user = state.currentUser!;
        expect(user.id, 42);
        expect(user.username, 'ada');
        expect(user.email, 'ada@example.com');
        expect(user.name, 'Ada Lovelace');

        verify(() => apiClient.getCurrentUser()).called(1);
        verifyNever(() => logger.error(any()));
      },
    );

    test(
      'Scenario 2: id is part of CurrentUser identity',
      () async {
        when(() => storage.read()).thenAnswer((_) async => session);
        when(
          () => apiClient.getCurrentUser(),
        ).thenAnswer((_) async => CurrentUserDto.fromJson(meJson));

        await cubit.bootstrap();

        final user = (cubit.state as AuthAuthenticated).currentUser!;

        const differentId = CurrentUser(
          id: 99,
          username: 'ada',
          email: 'ada@example.com',
          name: 'Ada Lovelace',
          isSuperuser: false,
          isModerator: false,
        );
        const sameId = CurrentUser(
          id: 42,
          username: 'ada',
          email: 'ada@example.com',
          name: 'Ada Lovelace',
          isSuperuser: false,
          isModerator: false,
        );

        expect(user == differentId, isFalse);
        expect(user.hashCode == differentId.hashCode, isFalse);
        expect(user == sameId, isTrue);
        expect(user.hashCode == sameId.hashCode, isTrue);
      },
    );
  });
}
