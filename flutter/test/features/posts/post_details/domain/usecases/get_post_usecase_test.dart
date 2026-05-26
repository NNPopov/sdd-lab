import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/post_details/domain/ports/post_details_port.dart';
import 'package:flutter_application_1/features/posts/post_details/domain/usecases/get_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostDetailsPort extends Mock implements PostDetailsPort {}

void main() {
  group('GetPostUseCase', () {
    late _MockPostDetailsPort port;
    late GetPostUseCase useCase;

    final post = Post(
      id: 1,
      title: 'Test Post',
      text: 'Some **markdown** text',
      createdAt: DateTime(2026, 1, 15, 14, 30),
      createdByUserId: 42,
      postUuid: 'test-uuid',
      status: PostStatus.pendingReview,
    );

    setUp(() {
      port = _MockPostDetailsPort();
      useCase = GetPostUseCase(port);
    });

    test('call(userId, id) → port Right(post) → Right(post)', () async {
      when(() => port(42, 1)).thenAnswer((_) async => Right(post));

      final result = await useCase(42, 1);

      expect(result, Right<Failure, Post>(post));
    });

    test('call(userId, id) → port Left(NotFoundFailure) '
        '→ Left(NotFoundFailure)', () async {
      when(
        () => port(42, 999),
      ).thenAnswer((_) async => const Left(Failure.notFound()));

      final result = await useCase(42, 999);

      expect(result, const Left<Failure, Post>(Failure.notFound()));
    });
  });
}
