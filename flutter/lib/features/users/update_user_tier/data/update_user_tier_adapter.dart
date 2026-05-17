import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/dto/update_user_tier_request_dto.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/ports/update_user_tier_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: UpdateUserTierPort)
class UpdateUserTierAdapter implements UpdateUserTierPort {
  UpdateUserTierAdapter(this._api, this._logger);

  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Unit>> call({
    required String username,
    required int tierId,
  }) async {
    try {
      try {
        await _api.patchUserTier(
          username,
          UpdateUserTierRequestDto(tierId: tierId),
        );
        return const Right(unit);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'UpdateUserTierAdapter.call failed',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    return switch (e.response?.statusCode) {
      401 => const Failure.unauthorized(message: 'Session expired'),
      403 => const Failure.forbidden(message: 'Permission denied'),
      404 => const Failure.notFound(message: 'User or tier not found'),
      _ => Failure.server(statusCode: e.response?.statusCode),
    };
  }
}
