import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/create_user_request_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/user_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/create_user/domain/entities/new_user_data.dart';
import 'package:flutter_application_1/features/users/create_user/domain/ports/create_user_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CreateUserPort)
class CreateUserAdapter implements CreateUserPort {
  CreateUserAdapter(this._api, this._logger);

  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, User>> call(NewUserData data) async {
    try {
      try {
        final request = CreateUserRequestDto(
          name: data.name,
          username: data.username,
          email: data.email,
          password: data.password,
        );
        final dto = await _api.createUser(request);
        return Right(dto.toDomain());
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        if (statusCode == 409) {
          final detail = (e.response?.data as Map<String, dynamic>?)?['detail'];
          return Left(
            Failure.conflict(message: detail?.toString() ?? 'Conflict'),
          );
        }

        if (statusCode == 422) {
          return Left(_parseValidation(e));
        }

        final failure = e.error;
        if (failure is Failure) return Left(failure);
        return Left(Failure.network(message: e.message));
      }
    } on Object catch (e, st) {
      _logger.error(
        'CreateUserAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  MessageValidationFailure _parseValidation(DioException e) {
    final rawDetail = (e.response?.data as Map<String, dynamic>?)?['detail'];
    return MessageValidationFailure(
      message: rawDetail?.toString() ?? 'Validation error',
    );
  }
}
