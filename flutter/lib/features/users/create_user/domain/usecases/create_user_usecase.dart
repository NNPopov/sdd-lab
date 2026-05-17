import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/create_user/domain/entities/new_user_data.dart';
import 'package:flutter_application_1/features/users/create_user/domain/ports/create_user_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class CreateUserUseCase {
  const CreateUserUseCase(this._port);

  final CreateUserPort _port;

  Future<Either<Failure, User>> call(NewUserData data) => _port(data);
}
