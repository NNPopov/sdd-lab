import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/features/tiers/_shared/domain/entities/tier.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/entities/new_tier_data.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/ports/create_tier_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class CreateTierUseCase {
  const CreateTierUseCase(this._port, this._permissions);

  final CreateTierPort _port;
  final PermissionCubit _permissions;

  Future<Either<Failure, Tier>> call(NewTierData data) {
    if (!_permissions.has(Permission.manageTiers)) {
      return Future.value(const Left(Failure.permissionDenied()));
    }
    return _port(data);
  }
}
