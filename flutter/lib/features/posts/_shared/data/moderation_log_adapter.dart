import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_action.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_event_type.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_log_entry.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/ports/i_moderation_log_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IModerationLogPort)
class ModerationLogAdapter implements IModerationLogPort {
  ModerationLogAdapter(this._api, this._logger);

  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, List<ModerationLogEntry>>> call(
    String postUuid,
  ) async {
    try {
      try {
        final dto = await _api.getModerationLog(postUuid);
        final entries = dto.items.map((item) {
          return ModerationLogEntry(
            id: item.id,
            eventType: _parseEventType(item.eventType),
            action: _parseAction(item.action),
            message: item.message,
            createdAt: item.createdAt,
            actorUserId: item.actorUserId,
            actorUsername: item.actorUsername,
          );
        }).toList();
        return Right(entries);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'ModerationLogAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
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
    if (statusCode == 403) {
      return const Failure.forbidden(message: 'Forbidden');
    }
    if (statusCode == 404) return const Failure.notFound();
    if (statusCode != null && statusCode >= 500) {
      return Failure.server(statusCode: statusCode);
    }
    return Failure.network(message: e.message);
  }
}
