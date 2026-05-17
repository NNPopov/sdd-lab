import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/entities/edit_tier_data.dart';

abstract class EditTierPort {
  Future<Either<Failure, Unit>> call(EditTierData data);
}
