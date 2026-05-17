import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/entities/user_tier.dart';

abstract class GetUserTierPort {
  Future<Either<Failure, UserTier>> call(String username);
}
