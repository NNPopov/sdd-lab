import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';

abstract class DeleteUserPort {
  Future<Either<Failure, Unit>> call(int userId);
}
