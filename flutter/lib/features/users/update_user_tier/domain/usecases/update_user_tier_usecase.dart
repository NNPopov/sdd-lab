import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/ports/update_user_tier_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class UpdateUserTierUseCase {
  const UpdateUserTierUseCase(this._port);
  final UpdateUserTierPort _port;

  Future<Either<Failure, Unit>> call({
    required int userId,
    required int tierId,
    required bool isSuperuser,
  }) async {
    if (!isSuperuser) return const Left(Failure.permissionDenied());
    return _port(userId: userId, tierId: tierId);
  }
}
