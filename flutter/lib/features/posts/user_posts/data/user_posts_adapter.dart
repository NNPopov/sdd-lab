import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_posts.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/user_posts/domain/ports/user_posts_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: UserPostsPort)
class UserPostsAdapter implements UserPostsPort {
  UserPostsAdapter(this._api, this._logger);

  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, PaginatedPosts>> call({
    required int userId,
    required int page,
    required int perPage,
  }) async {
    try {
      try {
        final dto = await _api.getUserPosts(
          userId,
          page: page,
          perPage: perPage,
        );
        return Right(
          PaginatedPosts(
            items: dto.items
                .map(
                  (p) => Post(
                    id: p.id,
                    title: p.title,
                    text: p.text,
                    createdAt: p.createdAt ?? DateTime(0),
                    createdByUserId: p.createdByUserId,
                    mediaUrl: p.mediaUrl,
                    username: p.username,
                    postUuid: p.postUuid,
                    status: _parseStatus(p.status),
                  ),
                )
                .toList(),
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
        'UserPostsAdapter.call failed unexpectedly',
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

  Failure _mapHttp(DioException e) {
    final failure = e.error;
    if (failure is Failure) return failure;
    final statusCode = e.response?.statusCode;
    if (statusCode == 404) return const Failure.notFound();
    if (statusCode != null && statusCode >= 500) {
      return Failure.server(statusCode: statusCode);
    }
    return Failure.network(message: e.message);
  }
}
