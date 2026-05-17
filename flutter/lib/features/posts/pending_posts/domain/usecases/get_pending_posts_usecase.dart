import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_result.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/pending_posts/domain/ports/pending_posts_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetPendingPostsUseCase {
  GetPendingPostsUseCase(this._port);

  final PendingPostsPort _port;

  Future<Either<Failure, PaginatedResult<PendingPostItem>>> call({
    required int page,
    required int perPage,
  }) => _port(page: page, perPage: perPage);
}
