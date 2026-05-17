import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/domain/entities/paginated_tiers.dart';

abstract class ListTiersPort {
  Future<Either<Failure, PaginatedTiers>> call({
    required int page,
    required int perPage,
  });
}
