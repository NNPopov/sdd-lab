import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_result.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';

abstract class PendingPostsPort {
  Future<Either<Failure, PaginatedResult<PendingPostItem>>> call({
    required int page,
    required int perPage,
  });
}
