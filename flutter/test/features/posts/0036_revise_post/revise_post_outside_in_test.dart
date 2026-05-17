import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/update_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_cubit.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_state.dart';
import 'package:flutter_application_1/features/posts/edit_post/data/dto/revise_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/edit_post/data/edit_post_adapter.dart';
import 'package:flutter_application_1/features/posts/edit_post/data/revise_post_adapter.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/usecases/edit_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockAuthCubit extends Mock implements AuthCubit {}

const _currentUser = CurrentUser(
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

const _postUuid = 'post-uuid-001';

DioException _dioError(int statusCode) => DioException(
  requestOptions: RequestOptions(),
  response: Response(
    requestOptions: RequestOptions(),
    statusCode: statusCode,
    data: <String, dynamic>{},
  ),
);

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late _MockAuthCubit authCubit;
  late RevisePostAdapter reviseAdapter;
  late EditPostAdapter editAdapter;
  late EditPostUseCase useCase;
  late EditPostCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      const RevisePostRequestDto(title: null, text: null, message: ''),
    );
    registerFallbackValue(
      const UpdatePostRequestDto(title: '', text: ''),
    );
    registerFallbackValue(
      const UpdatedPostData(
        username: 'alice',
        id: 1,
        postUuid: _postUuid,
        status: PostStatus.changesRequested,
        title: 'T',
        text: 'T',
        revisionMessage: null,
      ),
    );
  });

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();
    authCubit = _MockAuthCubit();

    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);

    when(() => authCubit.currentUser).thenReturn(_currentUser);

    reviseAdapter = RevisePostAdapter(api, logger);
    editAdapter = EditPostAdapter(api, logger);
    useCase = EditPostUseCase(editAdapter, reviseAdapter, authCubit);
    cubit = EditPostCubit(useCase);
  });

  tearDown(() async {
    await cubit.close();
  });

  test(
    'successful revision of a changesRequested post — emits [loading, success]',
    () async {
      when(
        () => api.revisePost(any(), any()),
      ).thenAnswer((_) async {});

      final stateExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const EditPostState.loading(),
          const EditPostState.success(),
        ]),
      );

      await cubit.submit(
        const UpdatedPostData(
          username: 'alice',
          id: 1,
          postUuid: _postUuid,
          status: PostStatus.changesRequested,
          title: 'Revised Title',
          text: 'Revised body text with enough content to pass validation.',
          revisionMessage:
              'Addressed the moderator feedback on paragraph structure.',
        ),
      );

      await stateExpectation;

      verify(
        () => api.revisePost(
          _postUuid,
          any(
            that: isA<RevisePostRequestDto>().having(
              (dto) => dto.message,
              'message',
              'Addressed the moderator feedback on paragraph structure.',
            ),
          ),
        ),
      ).called(1);
    },
  );

  test(
    'revision rejected with 409 — emits [loading, error(ConflictFailure)]',
    () async {
      when(
        () => api.revisePost(any(), any()),
      ).thenThrow(_dioError(409));

      final stateExpectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const EditPostState.loading(),
          isA<EditPostError>().having(
            (s) => s.failure,
            'failure',
            isA<ConflictFailure>(),
          ),
        ]),
      );

      await cubit.submit(
        const UpdatedPostData(
          username: 'alice',
          id: 1,
          postUuid: _postUuid,
          status: PostStatus.changesRequested,
          title: 'Revised Title',
          text: 'Revised body text with enough content to pass validation.',
          revisionMessage:
              'Addressed the moderator feedback on paragraph structure.',
        ),
      );

      await stateExpectation;

      // The revise adapter was called; the regular edit endpoint was not.
      verifyNever(() => api.patchPost(any(), any(), any()));
    },
  );
}
