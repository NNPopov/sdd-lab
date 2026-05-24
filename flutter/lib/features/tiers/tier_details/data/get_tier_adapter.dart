import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/tier_details/data/dto/tier_detail_dto.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/entities/tier_detail.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/ports/get_tier_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: GetTierPort)
class GetTierAdapter implements GetTierPort {
  const GetTierAdapter(this._api, this._logger);

  final TiersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, TierDetail>> call(int id) async {
    try {
      try {
        final dto = await _api.getTier(id);
        return Right(dto.toDomain());
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error('GetTierAdapter.call failed', error: e, stackTrace: st);
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    return switch (e.response?.statusCode) {
      401 => Failure.unauthorized(message: e.message ?? ''),
      403 => Failure.forbidden(message: e.message ?? ''),
      404 => const Failure.notFound(),
      _ => Failure.server(statusCode: e.response?.statusCode),
    };
  }
}
