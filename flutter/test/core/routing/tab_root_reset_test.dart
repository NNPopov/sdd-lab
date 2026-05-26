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
import 'package:flutter_application_1/features/posts/post_details/presentation/post_details_route.dart';
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
        // Error state avoids CircularProgressIndicator that blocks pumpAndSettle.
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
        // Error state avoids CircularProgressIndicator that blocks pumpAndSettle.
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

  group('tab root reset on tap', () {
    testWidgets(
      'TC-1: tapping Users tab while deep in Users stack pops to root',
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

        await router.navigate(UserDetailsRoute(userId: 1));
        await tester.pumpAndSettle();

        expect(find.text('alice'), findsOneWidget);

        await tester.tap(find.text('Users'));
        await tester.pumpAndSettle();

        expect(find.text('alice'), findsNothing);
        expect(find.text('Users'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-2: re-tapping the already-active Users tab resets the stack',
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

        await router.navigate(UserDetailsRoute(userId: 1));
        await tester.pumpAndSettle();

        expect(find.text('alice'), findsOneWidget);

        // Users tab is already active (index 0) — tap it again.
        await tester.tap(find.text('Users'));
        await tester.pumpAndSettle();

        expect(find.text('alice'), findsNothing);
        expect(find.text('Users'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-3: tapping Posts tab while deep in Posts stack pops to root',
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

        await tester.tap(find.text('Posts'));
        await tester.pumpAndSettle();

        // LocaleSelectorButton is in the shell AppBar — valid context for of().
        final tabsEl = tester.element(find.byType(LocaleSelectorButton));
        final tabsRouter = AutoTabsRouter.of(tabsEl);
        final postsInnerRouter = tabsRouter.innerRouterOf<StackRouter>(
          PostsTabRoute.name,
        );
        // navigate (not push) — push returns a Future that completes on POP,
        // which would block pumpAndSettle indefinitely in tests.
        await postsInnerRouter?.navigate(
          PostDetailsRoute(username: 'alice', id: 1),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PostDetailsPage), findsOneWidget);

        await tester.tap(find.text('Posts'));
        await tester.pumpAndSettle();

        expect(find.byType(PostDetailsPage), findsNothing);
        // 'Posts' appears in both tab button and ListPostsScreen AppBar.
        expect(find.text('Posts'), findsWidgets);
      },
    );

    testWidgets(
      'TC-4: tapping Tiers tab while deep in Tiers stack pops to root (superuser)',
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

        await tester.tap(find.text('Tiers'));
        await tester.pumpAndSettle();

        final tabsEl = tester.element(find.byType(LocaleSelectorButton));
        final tabsRouter = AutoTabsRouter.of(tabsEl);
        final tiersInnerRouter = tabsRouter.innerRouterOf<StackRouter>(
          TiersTabRoute.name,
        );
        await tiersInnerRouter?.navigate(
          TierDetailsRoute(tierId: 1, tierName: 'gold'),
        );
        await tester.pumpAndSettle();

        expect(find.text('gold'), findsOneWidget);

        await tester.tap(find.text('Tiers'));
        await tester.pumpAndSettle();

        expect(find.text('gold'), findsNothing);
        expect(find.text('Tiers'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-5: cross-tab sequence — Users stack is reset on deliberate Users tap',
      (tester) async {
        prepareAuth(const AuthState.unauthenticated());
        registerUsersListMock();
        registerListPostsMock();
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

        await router.navigate(UserDetailsRoute(userId: 1));
        await tester.pumpAndSettle();

        expect(find.text('alice'), findsOneWidget);

        // Switch away — Users stack is preserved (not reset yet).
        // The loaded details body also renders a "Posts" link, so target the
        // nav tab in the shell AppBar specifically.
        await tester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Posts'),
          ),
        );
        await tester.pumpAndSettle();

        // Switch back — this tap triggers reset on the Users inner stack.
        await tester.tap(find.text('Users'));
        await tester.pumpAndSettle();

        expect(find.text('alice'), findsNothing);
        expect(find.text('Users'), findsOneWidget);
      },
    );
  });
}
