import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/moderation_log_entry_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_action.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_event_type.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/moderation_log_response_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/moderation_log_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late ModerationLogAdapter adapter;

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
    when(
      () => logger.warning(any()),
    ).thenReturn(null);
    adapter = ModerationLogAdapter(api, logger);
  });

  DioException dioError(int statusCode) => DioException(
    requestOptions: RequestOptions(),
    response: Response(
      requestOptions: RequestOptions(),
      statusCode: statusCode,
    ),
  );

  final now = DateTime(2024, 1, 15, 10, 30);

  test(
    '200 with 2 entries → Right([entry, entry]) all fields mapped',
    () async {
      when(() => api.getModerationLog(any())).thenAnswer(
        (_) async => ModerationLogResponseDto(
          items: [
            ModerationLogEntryDto(
              id: 1,
              eventType: 'moderator_review',
              action: 'approved',
              message: 'looks good',
              createdAt: now,
              actorUserId: 42,
              actorUsername: 'moderator1',
            ),
            ModerationLogEntryDto(
              id: 2,
              eventType: 'author_revision',
              createdAt: now,
              actorUserId: 7,
              actorUsername: 'author1',
            ),
          ],
        ),
      );
      final result = await adapter('uuid-1');
      expect(result.isRight(), isTrue);
      final entries = result.getOrElse(() => []);
      expect(entries, hasLength(2));

      final e1 = entries[0];
      expect(e1.id, equals(1));
      expect(e1.eventType, equals(ModerationEventType.moderatorReview));
      expect(e1.action, equals(ModerationAction.approved));
      expect(e1.message, equals('looks good'));
      expect(e1.actorUserId, equals(42));
      expect(e1.actorUsername, equals('moderator1'));

      final e2 = entries[1];
      expect(e2.eventType, equals(ModerationEventType.authorRevision));
      expect(e2.action, isNull);
      expect(e2.message, isNull);
    },
  );

  test('200 with empty list → Right([])', () async {
    when(() => api.getModerationLog(any())).thenAnswer(
      (_) async => const ModerationLogResponseDto(items: []),
    );
    final result = await adapter('uuid-1');
    expect(result.isRight(), isTrue);
    final entries = result.getOrElse(() => throw Exception('was Left'));
    expect(entries, isEmpty);
  });

  test('401 → Left(UnauthorizedFailure)', () async {
    when(() => api.getModerationLog(any())).thenThrow(dioError(401));
    final result = await adapter('uuid-1');
    expect(result.isLeft(), isTrue);
    expect(result.fold(id, id), isA<UnauthorizedFailure>());
  });

  test('403 → Left(ForbiddenFailure)', () async {
    when(() => api.getModerationLog(any())).thenThrow(dioError(403));
    final result = await adapter('uuid-1');
    expect(result.isLeft(), isTrue);
    expect(result.fold(id, id), isA<ForbiddenFailure>());
  });

  test('404 → Left(NotFoundFailure)', () async {
    when(() => api.getModerationLog(any())).thenThrow(dioError(404));
    final result = await adapter('uuid-1');
    expect(result.isLeft(), isTrue);
    expect(result.fold(id, id), isA<NotFoundFailure>());
  });

  test(
    'unexpected exception → Left(UnknownFailure), logger.error called',
    () async {
      when(() => api.getModerationLog(any())).thenThrow(Exception('oops'));
      final result = await adapter('uuid-1');
      expect(result.isLeft(), isTrue);
      expect(result.fold(id, id), isA<UnknownFailure>());
      verify(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).called(1);
    },
  );
}
