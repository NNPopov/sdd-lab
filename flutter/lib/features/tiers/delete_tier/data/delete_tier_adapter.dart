import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/domain/ports/delete_tier_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DeleteTierPort)
class DeleteTierAdapter implements DeleteTierPort {
  DeleteTierAdapter(this._api, this._logger);

  final TiersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Unit>> call(String name) async {
    try {
      try {
        await _api.deleteTier(name);
        return const Right(unit);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'DeleteTierAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) => switch (e.response?.statusCode) {
    401 => Failure.unauthorized(message: e.message ?? ''),
    403 => Failure.forbidden(message: e.message ?? ''),
    404 => const Failure.notFound(),
    _ => Failure.server(
      statusCode: e.response?.statusCode,
      message: e.message,
    ),
  };
}
