import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';

abstract class UpdateUserTierPort {
  Future<Either<Failure, Unit>> call({
    required String username,
    required int tierId,
  });
}
