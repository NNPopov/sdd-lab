import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/entities/new_post_data.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/ports/create_post_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class CreatePostUseCase {
  CreatePostUseCase(this._port, this._authCubit);

  final CreatePostPort _port;
  final AuthCubit _authCubit;

  Future<Either<Failure, void>> call(NewPostData data) async {
    final currentUser = _authCubit.currentUser;
    if (currentUser == null || currentUser.username != data.username) {
      return const Left(
        Failure.forbidden(message: 'Cannot post as another user'),
      );
    }
    return _port(data);
  }
}
