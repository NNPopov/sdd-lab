import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_cubit.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_state.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/usecases/edit_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEditPostUseCase extends Mock implements EditPostUseCase {}

void main() {
  late _MockEditPostUseCase useCase;
  late EditPostCubit cubit;

  const data = UpdatedPostData(
    username: 'alice',
    id: 1,
    postUuid: 'post-uuid-001',
    status: PostStatus.pendingReview,
    title: 'Updated Title',
    text: 'Updated text',
  );

  setUp(() {
    useCase = _MockEditPostUseCase();
    cubit = EditPostCubit(useCase);
    registerFallbackValue(data);
  });

  tearDown(() => cubit.close());

  blocTest<EditPostCubit, EditPostState>(
    'submit success emits [loading, success]',
    build: () => cubit,
    setUp: () {
      when(() => useCase(any())).thenAnswer((_) async => const Right(null));
    },
    act: (c) => c.submit(data),
    expect: () => [
      const EditPostState.loading(),
      const EditPostState.success(),
    ],
  );

  blocTest<EditPostCubit, EditPostState>(
    'submit failure emits [loading, error]',
    build: () => cubit,
    setUp: () {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Left(Failure.network()));
    },
    act: (c) => c.submit(data),
    expect: () => [
      const EditPostState.loading(),
      const EditPostState.error(Failure.network()),
    ],
  );

  blocTest<EditPostCubit, EditPostState>(
    'submit changesRequested data emits [loading, success]',
    build: () => cubit,
    setUp: () {
      when(() => useCase(any())).thenAnswer((_) async => const Right(null));
    },
    act: (c) => c.submit(
      const UpdatedPostData(
        username: 'alice',
        id: 1,
        postUuid: 'post-uuid-001',
        status: PostStatus.changesRequested,
        title: 'Revised Title',
        text: 'Revised body text with enough content to pass validation.',
        revisionMessage: 'Addressed the moderator feedback.',
      ),
    ),
    expect: () => [
      const EditPostState.loading(),
      const EditPostState.success(),
    ],
  );
}
