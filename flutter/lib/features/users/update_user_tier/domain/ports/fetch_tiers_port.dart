import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/entities/tier_option.dart';

abstract class FetchTiersPort {
  Future<Either<Failure, List<TierOption>>> call();
}
