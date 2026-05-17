import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/entities/user_tier.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/ports/get_user_tier_port.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetUserTierUseCase {
  const GetUserTierUseCase(this._port);

  final GetUserTierPort _port;

  Future<Either<Failure, UserTier>> call(String username) => _port(username);
}
