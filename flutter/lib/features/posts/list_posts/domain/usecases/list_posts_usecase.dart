import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_posts.dart';
import 'package:flutter_application_1/features/posts/list_posts/domain/ports/list_posts_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class ListPostsUseCase {
  ListPostsUseCase(this._port);

  final ListPostsPort _port;

  Future<Either<Failure, PaginatedPosts>> call({
    required int page,
    required int perPage,
  }) => _port(page: page, perPage: perPage);
}
