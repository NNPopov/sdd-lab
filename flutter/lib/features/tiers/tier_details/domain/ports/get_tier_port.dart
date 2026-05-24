import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/entities/tier_detail.dart';

abstract class GetTierPort {
  Future<Either<Failure, TierDetail>> call(int id);
}
