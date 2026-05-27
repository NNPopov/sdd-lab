import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';

abstract interface class ModeratorManagementPort {
  Future<Either<Failure, void>> assignModerator(int userId);
  Future<Either<Failure, void>> revokeModerator(int userId);
}
