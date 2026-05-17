import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_event.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/auth_session.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/auth/domain/ports/auth_api_port.dart';
import 'package:flutter_application_1/core/auth/domain/ports/token_storage_port.dart';
import 'package:flutter_application_1/core/auth/infrastructure/token_holder.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthApiPort extends Mock implements AuthApiPort {}

class _MockTokenStoragePort extends Mock implements TokenStoragePort {}

void main() {
  late _MockAuthApiPort mockApi;
  late _MockTokenStoragePort mockStorage;
  late TokenHolder tokens;

  const session = AuthSession(accessToken: 'tok', username: 'alice');
  const me = CurrentUser(
    username: 'alice',
    email: 'alice@example.com',
    name: 'Alice',
    isSuperuser: false,
    isModerator: false,
  );
  const loginFailure = Failure.invalidCredentials(message: 'Wrong password');

  setUpAll(() {
    registerFallbackValue(const AuthSession(accessToken: '', username: ''));
  });

  AuthCubit buildCubit() => AuthCubit(mockApi, mockStorage, tokens);

  setUp(() {
    mockApi = _MockAuthApiPort();
    mockStorage = _MockTokenStoragePort();
    tokens = TokenHolder();
  });

  group('bootstrap', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Unauthenticated] when storage is empty',
      build: buildCubit,
      setUp: () => when(() => mockStorage.read()).thenAnswer((_) async => null),
      act: (c) => c.bootstrap(),
      expect: () => [const AuthUnauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Authenticated(currentUser)] when session found and /me succeeds',
      build: buildCubit,
      setUp: () {
        when(() => mockStorage.read()).thenAnswer((_) async => session);
        when(
          () => mockApi.getCurrentUser(),
        ).thenAnswer((_) async => const Right(me));
      },
      act: (c) => c.bootstrap(),
      expect: () => [const AuthAuthenticated(currentUser: me)],
      verify: (_) => expect(tokens.current, 'tok'),
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Unauthenticated] and clears storage when /me fails',
      build: buildCubit,
      setUp: () {
        when(() => mockStorage.read()).thenAnswer((_) async => session);
        when(() => mockApi.getCurrentUser()).thenAnswer(
          (_) async => const Left(
            Failure.invalidCredentials(message: 'Unauthorized'),
          ),
        );
        when(() => mockStorage.clear()).thenAnswer((_) async {});
      },
      act: (c) => c.bootstrap(),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) {
        verify(() => mockStorage.clear()).called(1);
        expect(tokens.current, isNull);
      },
    );

    test(
      'bootstrap /me failure does NOT emit SessionExpiredEvent',
      () async {
        when(() => mockStorage.read()).thenAnswer((_) async => session);
        when(() => mockApi.getCurrentUser()).thenAnswer(
          (_) async => const Left(
            Failure.invalidCredentials(message: 'Unauthorized'),
          ),
        );
        when(() => mockStorage.clear()).thenAnswer((_) async {});

        final cubit = buildCubit();
        final events = <AuthEvent>[];
        final sub = cubit.events.listen(events.add);

        await cubit.bootstrap();
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);
        await sub.cancel();
        await cubit.close();
      },
    );
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Authenticating, Authenticated(me)] on login + /me success',
      build: buildCubit,
      setUp: () {
        when(
          () => mockApi.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Right(session));
        when(() => mockStorage.write(any())).thenAnswer((_) async {});
        when(
          () => mockApi.getCurrentUser(),
        ).thenAnswer((_) async => const Right(me));
      },
      act: (c) => c.login(username: 'alice', password: 's3cr3t'),
      expect: () => [
        const AuthAuthenticating(),
        const AuthAuthenticated(currentUser: me),
      ],
      verify: (_) {
        verify(() => mockStorage.write(session)).called(1);
        expect(tokens.current, 'tok');
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Authenticating, Authenticated(null)] when /me fails after login',
      build: buildCubit,
      setUp: () {
        when(
          () => mockApi.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Right(session));
        when(() => mockStorage.write(any())).thenAnswer((_) async {});
        when(
          () => mockApi.getCurrentUser(),
        ).thenAnswer((_) async => const Left(Failure.network()));
      },
      act: (c) => c.login(username: 'alice', password: 's3cr3t'),
      expect: () => [
        const AuthAuthenticating(),
        const AuthAuthenticated(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Authenticating, AuthError] on invalid credentials',
      build: buildCubit,
      setUp: () => when(
        () => mockApi.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(loginFailure)),
      act: (c) => c.login(username: 'alice', password: 'wrong'),
      expect: () => [
        const AuthAuthenticating(),
        const AuthError(loginFailure),
      ],
    );
  });

  group('logout', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Unauthenticated] and clears token + storage',
      build: buildCubit,
      seed: () => const AuthAuthenticated(),
      setUp: () {
        tokens.current = 'tok';
        when(() => mockApi.logout()).thenAnswer((_) async => const Right(unit));
        when(() => mockStorage.clear()).thenAnswer((_) async {});
      },
      act: (c) => c.logout(),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) {
        verify(() => mockApi.logout()).called(1);
        verify(() => mockStorage.clear()).called(1);
        expect(tokens.current, isNull);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'does nothing when not authenticated',
      build: buildCubit,
      seed: () => const AuthUnauthenticated(),
      act: (c) => c.logout(),
      expect: () => <AuthState>[],
    );
  });

  group('forceLogout', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Unauthenticated] and clears token + storage when authenticated',
      build: buildCubit,
      seed: () => const AuthAuthenticated(),
      setUp: () {
        tokens.current = 'tok';
        when(() => mockStorage.clear()).thenAnswer((_) async {});
      },
      act: (c) => c.forceLogout(),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) {
        verify(() => mockStorage.clear()).called(1);
        expect(tokens.current, isNull);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'does nothing when already unauthenticated',
      build: buildCubit,
      seed: () => const AuthUnauthenticated(),
      setUp: () => when(() => mockStorage.clear()).thenAnswer((_) async {}),
      act: (c) => c.forceLogout(),
      expect: () => <AuthState>[],
    );

    test(
      'forceLogout emits SessionExpiredEvent when not unauthenticated',
      () async {
        when(() => mockStorage.clear()).thenAnswer((_) async {});
        tokens.current = 'tok';

        final cubit = buildCubit();
        final events = <AuthEvent>[];
        final sub = cubit.events.listen(events.add);

        await cubit.forceLogout();
        await Future<void>.delayed(Duration.zero);

        expect(events, [isA<SessionExpiredEvent>()]);
        await sub.cancel();
        await cubit.close();
      },
    );

    test(
      'forceLogout does NOT emit SessionExpiredEvent '
      'when already unauthenticated',
      () async {
        when(() => mockStorage.read()).thenAnswer((_) async => null);
        when(() => mockStorage.clear()).thenAnswer((_) async {});

        final cubit = buildCubit();
        await cubit.bootstrap();
        expect(cubit.state, const AuthUnauthenticated());

        final events = <AuthEvent>[];
        final sub = cubit.events.listen(events.add);

        await cubit.forceLogout();
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);
        await sub.cancel();
        await cubit.close();
      },
    );
  });
}
