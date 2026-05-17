import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/domain/ports/erase_db_post_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class EraseDbPostUseCase {
  EraseDbPostUseCase(this._port);

  final EraseDbPostPort _port;

  Future<Either<Failure, Unit>> call({
    required String username,
    required int id,
    required bool isSuperuser,
  }) async {
    if (!isSuperuser) return const Left(Failure.permissionDenied());
    return _port(username, id);
  }
}
