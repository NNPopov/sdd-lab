import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_cubit.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_state.dart';
import 'package:flutter_application_1/features/posts/delete_post/domain/usecases/delete_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeletePostUseCase extends Mock implements DeletePostUseCase {}

class _MockPostEventBus extends Mock implements PostEventBus {}

void main() {
  setUpAll(() {
    registerFallbackValue(PostDeleted(0));
  });

  late _MockDeletePostUseCase useCase;
  late _MockPostEventBus eventBus;

  const userId = 7;
  const postId = 42;

  setUp(() {
    useCase = _MockDeletePostUseCase();
    eventBus = _MockPostEventBus();
  });

  DeletePostCubit build() => DeletePostCubit(useCase, eventBus);

  group('requestConfirmation', () {
    blocTest<DeletePostCubit, DeletePostState>(
      'emits [confirming]',
      build: build,
      act: (c) => c.requestConfirmation(),
      expect: () => [const DeletePostState.confirming()],
    );
  });

  group('cancel', () {
    blocTest<DeletePostCubit, DeletePostState>(
      'from confirming emits [initial]',
      build: build,
      seed: () => const DeletePostState.confirming(),
      act: (c) => c.cancel(),
      expect: () => [const DeletePostState.initial()],
    );

    blocTest<DeletePostCubit, DeletePostState>(
      'from initial emits nothing',
      build: build,
      seed: () => const DeletePostState.initial(),
      act: (c) => c.cancel(),
      expect: () => <DeletePostState>[],
    );
  });

  group('confirmAndDelete', () {
    blocTest<DeletePostCubit, DeletePostState>(
      'success emits [deleting, success] and publishes PostDeleted',
      build: build,
      setUp: () {
        when(
          () => useCase(userId, postId),
        ).thenAnswer((_) async => const Right(unit));
        when(() => eventBus.publish(any())).thenReturn(null);
      },
      act: (c) => c.confirmAndDelete(userId, postId),
      expect: () => [
        const DeletePostState.deleting(),
        const DeletePostState.success(),
      ],
      verify: (_) {
        verify(
          () => eventBus.publish(
            any(
              that: predicate<PostEvent>(
                (e) => e is PostDeleted && e.id == postId,
              ),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<DeletePostCubit, DeletePostState>(
      'failure emits [deleting, failure]',
      build: build,
      setUp: () {
        when(() => useCase(userId, postId)).thenAnswer(
          (_) async => const Left(Failure.forbidden(message: 'forbidden')),
        );
      },
      act: (c) => c.confirmAndDelete(userId, postId),
      expect: () => [
        const DeletePostState.deleting(),
        const DeletePostState.failure(
          Failure.forbidden(message: 'forbidden'),
        ),
      ],
    );
  });
}
