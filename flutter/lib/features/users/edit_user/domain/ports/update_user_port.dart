import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/entities/user_update.dart';

abstract class UpdateUserPort {
  Future<Either<Failure, User>> call({
    required User original,
    required UserUpdate update,
  });
}
