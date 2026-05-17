import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/user_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/list_users/domain/entities/paginated_users.dart';
import 'package:flutter_application_1/features/users/list_users/domain/ports/list_users_port.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ListUsersPort)
class ListUsersAdapter implements ListUsersPort {
  ListUsersAdapter(this._api, this._logger);

  final UsersApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, PaginatedUsers>> call({
    required int page,
    required int perPage,
  }) async {
    try {
      try {
        final dto = await _api.getUsers(page: page, perPage: perPage);
        return Right(
          PaginatedUsers(
            users: dto.items.map((u) => u.toDomain()).toList(),
            totalCount: dto.totalCount,
            page: dto.page,
            itemsPerPage: dto.itemsPerPage,
          ),
        );
      } on DioException catch (e) {
        final failure = e.error;
        if (failure is Failure) return Left(failure);
        return Left(Failure.network(message: e.message));
      }
    } on Object catch (e, st) {
      _logger.error(
        'ListUsersAdapter.call failed unexpectedly',
        error: e,
        stackTrace: st,
      );
      return const Left(Failure.unknown());
    }
  }
}
