import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_action.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_event_type.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_log_entry.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_result.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/pending_posts/domain/ports/pending_posts_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PendingPostsPort)
class PendingPostsAdapter implements PendingPostsPort {
  PendingPostsAdapter(this._api, this._logger);

  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, PaginatedResult<PendingPostItem>>> call({
    required int page,
    required int perPage,
  }) async {
    try {
      try {
        final dto = await _api.getPendingPosts(page: page, perPage: perPage);
        final items = dto.items.map((itemDto) {
          final log = itemDto.moderationLog.map((logDto) {
            return ModerationLogEntry(
              id: logDto.id,
              eventType: _parseEventType(logDto.eventType),
              action: _parseAction(logDto.action),
              message: logDto.message,
              createdAt: logDto.createdAt,
              actorUserId: logDto.actorUserId,
              actorUsername: logDto.actorUsername,
            );
          }).toList();

          return PendingPostItem(
            postUuid: itemDto.postUuid,
            title: itemDto.title,
            text: itemDto.text,
            status: _parseStatus(itemDto.status),
            createdAt: itemDto.createdAt,
            updatedAt: itemDto.updatedAt,
            authorUsername: itemDto.authorUsername,
            moderationLog: log,
            mediaUrl: itemDto.mediaUrl,
          );
        }).toList();

        return Right(
          PaginatedResult<PendingPostItem>(
            items: items,
            totalCount: dto.totalCount,
            page: dto.page,
            itemsPerPage: dto.itemsPerPage,
          ),
        );
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'PendingPostsAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  PostStatus _parseStatus(String raw) {
    return switch (raw) {
      'approved' => PostStatus.approved,
      'changes_requested' => PostStatus.changesRequested,
      _ => () {
        if (raw != 'pending_review') {
          _logger.warning(
            'Unknown post status: $raw, falling back to pendingReview',
          );
        }
        return PostStatus.pendingReview;
      }(),
    };
  }

  ModerationEventType _parseEventType(String raw) {
    return switch (raw) {
      'moderator_review' => ModerationEventType.moderatorReview,
      'author_revision' => ModerationEventType.authorRevision,
      _ => () {
        _logger.warning(
          'Unknown moderation event type: $raw, '
          'falling back to moderatorReview',
        );
        return ModerationEventType.moderatorReview;
      }(),
    };
  }

  ModerationAction? _parseAction(String? raw) {
    if (raw == null) return null;
    return switch (raw) {
      'approved' => ModerationAction.approved,
      'changes_requested' => ModerationAction.changesRequested,
      _ => () {
        _logger.warning('Unknown moderation action: $raw, returning null');
        return null;
      }(),
    };
  }

  Failure _mapHttp(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return Failure.unauthorized(message: e.message ?? '');
    }
    if (statusCode == 403) return const Failure.permissionDenied();
    if (statusCode == 404) return const Failure.notFound();
    if (statusCode != null && statusCode >= 500) {
      return Failure.server(statusCode: statusCode);
    }
    return Failure.network(message: e.message);
  }
}
