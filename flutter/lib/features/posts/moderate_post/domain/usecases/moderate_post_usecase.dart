import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/moderate_post/domain/ports/i_moderate_post_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class ModeratePostUseCase {
  ModeratePostUseCase(this._port);

  final IModeratePostPort _port;

  Future<Either<Failure, PostStatus>> call({
    required String postUuid,
    required String action,
    String? message,
  }) {
    if (action == 'changes_requested' &&
        (message == null || message.trim().isEmpty)) {
      return Future.value(
        const Left(Failure.validation(fieldErrors: {'message': 'required'})),
      );
    }
    return _port(postUuid: postUuid, action: action, message: message);
  }
}
