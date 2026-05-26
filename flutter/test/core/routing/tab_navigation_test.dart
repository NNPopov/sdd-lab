import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/auth/infrastructure/auth_guard.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/locale_cubit.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/core/widgets/locale_selector_button.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_cubit.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_state.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_state.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_cubit.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_state.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_state.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/application/list_tiers_cubit.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/application/list_tiers_state.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_cubit.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_state.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_state.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_cubit.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_state.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_state.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_cubit.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockLocaleCubit extends MockCubit<AppLocale> implements LocaleCubit {}

class _MockUsersListCubit extends MockCubit<UsersListState>
    implements UsersListCubit {}

class _MockUserDetailsCubit extends MockCubit<UserDetailsState>
    implements UserDetailsCubit {}

class _MockGetUserTierCubit extends MockCubit<GetUserTierState>
    implements GetUserTierCubit {}

class _MockUpdateUserTierCubit extends MockCubit<UpdateUserTierState>
    implements UpdateUserTierCubit {}

class _MockPostDetailsCubit extends MockCubit<PostDetailsState>
    implements PostDetailsCubit {}

class _MockDeletePostCubit extends MockCubit<DeletePostState>
    implements DeletePostCubit {}

class _MockListPostsCubit extends MockCubit<ListPostsState>
    implements ListPostsCubit {}

class _MockListTiersCubit extends MockCubit<ListTiersState>
    implements ListTiersCubit {}

class _MockTierDetailsCubit extends MockCubit<TierDetailsState>
    implements TierDetailsCubit {}

class _MockDeleteTierCubit extends MockCubit<DeleteTierState>
    implements DeleteTierCubit {}

class _PermissiveAuthGuard extends AuthGuard {
  _PermissiveAuthGuard(AuthCubit auth) : super(auth);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      resolver.next();
}

