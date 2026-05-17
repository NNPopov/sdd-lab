import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/domain/entities/auth_session.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';

abstract class AuthApiPort {
  Future<Either<Failure, AuthSession>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, CurrentUser>> getCurrentUser();
}
