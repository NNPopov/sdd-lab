import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_cubit.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_state.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/domain/usecases/erase_db_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEraseDbPostUseCase extends Mock implements EraseDbPostUseCase {}

class _MockAuthCubit extends Mock implements AuthCubit {}

class _MockPostEventBus extends Mock implements PostEventBus {}

const _superuser = CurrentUser(
  id: 1,
  username: 'admin',
  email: 'admin@example.com',
  name: 'Admin',
  isSuperuser: true,
  isModerator: false,
);

const _regularUser = CurrentUser(
  id: 1,
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

void main() {
  setUpAll(() {
    registerFallbackValue(PostDeleted(0));
  });

  late _MockEraseDbPostUseCase useCase;
  late _MockAuthCubit authCubit;
  late _MockPostEventBus eventBus;

  const userId = 7;
  const postId = 42;

  setUp(() {
    useCase = _MockEraseDbPostUseCase();
    authCubit = _MockAuthCubit();
    eventBus = _MockPostEventBus();
  });

  EraseDbPostCubit build() => EraseDbPostCubit(useCase, authCubit, eventBus);

  group('requestConfirmation', () {
    blocTest<EraseDbPostCubit, EraseDbPostState>(
      'emits [confirming]',
      build: build,
      act: (c) => c.requestConfirmation(),
      expect: () => [const EraseDbPostState.confirming()],
    );
  });

  group('cancel', () {
    blocTest<EraseDbPostCubit, EraseDbPostState>(
      'from confirming emits [initial]',
      build: build,
      seed: () => const EraseDbPostState.confirming(),
      act: (c) => c.cancel(),
      expect: () => [const EraseDbPostState.initial()],
    );

    blocTest<EraseDbPostCubit, EraseDbPostState>(
      'from initial emits nothing',
      build: build,
      seed: () => const EraseDbPostState.initial(),
      act: (c) => c.cancel(),
      expect: () => <EraseDbPostState>[],
    );
  });

  group('confirmAndErase', () {
    blocTest<EraseDbPostCubit, EraseDbPostState>(
      'success emits [deleting, success] and publishes PostDeleted',
      build: build,
      setUp: () {
        when(() => authCubit.currentUser).thenReturn(_superuser);
        when(
          () => useCase(
            userId: userId,
            id: postId,
            isSuperuser: true,
          ),
        ).thenAnswer((_) async => const Right(unit));
        when(() => eventBus.publish(any())).thenReturn(null);
      },
      act: (c) => c.confirmAndErase(userId, postId),
      expect: () => [
        const EraseDbPostState.deleting(),
        const EraseDbPostState.success(),
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

    blocTest<EraseDbPostCubit, EraseDbPostState>(
      'failure emits [deleting, failure] and does NOT publish event',
      build: build,
      setUp: () {
        when(() => authCubit.currentUser).thenReturn(_superuser);
        when(
          () => useCase(
            userId: userId,
            id: postId,
            isSuperuser: true,
          ),
        ).thenAnswer(
          (_) async => const Left(Failure.forbidden(message: 'Forbidden')),
        );
      },
      act: (c) => c.confirmAndErase(userId, postId),
      expect: () => [
        const EraseDbPostState.deleting(),
        const EraseDbPostState.failure(
          Failure.forbidden(message: 'Forbidden'),
        ),
      ],
      verify: (_) {
        verifyNever(() => eventBus.publish(any()));
      },
    );

    blocTest<EraseDbPostCubit, EraseDbPostState>(
      'emits [deleting, failure] when isSuperuser is false '
      '(use-case returns PermissionDenied)',
      build: build,
      setUp: () {
        when(() => authCubit.currentUser).thenReturn(_regularUser);
        when(
          () => useCase(
            userId: userId,
            id: postId,
            isSuperuser: false,
          ),
        ).thenAnswer(
          (_) async => const Left(Failure.permissionDenied()),
        );
      },
      act: (c) => c.confirmAndErase(userId, postId),
      expect: () => [
        const EraseDbPostState.deleting(),
        const EraseDbPostState.failure(Failure.permissionDenied()),
      ],
      verify: (_) {
        verifyNever(() => eventBus.publish(any()));
      },
    );
  });
}
