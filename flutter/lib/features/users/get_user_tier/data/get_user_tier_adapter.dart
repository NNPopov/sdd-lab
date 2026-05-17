import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/get_user_tier/data/dto/user_tier_dto.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/entities/user_tier.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/ports/get_user_tier_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: GetUserTierPort)
class GetUserTierAdapter implements GetUserTierPort {
  GetUserTierAdapter(this._api, this._logger);

  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, UserTier>> call(String username) async {
    try {
      try {
        final dto = await _api.getUserTier(username);
        return Right(dto.toDomain());
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'GetUserTierAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return Failure.unauthorized(
          message: _extractDetail(e) ?? 'Session expired',
        );
      case 403:
        return Failure.forbidden(
          message: _extractDetail(e) ?? 'Forbidden',
        );
      case 404:
        return const Failure.notFound(message: 'Tier not assigned');
      default:
        final failure = e.error;
        if (failure is Failure) return failure;
        return Failure.network(message: e.message);
    }
  }

  String? _extractDetail(DioException e) {
    final detail = (e.response?.data as Map<String, dynamic>?)?['detail'];
    return detail?.toString();
  }
}
