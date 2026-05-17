import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/entities/edit_tier_data.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/ports/edit_tier_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class EditTierUseCase {
  const EditTierUseCase(this._port);

  final EditTierPort _port;

  Future<Either<Failure, Unit>> call({
    required EditTierData data,
    required bool isSuperuser,
  }) {
    if (!isSuperuser) {
      return Future.value(const Left(Failure.permissionDenied()));
    }
    return _port(data);
  }
}
