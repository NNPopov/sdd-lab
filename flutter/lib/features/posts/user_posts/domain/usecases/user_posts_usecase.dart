import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_posts.dart';
import 'package:flutter_application_1/features/posts/user_posts/domain/ports/user_posts_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class UserPostsUseCase {
  UserPostsUseCase(this._port);

  final UserPostsPort _port;

  Future<Either<Failure, PaginatedPosts>> call({
    required int userId,
    required int page,
    required int perPage,
  }) => _port(userId: userId, page: page, perPage: perPage);
}
