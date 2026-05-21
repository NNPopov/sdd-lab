import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/entities/user_update.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/ports/update_user_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class UpdateUserUseCase {
  const UpdateUserUseCase(this._port);

  final UpdateUserPort _port;

  Future<Either<Failure, User>> call({
    required User original,
    required UserUpdate update,
  }) {
    if (update.isEmpty) {
      return Future.value(
        const Left(
          FieldValidationFailure(fields: {'_form': 'Nothing to update'}),
        ),
      );
    }
    return _port(original: original, update: update);
  }
}
