import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/dto/tier_option_dto.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/entities/tier_option.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/ports/fetch_tiers_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: FetchTiersPort)
class FetchTiersAdapter implements FetchTiersPort {
  FetchTiersAdapter(this._api, this._logger);

  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, List<TierOption>>> call() async {
    try {
      try {
        final dto = await _api.getTiersForSelection();
        return Right(dto.data.map((d) => d.toDomain()).toList());
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'FetchTiersAdapter.call failed',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    return switch (e.response?.statusCode) {
      401 => const Failure.unauthorized(message: 'Session expired'),
      _ => Failure.server(statusCode: e.response?.statusCode),
    };
  }
}
