import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/ports/moderator_management_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ModeratorManagementPort)
class ModeratorManagementAdapter implements ModeratorManagementPort {
  ModeratorManagementAdapter(this._api, this._logger);

  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, void>> assignModerator(String username) async {
    try {
      try {
        await _api.assignModerator(username);
        return const Right(null);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'ModeratorManagementAdapter.assignModerator failed',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  @override
  Future<Either<Failure, void>> revokeModerator(String username) async {
    try {
      try {
        await _api.revokeModerator(username);
        return const Right(null);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'ModeratorManagementAdapter.revokeModerator failed',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    return switch (e.response?.statusCode) {
      403 => const Failure.forbidden(message: 'Permission denied'),
      404 => const Failure.notFound(),
      409 => const Failure.conflict(message: 'Conflict'),
      _ => Failure.server(statusCode: e.response?.statusCode),
    };
  }
}
