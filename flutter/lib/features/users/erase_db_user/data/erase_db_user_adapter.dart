import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/erase_db_user/domain/ports/erase_db_user_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: EraseDbUserPort)
class EraseDbUserAdapter implements EraseDbUserPort {
  EraseDbUserAdapter(this._api, this._logger);

  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Unit>> call(int userId) async {
    try {
      try {
        await _api.eraseDbUser(userId);
        return const Right(unit);
      } on DioException catch (e) {
        switch (e.response?.statusCode) {
          case 401:
            return Left(
              Failure.unauthorized(
                message: _extractDetail(e) ?? 'Session expired',
              ),
            );
          case 403:
            return Left(
              Failure.forbidden(message: _extractDetail(e) ?? 'Forbidden'),
            );
          case 404:
            return Left(
              Failure.notFound(message: _extractDetail(e) ?? 'User not found'),
            );
          default:
            final failure = e.error;
            if (failure is Failure) return Left(failure);
            return Left(Failure.network(message: e.message));
        }
      }
    } on Object catch (e, st) {
      _logger.error(
        'EraseDbUserAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  String? _extractDetail(DioException e) {
    final detail = (e.response?.data as Map<String, dynamic>?)?['detail'];
    return detail?.toString();
  }
}
