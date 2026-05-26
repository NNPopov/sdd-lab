import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_cubit.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_state.dart';
import 'package:flutter_application_1/features/posts/delete_post/data/delete_post_adapter.dart';
import 'package:flutter_application_1/features/posts/delete_post/domain/usecases/delete_post_usecase.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_cubit.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_state.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/data/erase_db_post_adapter.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/domain/usecases/erase_db_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockAuthCubit extends Mock implements AuthCubit {}

class _MockPostEventBus extends Mock implements PostEventBus {}

// The post selected by the delete/erase actions; its author has id 42.
const _authorId = 42;
const _postId = 7;

CurrentUser _user(int id, {bool isSuperuser = false}) => CurrentUser(
  id: id,
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: isSuperuser,
  isModerator: false,
);

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late _MockAuthCubit authCubit;
  late _MockPostEventBus eventBus;

  late DeletePostCubit deletePostCubit;
  late EraseDbPostCubit eraseDbPostCubit;

  setUpAll(() {
    registerFallbackValue(PostDeleted(0));
  });

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();
    authCubit = _MockAuthCubit();
    eventBus = _MockPostEventBus();

    // Wire the delete vertical real: adapter → use-case → cubit.
    deletePostCubit = DeletePostCubit(
      DeletePostUseCase(DeletePostAdapter(api, logger), authCubit),
      eventBus,
    );

    // Wire the erase vertical real: adapter → use-case → cubit.
    eraseDbPostCubit = EraseDbPostCubit(
      EraseDbPostUseCase(EraseDbPostAdapter(api, logger)),
      authCubit,
      eventBus,
    );
  });

  tearDown(() {
    deletePostCubit.close();
    eraseDbPostCubit.close();
  });

  test(
    'the author deleting a post calls deletePost with the integer user id',
    () async {
      when(() => authCubit.currentUser).thenReturn(_user(_authorId));
      when(() => api.deletePost(_authorId, _postId)).thenAnswer((_) async {});

      final expectation = expectLater(
        deletePostCubit.stream,
        emitsInOrder([isA<DeletePostDeleting>(), isA<DeletePostSuccess>()]),
      );

      await deletePostCubit.confirmAndDelete(_authorId, _postId);
      await expectation;

      verify(() => api.deletePost(_authorId, _postId)).called(1);
      final published = verify(
        () => eventBus.publish(captureAny()),
      ).captured.single;
      expect(published, isA<PostDeleted>());
      expect((published as PostDeleted).id, _postId);
    },
  );

  test('a non-author is forbidden by id and no delete is sent', () async {
    when(() => authCubit.currentUser).thenReturn(_user(99));

    final expectation = expectLater(
      deletePostCubit.stream,
      emitsInOrder([isA<DeletePostDeleting>(), isA<DeletePostFailure>()]),
    );

    await deletePostCubit.confirmAndDelete(_authorId, _postId);
    await expectation;

    final failure = (deletePostCubit.state as DeletePostFailure).failure;
    expect(failure, isA<ForbiddenFailure>());
    verifyNever(() => api.deletePost(any(), any()));
    verifyNever(() => eventBus.publish(any()));
  });

  test(
    'a superuser erasing a post calls eraseDbPost with the integer user id',
    () async {
      when(
        () => authCubit.currentUser,
      ).thenReturn(_user(99, isSuperuser: true));
      when(() => api.eraseDbPost(_authorId, _postId)).thenAnswer((_) async {});

      final expectation = expectLater(
        eraseDbPostCubit.stream,
        emitsInOrder([isA<EraseDbPostDeleting>(), isA<EraseDbPostSuccess>()]),
      );

      await eraseDbPostCubit.confirmAndErase(_authorId, _postId);
      await expectation;

      verify(() => api.eraseDbPost(_authorId, _postId)).called(1);
      final published = verify(
        () => eventBus.publish(captureAny()),
      ).captured.single;
      expect(published, isA<PostDeleted>());
      expect((published as PostDeleted).id, _postId);
    },
  );

  test('a non-superuser is permission-denied and no erase is sent', () async {
    when(() => authCubit.currentUser).thenReturn(_user(99));

    final expectation = expectLater(
      eraseDbPostCubit.stream,
      emitsInOrder([isA<EraseDbPostDeleting>(), isA<EraseDbPostFailure>()]),
    );

    await eraseDbPostCubit.confirmAndErase(_authorId, _postId);
    await expectation;

    final failure = (eraseDbPostCubit.state as EraseDbPostFailure).failure;
    expect(failure, isA<PermissionDenied>());
    verifyNever(() => api.eraseDbPost(any(), any()));
    verifyNever(() => eventBus.publish(any()));
  });
}
