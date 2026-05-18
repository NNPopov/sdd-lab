import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_cubit.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_state.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_cubit.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_state.dart';
import 'package:flutter_application_1/features/posts/post_details/presentation/post_details_screen.dart';
import 'package:flutter_application_1/features/posts/post_details/presentation/widgets/post_status_chip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostDetailsCubit extends MockCubit<PostDetailsState>
    implements PostDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockDeletePostCubit extends MockCubit<DeletePostState>
    implements DeletePostCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

const _author = CurrentUser(
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

const _nonAuthor = CurrentUser(
  username: 'bob',
  email: 'bob@example.com',
  name: 'Bob',
  isSuperuser: false,
  isModerator: false,
);

Post _fakePost({PostStatus status = PostStatus.pendingReview}) => Post(
  id: 42,
  title: 'Test Post',
  text: 'x' * 100,
  createdAt: DateTime(2024, 1, 15),
  createdByUserId: 1,
  postUuid: 'uuid-001',
  status: status,
  username: 'alice',
);

void main() {
  late _MockPostDetailsCubit mockPostDetailsCubit;
  late _MockAuthCubit mockAuthCubit;
  late _MockDeletePostCubit mockDeletePostCubit;
  late _MockStackRouter mockRouter;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
  });

  setUp(() {
    mockPostDetailsCubit = _MockPostDetailsCubit();
    mockAuthCubit = _MockAuthCubit();
    mockDeletePostCubit = _MockDeletePostCubit();
    mockRouter = _MockStackRouter();

    when(
      () => mockDeletePostCubit.state,
    ).thenReturn(const DeletePostState.initial());
    when(
      () => mockDeletePostCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
    getIt.registerFactory<DeletePostCubit>(() => mockDeletePostCubit);
  });

  tearDown(() async {
    await getIt.unregister<DeletePostCubit>();
  });

  Widget buildSubject({
    required PostDetailsState postState,
    required AuthState authState,
  }) {
    when(() => mockPostDetailsCubit.state).thenReturn(postState);
    when(
      () => mockPostDetailsCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthCubit.state).thenReturn(authState);
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());

    return TranslationProvider(
      child: StackRouterScope(
        stateHash: 0,
        controller: mockRouter,
        child: MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<PostDetailsCubit>.value(value: mockPostDetailsCubit),
              BlocProvider<AuthCubit>.value(value: mockAuthCubit),
            ],
            child: const PostDetailsScreen(username: 'alice', id: 42),
          ),
        ),
      ),
    );
  }

  group('PostDetailsScreen — PostStatusChip visibility', () {
    testWidgets(
      'case 1: author sees Pending Review chip',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            postState: PostDetailsState.loaded(
              post: _fakePost(),
            ),
            authState: const AuthState.authenticated(currentUser: _author),
          ),
        );
        await tester.pump();

        expect(find.text('Pending Review'), findsOneWidget);
        expect(find.byType(PostStatusChip), findsOneWidget);
      },
    );

    testWidgets(
      'case 2: author sees Approved chip',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            postState: PostDetailsState.loaded(
              post: _fakePost(status: PostStatus.approved),
            ),
            authState: const AuthState.authenticated(currentUser: _author),
          ),
        );
        await tester.pump();

        expect(find.text('Approved'), findsOneWidget);
        expect(find.byType(PostStatusChip), findsOneWidget);
      },
    );

    testWidgets(
      'case 3: author sees Changes Requested chip',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            postState: PostDetailsState.loaded(
              post: _fakePost(status: PostStatus.changesRequested),
            ),
            authState: const AuthState.authenticated(currentUser: _author),
          ),
        );
        await tester.pump();

        expect(find.text('Changes Requested'), findsOneWidget);
        expect(find.byType(PostStatusChip), findsOneWidget);
      },
    );

    testWidgets(
      'case 4: non-author does not see status chip',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            postState: PostDetailsState.loaded(post: _fakePost()),
            authState: const AuthState.authenticated(currentUser: _nonAuthor),
          ),
        );
        await tester.pump();

        expect(find.byType(PostStatusChip), findsNothing);
        expect(find.text('Pending Review'), findsNothing);
      },
    );

    testWidgets(
      'case 5: unauthenticated user does not see status chip',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            postState: PostDetailsState.loaded(post: _fakePost()),
            authState: const AuthState.unauthenticated(),
          ),
        );
        await tester.pump();

        expect(find.byType(PostStatusChip), findsNothing);
        expect(find.text('Pending Review'), findsNothing);
      },
    );

    testWidgets(
      'case 6: PostDetailsLoading state — no chip shown',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            postState: const PostDetailsState.loading(),
            authState: const AuthState.authenticated(currentUser: _author),
          ),
        );
        await tester.pump();

        expect(find.byType(PostStatusChip), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'case 7: PostDetailsError state — no chip shown',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(
            postState: const PostDetailsState.error(
              failure: Failure.unknown(),
            ),
            authState: const AuthState.authenticated(currentUser: _author),
          ),
        );
        await tester.pump();

        expect(find.byType(PostStatusChip), findsNothing);
      },
    );
  });
}
