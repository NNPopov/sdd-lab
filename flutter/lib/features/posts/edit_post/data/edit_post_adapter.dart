import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/update_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/ports/edit_post_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: EditPostPort)
class EditPostAdapter implements EditPostPort {
  EditPostAdapter(this._api, this._logger);

  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, void>> call(UpdatedPostData data) async {
    try {
      try {
        await _api.patchPost(
          data.userId,
          data.id,
          UpdatePostRequestDto(
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
        'EditPostAdapter.call failed unexpectedly',
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
      422 => const MessageValidationFailure(message: 'Validation error'),
      _ =>
        e.type == DioExceptionType.connectionError
            ? const Failure.network()
            : Failure.server(statusCode: e.response?.statusCode),
    };
  }
}
