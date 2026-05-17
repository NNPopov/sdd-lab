import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_posts.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/list_posts/domain/ports/list_posts_port.dart';
import 'package:flutter_application_1/features/posts/list_posts/domain/usecases/list_posts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListPostsPort extends Mock implements ListPostsPort {}

void main() {
  late _MockListPostsPort port;
  late ListPostsUseCase useCase;

  final paginated = PaginatedPosts(
    items: [
      Post(
        id: 1,
        title: 'Post',
        text: 'Text',
        createdAt: DateTime(2026),
        createdByUserId: 1,
        postUuid: 'test-uuid',
        status: PostStatus.pendingReview,
      ),
    ],
    totalCount: 20,
    page: 1,
    itemsPerPage: 10,
  );

  setUp(() {
    port = _MockListPostsPort();
    useCase = ListPostsUseCase(port);
  });

  test('delegates to port and returns Right on success', () async {
    when(
      () => port(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(paginated));

    final result = await useCase(page: 1, perPage: 10);

    expect(result, Right<Failure, PaginatedPosts>(paginated));
    verify(() => port(page: 1, perPage: 10)).called(1);
  });

  test('delegates to port and returns Left on failure', () async {
    const failure = Failure.network();
    when(
      () => port(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(page: 1, perPage: 10);

    expect(result, const Left<Failure, PaginatedPosts>(failure));
  });
}
