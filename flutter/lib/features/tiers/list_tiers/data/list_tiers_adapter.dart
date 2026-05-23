import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/dto/tier_dto.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/domain/entities/paginated_tiers.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/domain/ports/list_tiers_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ListTiersPort)
class ListTiersAdapter implements ListTiersPort {
  ListTiersAdapter(this._api, this._logger);

  final TiersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, PaginatedTiers>> call({
    required int page,
    required int perPage,
  }) async {
    try {
      try {
        final dto = await _api.getTiers(page: page, perPage: perPage);
        return Right(
          PaginatedTiers(
            tiers: dto.items.map((t) => t.toDomain()).toList(),
            totalCount: dto.totalCount,
            page: dto.page,
            itemsPerPage: dto.itemsPerPage,
          ),
        );
      } on DioException catch (e) {
        final failure = e.error;
        if (failure is Failure) return Left(failure);
        return Left(Failure.network(message: e.message));
      }
    } on Object catch (e, st) {
      _logger.error(
        'ListTiersAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }
}
