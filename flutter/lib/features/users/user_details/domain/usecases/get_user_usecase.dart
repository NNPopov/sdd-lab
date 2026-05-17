import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/user_details/domain/ports/get_user_port.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetUserUseCase {
  const GetUserUseCase(this._port);

  final GetUserPort _port;

  Future<Either<Failure, User>> call(String username) => _port(username);
}
