import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_state.dart';
import 'package:flutter_application_1/features/posts/user_posts/presentation/user_posts_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserPostsCubit extends MockCubit<UserPostsState>
    implements UserPostsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

class _FakePageRouteInfo extends Fake implements PageRouteInfo<dynamic> {}

const _username = 'alice';

const _aliceUser = CurrentUser(
  id: 1,
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

const _bobUser = CurrentUser(
  id: 1,
  username: 'bob',
  email: 'bob@example.com',
  name: 'Bob',
  isSuperuser: false,
  isModerator: false,
);

final _posts = [
  Post(
    id: 1,
    title: 'First Post',
    text: 'A' * 50,
    createdAt: DateTime(2024, 1, 15),
    createdByUserId: 42,
    postUuid: 'test-uuid-1',
    status: PostStatus.pendingReview,
  ),
  Post(
    id: 2,
    title: 'Second Post',
    text: 'B' * 50,
    createdAt: DateTime(2024, 2, 20),
    createdByUserId: 42,
    postUuid: 'test-uuid-2',
    status: PostStatus.pendingReview,
  ),
];

Widget _wrapWithRouter(
  Widget child,
  UserPostsCubit cubit,
  StackRouter router,
  AuthCubit authCubit,
) => TranslationProvider(
  child: StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<UserPostsCubit>.value(value: cubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
        ],
        child: child,
      ),
    ),
  ),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePageRouteInfo());
  });

  group('UserPostsScreen navigation', () {
    late _MockUserPostsCubit cubit;
    late _MockStackRouter mockRouter;
    late _MockAuthCubit authCubit;

    setUp(() {
      cubit = _MockUserPostsCubit();
      mockRouter = _MockStackRouter();
      authCubit = _MockAuthCubit();
      when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => cubit.load(any())).thenAnswer((_) async {});
      when(() => mockRouter.push(any())).thenAnswer((_) async => null);
      when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
    });

    tearDown(() async {
      await cubit.close();
      await authCubit.close();
    });

    testWidgets(
      'T-04: tap Open pushes PostDetailsRoute with correct username and id',
      (tester) async {
        when(() => cubit.state).thenReturn(
          UserPostsState.loaded(
            posts: _posts,
            page: 1,
            hasMore: false,
          ),
        );

        await tester.pumpWidget(
          _wrapWithRouter(
            const UserPostsScreen(username: _username),
            cubit,
            mockRouter,
            authCubit,
          ),
        );

        await tester.tap(find.byIcon(Icons.open_in_new).first);
        await tester.pump();

        final captured = verify(() => mockRouter.push(captureAny())).captured;
        final route = captured.first as PostDetailsRoute;
        expect(route.args!.username, _username);
        expect(route.args!.id, _posts.first.id);
      },
    );

    testWidgets(
      'T-05: after returning from PostDetailsRoute refresh is not called',
      (tester) async {
        when(() => cubit.state).thenReturn(
          UserPostsState.loaded(
            posts: _posts,
            page: 1,
            hasMore: false,
          ),
        );

        await tester.pumpWidget(
          _wrapWithRouter(
            const UserPostsScreen(username: _username),
            cubit,
            mockRouter,
            authCubit,
          ),
        );

        await tester.tap(find.byIcon(Icons.open_in_new).first);
        await tester.pumpAndSettle();

        verifyNever(() => cubit.refresh(any()));
      },
    );
  });

  group('UserPostsScreen FAB visibility', () {
    late _MockUserPostsCubit cubit;
    late _MockStackRouter mockRouter;
    late _MockAuthCubit authCubit;

    setUp(() {
      cubit = _MockUserPostsCubit();
      mockRouter = _MockStackRouter();
      authCubit = _MockAuthCubit();
      when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => cubit.load(any())).thenAnswer((_) async {});
      when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => cubit.state).thenReturn(
        UserPostsState.loaded(posts: _posts, page: 1, hasMore: false),
      );
    });

    tearDown(() async {
      await cubit.close();
      await authCubit.close();
    });

    testWidgets(
      'T-FAB-1: FAB is visible when authenticated user is the owner',
      (tester) async {
        when(() => authCubit.state).thenReturn(
          const AuthState.authenticated(currentUser: _aliceUser),
        );

        await tester.pumpWidget(
          _wrapWithRouter(
            const UserPostsScreen(username: _username),
            cubit,
            mockRouter,
            authCubit,
          ),
        );

        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets(
      'T-FAB-2: FAB is hidden when authenticated user is not the owner',
      (tester) async {
        when(() => authCubit.state).thenReturn(
          const AuthState.authenticated(currentUser: _bobUser),
        );

        await tester.pumpWidget(
          _wrapWithRouter(
            const UserPostsScreen(username: _username),
            cubit,
            mockRouter,
            authCubit,
          ),
        );

        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );
  });
}
