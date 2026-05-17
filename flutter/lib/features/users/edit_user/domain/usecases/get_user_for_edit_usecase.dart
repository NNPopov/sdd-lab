import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/ports/get_user_for_edit_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetUserForEditUseCase {
  const GetUserForEditUseCase(this._port);

  final GetUserForEditPort _port;

  Future<Either<Failure, User>> call(String username) => _port(username);
}
