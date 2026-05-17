import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/domain/ports/erase_db_post_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: EraseDbPostPort)
class EraseDbPostAdapter implements EraseDbPostPort {
  EraseDbPostAdapter(this._api, this._logger);

  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Unit>> call(String username, int id) async {
    try {
      try {
        await _api.eraseDbPost(username, id);
        return const Right(unit);
      } on DioException catch (e) {
        switch (e.response?.statusCode) {
          case 401:
            return Left(
              Failure.unauthorized(message: _detail(e) ?? 'Unauthorized'),
            );
          case 403:
            return Left(
              Failure.forbidden(message: _detail(e) ?? 'Forbidden'),
            );
          case 404:
            return Left(
              Failure.notFound(message: _detail(e) ?? 'Post not found'),
            );
          default:
            final code = e.response?.statusCode;
            if (code != null && code >= 500) {
              return Left(
                Failure.server(statusCode: code, message: _detail(e)),
              );
            }
            final f = e.error;
            if (f is Failure) return Left(f);
            return Left(Failure.network(message: e.message));
        }
      }
    } on Object catch (e, st) {
      _logger.error(
        'EraseDbPostAdapter.call failed',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  String? _detail(DioException e) =>
      ((e.response?.data as Map<String, dynamic>?)?['detail'])?.toString();
}
