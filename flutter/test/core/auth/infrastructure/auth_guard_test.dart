import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/infrastructure/auth_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockNavigationResolver extends Mock implements NavigationResolver {}

class _MockStackRouter extends Mock implements StackRouter {}

class _MockRouteMatch extends Mock implements RouteMatch<void> {}

void main() {
  group('AuthGuard', () {
    late _MockAuthCubit authCubit;
    late AuthGuard guard;
    late _MockNavigationResolver resolver;
    late _MockStackRouter router;
    late _MockRouteMatch routeMatch;

    setUp(() {
      authCubit = _MockAuthCubit();
      guard = AuthGuard(authCubit);
      resolver = _MockNavigationResolver();
      router = _MockStackRouter();
      routeMatch = _MockRouteMatch();

      when(() => resolver.route).thenReturn(routeMatch);
      when(() => routeMatch.stringMatch).thenReturn('user/userson/edit');
    });

    test('allows navigation when authenticated', () {
      when(() => authCubit.state).thenReturn(const AuthState.authenticated());

      guard.onNavigation(resolver, router);

      verify(() => resolver.next()).called(1);
      verifyNever(() => resolver.next(false));
      verifyNever(() => router.pushPath(any()));
    });

    test('aborts navigation and pushes login with redirect '
        'when unauthenticated', () {
      when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
      when(() => router.pushPath(any())).thenAnswer((_) => Future.value());

      guard.onNavigation(resolver, router);

      verify(() => resolver.next(false)).called(1);
      final captured =
          verify(() => router.pushPath(captureAny())).captured.single as String;
      expect(captured, contains('/login?redirect='));
      expect(Uri.decodeFull(captured), contains('/user/userson/edit'));
    });
  });
}
