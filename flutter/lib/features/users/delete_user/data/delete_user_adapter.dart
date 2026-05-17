import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/delete_user/domain/ports/delete_user_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DeleteUserPort)
class DeleteUserAdapter implements DeleteUserPort {
  DeleteUserAdapter(this._api, this._logger);

  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Unit>> call(String username) async {
    try {
      try {
        await _api.deleteUser(username);
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
        'DeleteUserAdapter.call failed unexpectedly',
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
