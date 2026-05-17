import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/domain/ports/delete_tier_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteTierUseCase {
  const DeleteTierUseCase(this._port);

  final DeleteTierPort _port;

  Future<Either<Failure, Unit>> call({
    required String name,
    required bool isSuperuser,
  }) {
    if (!isSuperuser) {
      return Future.value(const Left(Failure.permissionDenied()));
    }
    return _port(name);
  }
}
