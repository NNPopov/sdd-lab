import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/list_users/domain/entities/paginated_users.dart';

abstract class ListUsersPort {
  Future<Either<Failure, PaginatedUsers>> call({
    required int page,
    required int perPage,
  });
}
