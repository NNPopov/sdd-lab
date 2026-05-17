import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/auth/infrastructure/auth_guard.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/i18n/locale_cubit.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/application/list_tiers_cubit.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/application/list_tiers_state.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_cubit.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_state.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_cubit.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks & stubs
// ---------------------------------------------------------------------------

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockLocaleCubit extends MockCubit<AppLocale> implements LocaleCubit {}

class _MockUsersListCubit extends MockCubit<UsersListState>
    implements UsersListCubit {}

class _MockListTiersCubit extends MockCubit<ListTiersState>
    implements ListTiersCubit {}

class _MockCreateUserCubit extends MockCubit<CreateUserState>
    implements CreateUserCubit {}

/// Subclass of the real AuthGuard that always allows navigation.
/// Necessary because AppRouter.authGuard expects the concrete AuthGuard type.
class _PermissiveAuthGuard extends AuthGuard {
  _PermissiveAuthGuard(AuthCubit auth) : super(auth);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      resolver.next();
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildApp({
  required _MockAuthCubit authCubit,
  required PermissionCubit permCubit,
}) {
  final localeCubit = _MockLocaleCubit();
  whenListen(
    localeCubit,
    const Stream<AppLocale>.empty(),
    initialState: AppLocale.en,
  );

  final router = AppRouter(
    authGuard: _PermissiveAuthGuard(authCubit),
    permissionCubit: permCubit,
  );
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<PermissionCubit>.value(value: permCubit),
      BlocProvider<LocaleCubit>.value(value: localeCubit),
    ],
    child: TranslationProvider(
      child: MaterialApp.router(routerConfig: router.config()),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockAuthCubit authCubit;
  late PermissionCubit permCubit;
  late StreamController<AuthState> authStateCtrl;

  setUp(() {
    authStateCtrl = StreamController<AuthState>.broadcast();
    authCubit = _MockAuthCubit();
    when(() => authCubit.stream).thenAnswer((_) => authStateCtrl.stream);
  });

  tearDown(() async {
    await authStateCtrl.close();
    await authCubit.close();
    await permCubit.close();
    await getIt.reset();
  });

  /// Sets up auth state, creates PermissionCubit, and registers stub page
  /// cubits so that UsersPage / ListTiersPage don't crash on getIt lookups.
  void prepare(AuthState state) {
    when(() => authCubit.state).thenReturn(state);
    permCubit = PermissionCubit(authCubit);

    getIt
      ..registerFactory<UsersListCubit>(() {
        final c = _MockUsersListCubit();
        when(() => c.stream).thenAnswer((_) => const Stream.empty());
        when(() => c.state).thenReturn(const UsersListState.initial());
        when(c.fetchUsers).thenAnswer((_) async {});
        return c;
      })
      ..registerFactory<ListTiersCubit>(() {
        final c = _MockListTiersCubit();
        when(() => c.stream).thenAnswer((_) => const Stream.empty());
        when(() => c.state).thenReturn(const ListTiersState.initial());
        when(c.load).thenAnswer((_) async {});
        return c;
      });
  }

  group('AppShellScreen — tab visibility', () {
    testWidgets(
      'unauthenticated: shows Users tab, hides Tiers',
      (tester) async {
        prepare(const AuthState.unauthenticated());

        await tester.pumpWidget(
          _buildApp(authCubit: authCubit, permCubit: permCubit),
        );
        await tester.pumpAndSettle();

        expect(find.text('Users'), findsOneWidget);
        expect(find.text('Tiers'), findsNothing);
      },
    );

    testWidgets('authenticated non-superuser: shows Users tab, hides Tiers', (
      tester,
    ) async {
      prepare(
        const AuthState.authenticated(
          currentUser: CurrentUser(
            username: 'alice',
            email: 'alice@example.com',
            name: 'Alice',
            isSuperuser: false,
            isModerator: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _buildApp(authCubit: authCubit, permCubit: permCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Tiers'), findsNothing);
    });

    testWidgets('superuser: shows both Users and Tiers tabs', (tester) async {
      prepare(
        const AuthState.authenticated(
          currentUser: CurrentUser(
            username: 'admin',
            email: 'admin@example.com',
            name: 'Admin',
            isSuperuser: true,
            isModerator: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _buildApp(authCubit: authCubit, permCubit: permCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Tiers'), findsOneWidget);
    });

    testWidgets('superuser on Tiers tab → logout → Tiers tab disappears', (
      tester,
    ) async {
      prepare(
        const AuthState.authenticated(
          currentUser: CurrentUser(
            username: 'admin',
            email: 'admin@example.com',
            name: 'Admin',
            isSuperuser: true,
            isModerator: false,
          ),
        ),
      );

      await tester.pumpWidget(
        _buildApp(authCubit: authCubit, permCubit: permCubit),
      );
      await tester.pumpAndSettle();

      // Superuser sees both tabs; tap Tiers to navigate there (index 2)
      expect(find.text('Tiers'), findsOneWidget);
      await tester.tap(find.text('Tiers'));
      await tester.pumpAndSettle();

      // Emit unauthenticated — BlocListener switches back to index 0,
      // BlocBuilder hides the Tiers tab button
      when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
      authStateCtrl.add(const AuthState.unauthenticated());
      await tester.pumpAndSettle();

      expect(find.text('Tiers'), findsNothing);
      expect(find.text('Users'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 5a — AutoLeadingButton
  // ---------------------------------------------------------------------------

  group('AppShellScreen — AutoLeadingButton', () {
    testWidgets('AutoLeadingButton is NOT present in the shell AppBar', (
      tester,
    ) async {
      prepare(const AuthState.unauthenticated());

      await tester.pumpWidget(
        _buildApp(authCubit: authCubit, permCubit: permCubit),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AutoLeadingButton), findsNothing);
    });

    testWidgets(
      'no back button rendered at the root of the Users tab',
      (tester) async {
        prepare(const AuthState.unauthenticated());

        await tester.pumpWidget(
          _buildApp(authCubit: authCubit, permCubit: permCubit),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BackButton), findsNothing);
      },
    );

    testWidgets(
      'exactly one BackButton in child screen AppBar after pushing a route',
      (tester) async {
        final createUserCubit = _MockCreateUserCubit();
        when(
          () => createUserCubit.stream,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => createUserCubit.state,
        ).thenReturn(const CreateUserState.initial());
        getIt.registerFactory<CreateUserCubit>(() => createUserCubit);

        prepare(const AuthState.unauthenticated());

        final localeCubit = _MockLocaleCubit();
        whenListen(
          localeCubit,
          const Stream<AppLocale>.empty(),
          initialState: AppLocale.en,
        );
        final router = AppRouter(
          authGuard: _PermissiveAuthGuard(authCubit),
          permissionCubit: permCubit,
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<PermissionCubit>.value(value: permCubit),
              BlocProvider<LocaleCubit>.value(value: localeCubit),
            ],
            child: TranslationProvider(
              child: MaterialApp.router(routerConfig: router.config()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No back button at root
        expect(find.byType(BackButton), findsNothing);

        // Push CreateUserRoute onto the Users tab's inner stack
        await router.navigate(const CreateUserRoute());
        await tester.pumpAndSettle();

        // Shell AppBar has no back button (automaticallyImplyLeading: false).
        // The pushed child screen's own AppBar auto-implies exactly one BackButton.
        expect(find.byType(BackButton), findsOneWidget);
      },
    );
  });
}
