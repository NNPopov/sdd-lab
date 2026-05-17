import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';

abstract class EraseDbUserPort {
  Future<Either<Failure, Unit>> call(String username);
}
