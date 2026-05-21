import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_cubit.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_state.dart';
import 'package:flutter_application_1/features/posts/moderate_post/data/dto/moderate_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/moderate_post/data/dto/moderate_post_result_dto.dart';
import 'package:flutter_application_1/features/posts/moderate_post/data/moderate_post_adapter.dart';
import 'package:flutter_application_1/features/posts/moderate_post/domain/usecases/moderate_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late PostEventBus eventBus;
  late ModeratePostAdapter adapter;
  late ModeratePostUseCase useCase;
  late ModeratePostCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      ModeratePostRequestDto(action: 'approved', message: null),
    );
  });

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();
    eventBus = PostEventBus();

    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);

    adapter = ModeratePostAdapter(api, logger);
    useCase = ModeratePostUseCase(adapter);
    cubit = ModeratePostCubit(useCase, eventBus);
  });

  tearDown(() async {
    await cubit.close();
    await eventBus.dispose();
  });

  test(
    'moderate approved — emits [loading, success(approved)] and publishes PostModeratedEvent',
    () async {
      when(
        () => api.moderatePost(any(), any()),
      ).thenAnswer(
        (_) async => ModeratePostResultDto(
          postUuid: 'post-uuid-abc-123',
          status: 'approved',
        ),
      );

      // expectLater must be set up BEFORE the action to avoid stream timing issues.
      final eventExpectation = expectLater(
        eventBus.stream,
        emits(
          isA<PostModeratedEvent>().having(
            (e) => e.postUuid,
            'postUuid',
            'post-uuid-abc-123',
          ),
        ),
      );

      final stateExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ModeratePostState.loading(),
          isA<ModeratePostSuccess>().having(
            (s) => s.newStatus,
            'newStatus',
            PostStatus.approved,
          ),
        ]),
      );

      await cubit.moderate(
        postUuid: 'post-uuid-abc-123',
        action: 'approved',
        message: null,
      );

      await stateExpectation;
      await eventExpectation;

      verify(() => api.moderatePost(any(), any())).called(1);
    },
  );

  test(
    'moderate changes_requested with empty message — emits [loading, error(ValidationFailure)], Dio not called',
    () async {
      final publishedEvents = <PostEvent>[];
      final sub = eventBus.stream.listen(publishedEvents.add);

      final stateExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ModeratePostState.loading(),
          isA<ModeratePostError>().having(
            (s) => s.failure,
            'failure',
            isA<FieldValidationFailure>(),
          ),
        ]),
      );

      await cubit.moderate(
        postUuid: 'post-uuid-abc-123',
        action: 'changes_requested',
        message: '',
      );

      await stateExpectation;
      await sub.cancel();

      expect(publishedEvents, isEmpty);
      verifyNever(() => api.moderatePost(any(), any()));
    },
  );
}
