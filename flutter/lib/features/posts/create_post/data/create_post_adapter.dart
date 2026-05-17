import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/create_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/entities/new_post_data.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/ports/create_post_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CreatePostPort)
class CreatePostAdapter implements CreatePostPort {
  CreatePostAdapter(this._api, this._logger);

  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, void>> call(NewPostData data) async {
    try {
      try {
        await _api.createPost(
          data.username,
          CreatePostRequestDto(
            title: data.title,
            text: data.text,
            mediaUrl: data.mediaUrl,
          ),
        );
        return const Right(null);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'CreatePostAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    return switch (e.response?.statusCode) {
      401 => const Failure.unauthorized(message: 'Unauthorized'),
      403 => const Failure.forbidden(message: 'Forbidden'),
      422 => const Failure.validation(fieldErrors: {}),
      _ =>
        e.type == DioExceptionType.connectionError
            ? const Failure.network()
            : Failure.server(statusCode: e.response?.statusCode),
    };
  }
}
