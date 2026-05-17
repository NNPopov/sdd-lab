import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/delete_post/domain/ports/delete_post_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeletePostUseCase {
  DeletePostUseCase(this._port, this._authCubit);

  final DeletePostPort _port;
  final AuthCubit _authCubit;

  Future<Either<Failure, Unit>> call(String username, int id) async {
    final currentUser = _authCubit.currentUser;
    if (currentUser == null || currentUser.username != username) {
      return const Left(
        Failure.forbidden(message: "Cannot delete another user's post"),
      );
    }
    return _port(username, id);
  }
}
