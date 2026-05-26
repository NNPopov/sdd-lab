import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/delete_user/domain/ports/delete_user_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteUserUseCase {
  DeleteUserUseCase(this._port);

  final DeleteUserPort _port;

  Future<Either<Failure, Unit>> call({
    required int userId,
    required int currentUserId,
  }) async {
    if (userId != currentUserId) {
      return const Left(Failure.permissionDenied());
    }
    return _port(userId);
  }
}
