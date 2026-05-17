import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/ports/moderator_management_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class RevokeModeratorUseCase {
  RevokeModeratorUseCase(this._port);

  final ModeratorManagementPort _port;

  Future<Either<Failure, void>> call(String username) =>
      _port.revokeModerator(username);
}
