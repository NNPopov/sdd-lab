import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/create_post/application/create_post_cubit.dart';
import 'package:flutter_application_1/features/posts/create_post/application/create_post_state.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/entities/new_post_data.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/usecases/create_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreatePostUseCase extends Mock implements CreatePostUseCase {}

void main() {
  late _MockCreatePostUseCase useCase;
  late CreatePostCubit cubit;

  const data = NewPostData(
    userId: 1,
    title: 'My Post',
    text: 'body text',
  );

  setUp(() {
    useCase = _MockCreatePostUseCase();
    cubit = CreatePostCubit(useCase);
    registerFallbackValue(data);
  });

  tearDown(() => cubit.close());

  blocTest<CreatePostCubit, CreatePostState>(
    'submit success emits [loading, success]',
    build: () => cubit,
    setUp: () {
      when(() => useCase(any())).thenAnswer((_) async => const Right(null));
    },
    act: (c) => c.submit(data),
    expect: () => [
      const CreatePostState.loading(),
      const CreatePostState.success(),
    ],
  );

  blocTest<CreatePostCubit, CreatePostState>(
    'submit failure emits [loading, error]',
    build: () => cubit,
    setUp: () {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Left(Failure.network()));
    },
    act: (c) => c.submit(data),
    expect: () => [
      const CreatePostState.loading(),
      const CreatePostState.error(Failure.network()),
    ],
  );
}
