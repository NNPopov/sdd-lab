import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/erase_db_user/domain/ports/erase_db_user_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class EraseDbUserUseCase {
  EraseDbUserUseCase(this._port);

  final EraseDbUserPort _port;

  Future<Either<Failure, Unit>> call({
    required int userId,
    required bool isSuperuser,
  }) async {
    if (!isSuperuser) return const Left(Failure.permissionDenied());
    return _port(userId);
  }
}
