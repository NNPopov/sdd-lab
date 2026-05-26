import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_posts.dart';

abstract class UserPostsPort {
  Future<Either<Failure, PaginatedPosts>> call({
    required int userId,
    required int page,
    required int perPage,
  });
}
