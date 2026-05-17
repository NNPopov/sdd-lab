import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/entities/tier_detail.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/ports/get_tier_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetTierUsecase {
  const GetTierUsecase(this._port, this._permissions);

  final GetTierPort _port;
  final PermissionCubit _permissions;

  Future<Either<Failure, TierDetail>> call(String name) {
    if (!_permissions.has(Permission.manageTiers)) {
      return Future.value(const Left(Failure.permissionDenied()));
    }
    return _port(name);
  }
}
