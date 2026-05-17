import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_cubit.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_state.dart';
import 'package:flutter_application_1/features/posts/post_details/data/get_post_adapter.dart';
import 'package:flutter_application_1/features/posts/post_details/domain/usecases/get_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late GetPostAdapter adapter;
  late GetPostUseCase useCase;
  late PostDetailsCubit cubit;

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();

    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);
    when(() => logger.warning(any())).thenReturn(null);

    adapter = GetPostAdapter(api, logger);
    useCase = GetPostUseCase(adapter);
    cubit = PostDetailsCubit(useCase);
  });

  tearDown(() => cubit.close());

  test(
    'load — known status "approved" — Post.status is approved and postUuid round-trips',
    () async {
      when(() => api.getPost('alice', 42)).thenAnswer(
        (_) async => PostDto(
          id: 42,
          title: 'Hello',
          text: 'World',
          createdAt: DateTime(2026),
          createdByUserId: 7,
          postUuid: 'post-uuid-abc',
          status: 'approved',
        ),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PostDetailsState.loading(),
          isA<PostDetailsLoaded>()
              .having(
                (s) => s.post.postUuid,
                'post.postUuid',
                'post-uuid-abc',
              )
              .having(
                (s) => s.post.status,
                'post.status',
                PostStatus.approved,
              ),
        ]),
      );

      await cubit.load('alice', 42);
      await expectation;

      verifyNever(() => logger.warning(any()));
      verifyNever(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      );
    },
  );

  test(
    'load — unknown status "archived" — Post.status falls back to pendingReview, warning logged',
    () async {
      when(() => api.getPost('alice', 42)).thenAnswer(
        (_) async => PostDto(
          id: 42,
          title: 'Hello',
          text: 'World',
          createdAt: DateTime(2026),
          createdByUserId: 7,
          postUuid: 'post-uuid-xyz',
          status: 'archived',
        ),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PostDetailsState.loading(),
          isA<PostDetailsLoaded>()
              .having(
                (s) => s.post.status,
                'post.status',
                PostStatus.pendingReview,
              )
              .having(
                (s) => s.post.postUuid,
                'post.postUuid',
                'post-uuid-xyz',
              ),
        ]),
      );

      await cubit.load('alice', 42);
      await expectation;

      verify(() => logger.warning(any())).called(1);
      verifyNever(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      );
    },
  );
}
