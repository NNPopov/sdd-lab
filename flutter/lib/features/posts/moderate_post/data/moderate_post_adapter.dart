import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/moderate_post/data/dto/moderate_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/moderate_post/domain/ports/i_moderate_post_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IModeratePostPort)
class ModeratePostAdapter implements IModeratePostPort {
  ModeratePostAdapter(this._api, this._logger);

  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, PostStatus>> call({
    required String postUuid,
    required String action,
    String? message,
  }) async {
    try {
      try {
        final dto = await _api.moderatePost(
          postUuid,
          ModeratePostRequestDto(action: action, message: message),
        );
        return Right(_parseStatus(dto.status));
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'ModeratePostAdapter.call failed unexpectedly',
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
      _ => PostStatus.pendingReview,
    };
  }

  Failure _mapHttp(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 403) {
      return const Failure.forbidden(message: 'Forbidden');
    }
    if (statusCode == 404) return const Failure.notFound();
    if (statusCode == 409) {
      return const Failure.conflict(message: 'Post already moderated');
    }
    if (statusCode != null && statusCode >= 500) {
      return Failure.server(statusCode: statusCode);
    }
    return Failure.network(message: e.message);
  }
}
