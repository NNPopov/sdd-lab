import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/update_user_request_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/entities/user_update.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/ports/update_user_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: UpdateUserPort)
class UpdateUserAdapter implements UpdateUserPort {
  UpdateUserAdapter(this._api, this._logger);

  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, User>> call({
    required User original,
    required UserUpdate update,
  }) async {
    try {
      try {
        await _api.updateUser(
          original.id,
          UpdateUserRequestDto(
            name: update.name,
            username: update.username,
            email: update.email,
            profileImageUrl: update.profileImageUrl,
          ),
        );
        // Server returned 200 with no resource body (CQS style).
        // Build the updated User locally by applying the patch to the original.
        return Right(_applyUpdate(original, update));
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
            return const Left(Failure.notFound(message: 'User not found'));
          case 409:
            return Left(
              Failure.conflict(
                message: _extractDetail(e) ?? 'Conflict',
              ),
            );
          case 422:
            return Left(_parseValidation(e));
          default:
            final failure = e.error;
            if (failure is Failure) return Left(failure);
            return Left(Failure.network(message: e.message));
        }
      }
    } on Object catch (e, st) {
      _logger.error(
        'UpdateUserAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }

  User _applyUpdate(User original, UserUpdate update) {
    return original.copyWith(
      name: update.name ?? original.name,
      username: update.username ?? original.username,
      email: update.email ?? original.email,
      profileImageUrl: update.profileImageUrl ?? original.profileImageUrl,
    );
  }

  String? _extractDetail(DioException e) {
    final detail = (e.response?.data as Map<String, dynamic>?)?['detail'];
    return detail?.toString();
  }

  FieldValidationFailure _parseValidation(DioException e) {
    final rawDetail = (e.response?.data as Map<String, dynamic>?)?['detail'];
    if (rawDetail is List) {
      final fields = <String, String>{};
      for (final item in rawDetail) {
        if (item is Map<String, dynamic>) {
          final loc = item['loc'] as List?;
          final field = loc != null && loc.length > 1
              ? loc.last.toString()
              : 'error';
          fields[field] = item['msg']?.toString() ?? '';
        }
      }
      return FieldValidationFailure(fields: fields);
    }
    return FieldValidationFailure(
      fields: {'_form': rawDetail?.toString() ?? 'Validation error'},
    );
  }
}
