import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/list_users/domain/entities/paginated_users.dart';
import 'package:flutter_application_1/features/users/list_users/domain/ports/list_users_port.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetUsersUseCase {
  const GetUsersUseCase(this._port);

  final ListUsersPort _port;

  Future<Either<Failure, PaginatedUsers>> call({
    int page = 1,
    int perPage = 10,
  }) => _port(page: page, perPage: perPage);
}