// The details screen now sources its AppBar title from the loaded user, so the
// mocked cubit must report a loaded state for the title to render.
const _aliceUser = User(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
  isModerator: false,
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildApp({
  required AppRouter router,
  required _MockAuthCubit authCubit,
  required PermissionCubit permCubit,
  required _MockLocaleCubit localeCubit,
}) {
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
  late _MockLocaleCubit localeCubit;
  late AppRouter router;
  late StreamController<AuthState> authStateCtrl;

  setUp(() {
    authStateCtrl = StreamController<AuthState>.broadcast();
    authCubit = _MockAuthCubit();
    localeCubit = _MockLocaleCubit();
    when(() => authCubit.stream).thenAnswer((_) => authStateCtrl.stream);
    whenListen(
      localeCubit,
      const Stream<AppLocale>.empty(),
      initialState: AppLocale.enUs,
    );
  });

  tearDown(() async {
    await authStateCtrl.close();
    await authCubit.close();
    await permCubit.close();
    await getIt.reset();
  });

  void prepareAuth(AuthState state) {
    when(() => authCubit.state).thenReturn(state);
    permCubit = PermissionCubit(authCubit);
    router = AppRouter(
      authGuard: _PermissiveAuthGuard(authCubit),
      permissionCubit: permCubit,
    );
  }

  void registerUsersListMock() {
    getIt.registerFactory<UsersListCubit>(() {
      final c = _MockUsersListCubit();
      when(() => c.stream).thenAnswer((_) => const Stream.empty());
      when(() => c.state).thenReturn(const UsersListState.initial());
      when(c.fetchUsers).thenAnswer((_) async {});
      return c;
    });
  }

  void registerUserDetailsMocks() {
    getIt
      ..registerFactory<UserDetailsCubit>(() {
        final c = _MockUserDetailsCubit();
        when(() => c.stream).thenAnswer((_) => const Stream.empty());
        when(
          () => c.state,
        ).thenReturn(const UserDetailsState.loaded(_aliceUser));
        when(() => c.load(any())).thenAnswer((_) async {});
        when(() => c.retry(any())).thenAnswer((_) async {});
        return c;
      })
      ..registerFactory<GetUserTierCubit>(() {
        final c = _MockGetUserTierCubit();
        when(() => c.stream).thenAnswer((_) => const Stream.empty());
        when(() => c.state).thenReturn(const GetUserTierState.initial());
        when(() => c.load(any())).thenAnswer((_) async {});
        return c;
      })
      ..registerFactory<UpdateUserTierCubit>(() {
        final c = _MockUpdateUserTierCubit();
        when(() => c.stream).thenAnswer((_) => const Stream.empty());
        when(() => c.state).thenReturn(const UpdateUserTierState.initial());
        when(c.loadTiers).thenAnswer((_) async {});
        when(c.reset).thenReturn(null);
        return c;
      });
  }

  void registerListPostsMock() {
    getIt.registerFactory<ListPostsCubit>(() {
      final c = _MockListPostsCubit();
      when(() => c.stream).thenAnswer((_) => const Stream.empty());
      when(() => c.state).thenReturn(const ListPostsState.initial());
      when(c.load).thenAnswer((_) async {});
      return c;
    });
  }

  void registerPostDetailsMocks() {
    getIt
      ..registerFactory<PostDetailsCubit>(() {
        final c = _MockPostDetailsCubit();
        when(() => c.stream).thenAnswer((_) => const Stream.empty());
        // Use error state — initial/loading shows CircularProgressIndicator
        // which never settles in pumpAndSettle.
        when(
          () => c.state,
        ).thenReturn(const PostDetailsState.error(failure: Failure.unknown()));
        when(() => c.load(any(), any())).thenAnswer((_) async {});
        return c;
      })
      ..registerFactory<DeletePostCubit>(() {
        final c = _MockDeletePostCubit();
        when(() => c.stream).thenAnswer((_) => const Stream.empty());
        when(() => c.state).thenReturn(const DeletePostState.initial());
        return c;
      });
  }

  void registerTiersMocks() {
    getIt
      ..registerFactory<ListTiersCubit>(() {
        final c = _MockListTiersCubit();
        when(() => c.stream).thenAnswer((_) => const Stream.empty());
        when(() => c.state).thenReturn(const ListTiersState.initial());
        when(c.load).thenAnswer((_) async {});
        return c;
      })
      ..registerFactory<TierDetailsCubit>(() {
        final c = _MockTierDetailsCubit();
        when(() => c.stream).thenAnswer((_) => const Stream.empty());
        // Use error state — initial/loading shows CircularProgressIndicator
        // which never settles in pumpAndSettle.
        when(
          () => c.state,
        ).thenReturn(
          const TierDetailsState.error(failure: Failure.unknown()),
        );
        when(() => c.load(any())).thenAnswer((_) async {});
        when(() => c.retry(any())).thenAnswer((_) async {});
        return c;
      })
      ..registerFactory<DeleteTierCubit>(() {
        final c = _MockDeleteTierCubit();
        when(() => c.stream).thenAnswer((_) => const Stream.empty());
        when(() => c.state).thenReturn(const DeleteTierState.initial());
        return c;
      });
  }

  // ---------------------------------------------------------------------------
  // 5b — Tab navigation keeps shell visible
  // ---------------------------------------------------------------------------

  group('tab navigation — shell persists', () {
    testWidgets(
      'navigating to UserDetailsPage within Users tab keeps shell visible',
      (tester) async {
        prepareAuth(const AuthState.unauthenticated());
        registerUsersListMock();
        registerUserDetailsMocks();

        await tester.pumpWidget(
          _buildApp(
            router: router,
            authCubit: authCubit,
            permCubit: permCubit,
            localeCubit: localeCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Shell is visible at root
        expect(find.text('Users'), findsOneWidget);
        expect(find.text('Posts'), findsOneWidget);

        // Navigate to UserDetailsPage within the Users tab
        await router.navigate(UserDetailsRoute(userId: 1));
        await tester.pumpAndSettle();

        // Shell tab bar and AppBar still in widget tree
        expect(find.text('Users'), findsOneWidget);
        expect(find.text('Flutter App'), findsOneWidget);
        // Inner page AppBar title visible
        expect(find.text('alice'), findsOneWidget);
      },
    );

    testWidgets(
      'navigating to PostDetailsPage within Posts tab keeps shell visible',
      (tester) async {
        prepareAuth(const AuthState.unauthenticated());
        registerUsersListMock();
        registerListPostsMock();
        registerPostDetailsMocks();

        await tester.pumpWidget(
          _buildApp(
            router: router,
            authCubit: authCubit,
            permCubit: permCubit,
            localeCubit: localeCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Posts tab
        await tester.tap(find.text('Posts'));
        await tester.pumpAndSettle();

        // Push PostDetailsRoute onto the Posts tab's inner stack directly,
        // avoiding the ambiguity of PostDetailsRoute appearing in both tabs.
        // AutoTabsRouter.of() requires a context that is a descendant of its
        // TabsRouterScope. LocaleSelectorButton (in the shell AppBar actions)
        // satisfies this because it is inside the shell builder but outside the
        // inner-tab body scope.
        final tabsEl = tester.element(find.byType(LocaleSelectorButton));
        final tabsRouter = AutoTabsRouter.of(tabsEl);
        final postsInnerRouter = tabsRouter.innerRouterOf<StackRouter>(
          PostsTabRoute.name,
        );
        // navigate (not push) — push returns a Future that completes on POP,
        // which would block pumpAndSettle indefinitely in tests.
        await postsInnerRouter?.navigate(
          PostDetailsRoute(userId: 1, id: 1),
        );
        await tester.pumpAndSettle();

        // Shell tab bar and AppBar still in widget tree
        expect(find.text('Users'), findsOneWidget);
        expect(find.text('Posts'), findsOneWidget);
        expect(find.text('Flutter App'), findsOneWidget);
      },
    );

    testWidgets(
      'navigating to TierDetailsPage within Tiers tab keeps shell visible',
      (tester) async {
        prepareAuth(
          const AuthState.authenticated(
            currentUser: CurrentUser(
              id: 1,
              username: 'admin',
              email: 'admin@example.com',
              name: 'Admin',
              isSuperuser: true,
              isModerator: false,
            ),
          ),
        );
        registerUsersListMock();
        registerTiersMocks();

        await tester.pumpWidget(
          _buildApp(
            router: router,
            authCubit: authCubit,
            permCubit: permCubit,
            localeCubit: localeCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Tiers tab
        await tester.tap(find.text('Tiers'));
        await tester.pumpAndSettle();

        // Push TierDetailsRoute onto the Tiers tab's inner stack directly.
        // LocaleSelectorButton is in the shell AppBar actions (inside TabsRouterScope
        // but outside the inner-tab body), giving a valid context for of().
        final tabsEl = tester.element(find.byType(LocaleSelectorButton));
        final tabsRouter = AutoTabsRouter.of(tabsEl);
        final tiersInnerRouter = tabsRouter.innerRouterOf<StackRouter>(
          TiersTabRoute.name,
        );
        // navigate (not push) — push returns a Future that completes on POP.
        await tiersInnerRouter?.navigate(
          TierDetailsRoute(tierId: 1, tierName: 'gold'),
        );
        await tester.pumpAndSettle();

        // Shell tab bar and AppBar still in widget tree
        expect(find.text('Tiers'), findsOneWidget);
        expect(find.text('Flutter App'), findsOneWidget);
        // Inner page AppBar title visible
        expect(find.text('gold'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping back arrow within a tab pops inner stack, shell stays visible',
      (tester) async {
        prepareAuth(const AuthState.unauthenticated());
        registerUsersListMock();
        registerUserDetailsMocks();

        await tester.pumpWidget(
          _buildApp(
            router: router,
            authCubit: authCubit,
            permCubit: permCubit,
            localeCubit: localeCubit,
          ),
        );
        await tester.pumpAndSettle();

        // Navigate within the Users tab
        await router.navigate(UserDetailsRoute(userId: 1));
        await tester.pumpAndSettle();

        // One BackButton: child screen's own AppBar (shell has none).
        expect(find.byType(BackButton), findsOneWidget);
        expect(find.text('alice'), findsOneWidget);

        // Tap the back button (child screen's AppBar)
        await tester.tap(find.byType(BackButton).first);
        await tester.pumpAndSettle();

        // Back at Users list — shell still visible
        expect(find.text('Users'), findsOneWidget);
        expect(find.text('Flutter App'), findsOneWidget);
        // User details are gone
        expect(find.text('alice'), findsNothing);
        // No back buttons at root
        expect(find.byType(BackButton), findsNothing);
      },
    );
  });
}
