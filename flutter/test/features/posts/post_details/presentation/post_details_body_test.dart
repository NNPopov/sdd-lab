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
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_cubit.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_state.dart';
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

class _MockEraseDbPostCubit extends MockCubit<EraseDbPostState>
    implements EraseDbPostCubit {}

final _post = Post(
  id: 1,
  title: 'My Post',
  text: 'Body content',
  createdAt: DateTime(2024),
  createdByUserId: 1,
  postUuid: 'uuid-1',
  status: PostStatus.approved,
  username: 'alice',
);

const _alice = CurrentUser(
  id: 1,
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

const _bob = CurrentUser(
  id: 1,
  username: 'bob',
  email: 'bob@example.com',
  name: 'Bob',
  isSuperuser: false,
  isModerator: false,
);

Widget _wrap({
  required PostDetailsCubit postCubit,
  required AuthCubit authCubit,
}) {
  return TranslationProvider(
    child: MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<PostDetailsCubit>.value(value: postCubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
        ],
        child: const PostDetailsScreen(username: 'alice', id: 1),
      ),
    ),
  );
}

void main() {
  late _MockPostDetailsCubit postCubit;
  late _MockAuthCubit authCubit;
  late _MockDeletePostCubit deletePostCubit;
  late _MockEraseDbPostCubit eraseDbPostCubit;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
  });

  setUp(() {
    postCubit = _MockPostDetailsCubit();
    authCubit = _MockAuthCubit();
    deletePostCubit = _MockDeletePostCubit();
    eraseDbPostCubit = _MockEraseDbPostCubit();

    when(() => postCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => deletePostCubit.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => eraseDbPostCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => deletePostCubit.state,
    ).thenReturn(const DeletePostState.initial());
    when(
      () => eraseDbPostCubit.state,
    ).thenReturn(const EraseDbPostState.initial());
    when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());

    getIt
      ..registerFactory<DeletePostCubit>(() => deletePostCubit)
      ..registerFactory<EraseDbPostCubit>(() => eraseDbPostCubit);
  });

  tearDown(() async {
    await postCubit.close();
    await authCubit.close();
    await deletePostCubit.close();
    await eraseDbPostCubit.close();
    await getIt.reset();
  });

  testWidgets('PostDetailsLoading → CircularProgressIndicator present', (
    tester,
  ) async {
    when(
      () => postCubit.state,
    ).thenReturn(const PostDetailsState.loading());

    await tester.pumpWidget(_wrap(postCubit: postCubit, authCubit: authCubit));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('PostDetailsError → retry button present', (tester) async {
    when(() => postCubit.state).thenReturn(
      const PostDetailsState.error(failure: NetworkFailure()),
    );

    await tester.pumpWidget(_wrap(postCubit: postCubit, authCubit: authCubit));
    await tester.pump();

    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('PostDetailsLoaded + author → PostStatusChip present', (
    tester,
  ) async {
    when(
      () => postCubit.state,
    ).thenReturn(PostDetailsState.loaded(post: _post));
    when(() => authCubit.state).thenReturn(
      const AuthState.authenticated(currentUser: _alice),
    );

    await tester.pumpWidget(_wrap(postCubit: postCubit, authCubit: authCubit));
    await tester.pump();

    expect(find.byType(PostStatusChip), findsOneWidget);
  });

  testWidgets('PostDetailsLoaded + not author → PostStatusChip absent', (
    tester,
  ) async {
    when(
      () => postCubit.state,
    ).thenReturn(PostDetailsState.loaded(post: _post));
    when(() => authCubit.state).thenReturn(
      const AuthState.authenticated(currentUser: _bob),
    );

    await tester.pumpWidget(_wrap(postCubit: postCubit, authCubit: authCubit));
    await tester.pump();

    expect(find.byType(PostStatusChip), findsNothing);
  });
}
