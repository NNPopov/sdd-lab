import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/create_user/domain/entities/new_user_data.dart';

abstract class CreateUserPort {
  Future<Either<Failure, User>> call(NewUserData data);
}
