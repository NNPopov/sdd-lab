import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';

abstract class DeleteTierPort {
  Future<Either<Failure, Unit>> call(int id);
}
