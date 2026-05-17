import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/post_details/domain/ports/post_details_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PostDetailsPort)
class GetPostAdapter implements PostDetailsPort {
  GetPostAdapter(this._api, this._logger);
  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Post>> call(String username, int id) async {
    try {
      try {
        final dto = await _api.getPost(username, id);
        return Right(
          Post(
            id: dto.id,
            title: dto.title,
            text: dto.text,
            createdAt: dto.createdAt ?? DateTime(0),
            createdByUserId: dto.createdByUserId ?? 0,
            mediaUrl: dto.mediaUrl,
            postUuid: dto.postUuid,
            status: _parseStatus(dto.status),
          ),
        );
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error('GetPostAdapter.call failed', error: e, stackTrace: st);
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

  Failure _mapHttp(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 404) return const Failure.notFound();
    if (statusCode != null && statusCode >= 500) {
      return Failure.server(statusCode: statusCode);
    }
    return Failure.network(message: e.message);
  }
}
