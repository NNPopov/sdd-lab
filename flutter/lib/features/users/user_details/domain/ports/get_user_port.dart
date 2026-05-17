import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';

abstract class GetUserPort {
  Future<Either<Failure, User>> call(String username);
}
