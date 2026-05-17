import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/domain/entities/paginated_tiers.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/domain/ports/list_tiers_port.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ListTiersUseCase {
  const ListTiersUseCase(this._port);

  final ListTiersPort _port;

  Future<Either<Failure, PaginatedTiers>> call({
    required Set<Permission> permissions,
    required int page,
    required int perPage,
  }) async {
    if (!permissions.contains(Permission.manageTiers)) {
      return const Left(Failure.permissionDenied());
    }
    return _port(page: page, perPage: perPage);
  }
}
