import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_state.dart';
import 'package:flutter_application_1/features/posts/list_posts/presentation/list_posts_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListPostsCubit extends MockCubit<ListPostsState>
    implements ListPostsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

class _FakePageRouteInfo extends Fake implements PageRouteInfo<dynamic> {}

const _aliceUser = CurrentUser(
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
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
    username: 'alice',
    postUuid: 'test-uuid-1',
    status: PostStatus.pendingReview,
  ),
  Post(
    id: 2,
    title: 'Second Post',
    text: 'B' * 50,
    createdAt: DateTime(2024, 2, 20),
    createdByUserId: 42,
    username: 'bob',
    postUuid: 'test-uuid-2',
    status: PostStatus.pendingReview,
  ),
];

Widget _wrap(
  Widget child,
  ListPostsCubit cubit,
  AuthCubit authCubit,
  StackRouter router,
) => TranslationProvider(
  child: StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ListPostsCubit>.value(value: cubit),
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

  late _MockListPostsCubit cubit;
  late _MockAuthCubit authCubit;
  late _MockStackRouter router;

  setUp(() {
    cubit = _MockListPostsCubit();
    authCubit = _MockAuthCubit();
    router = _MockStackRouter();
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => router.push(any())).thenAnswer((_) async => null);
  });

  tearDown(() async {
    await cubit.close();
    await authCubit.close();
  });

  testWidgets(
    'state=loading shows CircularProgressIndicator',
    (tester) async {
      when(() => cubit.state).thenReturn(const ListPostsState.loading());
      when(
        () => authCubit.state,
      ).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(
        _wrap(const ListPostsScreen(), cubit, authCubit, router),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'state=loaded empty list shows empty state text',
    (tester) async {
      when(() => cubit.state).thenReturn(
        const ListPostsState.loaded(posts: [], page: 1, hasMore: false),
      );
      when(
        () => authCubit.state,
      ).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(
        _wrap(const ListPostsScreen(), cubit, authCubit, router),
      );

      expect(find.text('No posts yet'), findsOneWidget);
    },
  );

  testWidgets(
    'state=loaded with post shows author username in tile',
    (tester) async {
      when(() => cubit.state).thenReturn(
        ListPostsState.loaded(
          posts: [_posts.first],
          page: 1,
          hasMore: false,
        ),
      );
      when(
        () => authCubit.state,
      ).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(
        _wrap(const ListPostsScreen(), cubit, authCubit, router),
      );

      expect(find.text('alice'), findsOneWidget);
    },
  );

  testWidgets(
    'state=loaded with loadMoreStatus.loading shows spinner at bottom',
    (tester) async {
      when(() => cubit.state).thenReturn(
        ListPostsState.loaded(
          posts: _posts,
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.loading,
        ),
      );
      when(
        () => authCubit.state,
      ).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(
        _wrap(const ListPostsScreen(), cubit, authCubit, router),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'state=loaded loadMoreStatus.error shows retry, tap calls loadMore',
    (tester) async {
      when(() => cubit.state).thenReturn(
        ListPostsState.loaded(
          posts: _posts,
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.error,
          loadMoreError: const Failure.network(),
        ),
      );
      when(
        () => authCubit.state,
      ).thenReturn(const AuthState.unauthenticated());
      when(() => cubit.loadMore()).thenAnswer((_) async {});

      await tester.pumpWidget(
        _wrap(const ListPostsScreen(), cubit, authCubit, router),
      );
      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(() => cubit.loadMore()).called(1);
    },
  );

  testWidgets(
    'state=error shows error text and retry calls load',
    (tester) async {
      when(() => cubit.state).thenReturn(
        const ListPostsState.error(Failure.network()),
      );
      when(
        () => authCubit.state,
      ).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(
        _wrap(const ListPostsScreen(), cubit, authCubit, router),
      );

      expect(find.text('Failed to load posts'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(() => cubit.load()).called(greaterThanOrEqualTo(1));
    },
  );

  testWidgets('authenticated user sees FAB', (tester) async {
    when(() => cubit.state).thenReturn(
      ListPostsState.loaded(posts: _posts, page: 1, hasMore: false),
    );
    when(() => authCubit.state).thenReturn(
      const AuthState.authenticated(currentUser: _aliceUser),
    );

    await tester.pumpWidget(
      _wrap(const ListPostsScreen(), cubit, authCubit, router),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('unauthenticated user does not see FAB', (tester) async {
    when(() => cubit.state).thenReturn(
      ListPostsState.loaded(posts: _posts, page: 1, hasMore: false),
    );
    when(
      () => authCubit.state,
    ).thenReturn(const AuthState.unauthenticated());

    await tester.pumpWidget(
      _wrap(const ListPostsScreen(), cubit, authCubit, router),
    );

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets(
    'FAB tap with authenticated user navigates to CreatePostRoute',
    (tester) async {
      when(() => cubit.state).thenReturn(
        ListPostsState.loaded(posts: _posts, page: 1, hasMore: false),
      );
      when(() => authCubit.state).thenReturn(
        const AuthState.authenticated(currentUser: _aliceUser),
      );

      await tester.pumpWidget(
        _wrap(const ListPostsScreen(), cubit, authCubit, router),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      final captured = verify(() => router.push(captureAny())).captured;
      final route = captured.first as CreatePostRoute;
      expect(route.args!.username, 'alice');
    },
  );
}
