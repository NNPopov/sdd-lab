import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/dto/create_tier_request_dto.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/dto/tier_dto.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/_shared/domain/entities/tier.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/entities/new_tier_data.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/ports/create_tier_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CreateTierPort)
class CreateTierAdapter implements CreateTierPort {
  CreateTierAdapter(this._api, this._logger);

  final TiersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Tier>> call(NewTierData data) async {
    try {
      try {
        final dto = await _api.createTier(
          CreateTierRequestDto(name: data.name),
        );
        return Right(dto.toDomain());
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'CreateTierAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    final statusCode = e.response?.statusCode;

    if (statusCode == 401) {
      final detail = (e.response?.data as Map<String, dynamic>?)?['detail'];
      return Failure.unauthorized(
        message: detail?.toString() ?? 'Unauthorized',
      );
    }

    if (statusCode == 403) {
      final detail = (e.response?.data as Map<String, dynamic>?)?['detail'];
      return Failure.forbidden(message: detail?.toString() ?? 'Forbidden');
    }

    if (statusCode == 409) {
      final detail = (e.response?.data as Map<String, dynamic>?)?['detail'];
      return Failure.conflict(message: detail?.toString() ?? 'Conflict');
    }

    if (statusCode == 422) {
      return _parseValidation(e);
    }

    if (statusCode != null && statusCode >= 500) {
      return Failure.server(statusCode: statusCode, message: e.message);
    }

    final failure = e.error;
    if (failure is Failure) return failure;
    return Failure.network(message: e.message);
  }

  Failure _parseValidation(DioException e) {
    final rawDetail = (e.response?.data as Map<String, dynamic>?)?['detail'];
    if (rawDetail is List) {
      final fieldErrors = <String, String>{};
      for (final item in rawDetail) {
        if (item is Map<String, dynamic>) {
          final loc = item['loc'] as List?;
          final field = loc != null && loc.length > 1
              ? loc.last.toString()
              : 'error';
          fieldErrors[field] = item['msg']?.toString() ?? '';
        }
      }
      return Failure.validation(fieldErrors: fieldErrors);
    }
    return Failure.validation(
      fieldErrors: {'error': rawDetail?.toString() ?? 'Validation error'},
    );
  }
}
