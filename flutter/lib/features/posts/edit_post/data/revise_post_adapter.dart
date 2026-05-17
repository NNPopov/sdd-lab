import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/edit_post/data/dto/revise_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/ports/i_revise_post_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IRevisePostPort)
class RevisePostAdapter implements IRevisePostPort {
  RevisePostAdapter(this._api, this._logger);

  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, void>> call(UpdatedPostData data) async {
    try {
      try {
        await _api.revisePost(
          data.postUuid,
          RevisePostRequestDto(
            title: data.title,
            text: data.text,
            message: data.revisionMessage!,
          ),
        );
        return const Right(null);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'RevisePostAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    return switch (e.response?.statusCode) {
      403 => const Failure.forbidden(message: 'Forbidden'),
      404 => const Failure.notFound(),
      409 => const Failure.conflict(message: 'Post status has changed'),
      422 => const Failure.validation(fieldErrors: {}),
      _ =>
        e.type == DioExceptionType.connectionError
            ? const Failure.network()
            : Failure.server(statusCode: e.response?.statusCode),
    };
  }
}
