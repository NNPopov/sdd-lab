import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_cubit.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_state.dart';
import 'package:flutter_application_1/features/posts/post_details/domain/usecases/get_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetPostUseCase extends Mock implements GetPostUseCase {}

void main() {
  group('PostDetailsCubit', () {
    late _MockGetPostUseCase useCase;

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
      useCase = _MockGetPostUseCase();
    });

    blocTest<PostDetailsCubit, PostDetailsState>(
      'load(username, id) → Right(post) → emits [loading, loaded(post)]',
      build: () {
        when(() => useCase(any(), any())).thenAnswer((_) async => Right(post));
        return PostDetailsCubit(useCase);
      },
      act: (cubit) => cubit.load('testuser', 1),
      expect: () => [
        const PostDetailsState.loading(),
        PostDetailsState.loaded(post: post),
      ],
    );

    blocTest<PostDetailsCubit, PostDetailsState>(
      'load(username, id) → Left(NotFoundFailure) '
      '→ emits [loading, error(NotFoundFailure)]',
      build: () {
        when(
          () => useCase(any(), any()),
        ).thenAnswer((_) async => const Left(Failure.notFound()));
        return PostDetailsCubit(useCase);
      },
      act: (cubit) => cubit.load('testuser', 999),
      expect: () => [
        const PostDetailsState.loading(),
        const PostDetailsState.error(failure: Failure.notFound()),
      ],
    );

    blocTest<PostDetailsCubit, PostDetailsState>(
      'load(username, id) → Left(UnknownFailure) '
      '→ emits [loading, error(UnknownFailure)]',
      build: () {
        when(
          () => useCase(any(), any()),
        ).thenAnswer((_) async => const Left(Failure.unknown()));
        return PostDetailsCubit(useCase);
      },
      act: (cubit) => cubit.load('testuser', 1),
      expect: () => [
        const PostDetailsState.loading(),
        const PostDetailsState.error(failure: Failure.unknown()),
      ],
    );
  });
}
