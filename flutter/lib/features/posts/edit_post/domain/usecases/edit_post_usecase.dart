import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/ports/edit_post_port.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/ports/i_revise_post_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class EditPostUseCase {
  EditPostUseCase(this._editPort, this._revisePort, this._authCubit);

  final EditPostPort _editPort;
  final IRevisePostPort _revisePort;
  final AuthCubit _authCubit;

  Future<Either<Failure, void>> call(UpdatedPostData data) async {
    final currentUser = _authCubit.currentUser;
    if (currentUser == null || currentUser.username != data.username) {
      return const Left(
        Failure.forbidden(message: "Cannot edit another user's post"),
      );
    }

    if (data.status == PostStatus.changesRequested) {
      final msg = data.revisionMessage?.trim() ?? '';
      if (msg.isEmpty) {
        return const Left(
          FieldValidationFailure(
            fields: {'message': 'Revision message is required'},
          ),
        );
      }
      return _revisePort(data);
    }

    return _editPort(data);
  }
}
