import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/auth/data/auth_api_client.dart';
import 'package:flutter_application_1/core/auth/data/dto/current_user_dto.dart';
import 'package:flutter_application_1/core/auth/domain/entities/auth_session.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/auth/domain/ports/auth_api_port.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthApiPort)
class AuthApiAdapter implements AuthApiPort {
  AuthApiAdapter(this._api, this._logger);

  final AuthApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String username,
    required String password,
  }) async {
    try {
      try {
        final dto = await _api.login(username: username, password: password);
        return Right(
          AuthSession(accessToken: dto.accessToken, username: username),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          final data = e.response?.data;
          final detail = data is Map ? (data['detail'] as String?) : null;
          return Left(
            Failure.invalidCredentials(
              message: detail ?? 'Invalid credentials',
            ),
          );
        }
        return Left(_mapError(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'AuthApiAdapter.login failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      try {
        await _api.logout();
        return const Right(unit);
      } on DioException catch (e) {
        return Left(_mapError(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'AuthApiAdapter.logout failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  @override
  Future<Either<Failure, CurrentUser>> getCurrentUser() async {
    try {
      try {
        final dto = await _api.getCurrentUser();
        return Right(dto.toDomain());
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          final data = e.response?.data;
          final detail = data is Map ? (data['detail'] as String?) : null;
          return Left(
            Failure.invalidCredentials(message: detail ?? 'Unauthorized'),
          );
        }
        return Left(_mapError(e));
      }
    } on Object catch (e, st) {
      _logger.error(
        'AuthApiAdapter.getCurrentUser failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  Failure _mapError(DioException e) {
    if (e.error is Failure) return e.error! as Failure;
    return Failure.unknown(error: e);
  }
}
