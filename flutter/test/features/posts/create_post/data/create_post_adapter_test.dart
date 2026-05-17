import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/create_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/create_post/data/create_post_adapter.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/entities/new_post_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late CreatePostAdapter adapter;

  const data = NewPostData(
    username: 'alice',
    title: 'My Post',
    text: 'body text',
  );

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();
    adapter = CreatePostAdapter(api, logger);
    registerFallbackValue(
      const CreatePostRequestDto(title: '', text: ''),
    );
    registerFallbackValue(StackTrace.empty);
  });

  void mockApiSuccess() {
    when(() => api.createPost(any(), any())).thenAnswer(
      (_) async => const PostDto(
        id: 1,
        postUuid: '',
        status: 'pending_review',
      ),
    );
  }

  void mockApiThrows(Object error) {
    when(() => api.createPost(any(), any())).thenThrow(error);
  }

  DioException dioException(int statusCode) => DioException(
    requestOptions: RequestOptions(),
    response: Response(
      requestOptions: RequestOptions(),
      statusCode: statusCode,
    ),
    type: DioExceptionType.badResponse,
  );

  group('call', () {
    test('success → Right(null)', () async {
      mockApiSuccess();

      final result = await adapter(data);

      expect(result, const Right<Failure, void>(null));
    });

    test('DioException 401 → Left(UnauthorizedFailure)', () async {
      mockApiThrows(dioException(401));

      final result = await adapter(data);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
    });

    test('DioException 403 → Left(ForbiddenFailure)', () async {
      mockApiThrows(dioException(403));

      final result = await adapter(data);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ForbiddenFailure>());
    });

    test('DioException 422 → Left(ValidationFailure)', () async {
      mockApiThrows(dioException(422));

      final result = await adapter(data);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });

    test('DioException connection error → Left(NetworkFailure)', () async {
      mockApiThrows(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await adapter(data);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    });

    test(
      'unexpected Exception → Left(UnknownFailure) and logs error',
      () async {
        final exception = Exception('unexpected');
        mockApiThrows(exception);

        when(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).thenReturn(null);

        final result = await adapter(data);

        expect(result, const Left<Failure, void>(Failure.unknown()));
        verify(
          () => logger.error(
            any(),
            error: exception,
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      },
    );
  });
}
