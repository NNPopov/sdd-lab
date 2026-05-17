import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/data/dto/edit_tier_request_dto.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/entities/edit_tier_data.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/ports/edit_tier_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: EditTierPort)
class EditTierAdapter implements EditTierPort {
  EditTierAdapter(this._api, this._logger);

  final TiersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Unit>> call(EditTierData data) async {
    try {
      try {
        await _api.patchTier(
          data.tierCurrentName,
          EditTierRequestDto(name: data.newName),
        );
        return const Right(unit);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'EditTierAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    final statusCode = e.response?.statusCode;

    if (statusCode == 403) {
      final detail = (e.response?.data as Map<String, dynamic>?)?['detail'];
      return Failure.forbidden(message: detail?.toString() ?? 'Forbidden');
    }

    if (statusCode == 404) {
      return const Failure.notFound();
    }

    if (statusCode != null && statusCode >= 500) {
      return Failure.server(statusCode: statusCode, message: e.message);
    }

    final failure = e.error;
    if (failure is Failure) return failure;
    return Failure.network(message: e.message);
  }
}
