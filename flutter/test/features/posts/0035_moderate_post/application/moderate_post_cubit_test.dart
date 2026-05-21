import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_cubit.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_state.dart';
import 'package:flutter_application_1/features/posts/moderate_post/domain/usecases/moderate_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockModeratePostUseCase extends Mock implements ModeratePostUseCase {}

void main() {
  late _MockModeratePostUseCase useCase;
  late PostEventBus eventBus;

  setUp(() {
    useCase = _MockModeratePostUseCase();
    eventBus = PostEventBus();
  });

  tearDown(() async {
    await eventBus.dispose();
  });

  blocTest<ModeratePostCubit, ModeratePostState>(
    'moderate(approved) success → emits [loading, success(approved)], '
    'PostEventBus emits PostModeratedEvent',
    build: () => ModeratePostCubit(useCase, eventBus),
    setUp: () {
      when(
        () => useCase(
          postUuid: any(named: 'postUuid'),
          action: any(named: 'action'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => const Right(PostStatus.approved));
    },
    act: (cubit) async {
      final eventExpectation = expectLater(
        eventBus.stream,
        emits(isA<PostModeratedEvent>()),
      );
      await cubit.moderate(
        postUuid: 'uuid-1',
        action: 'approved',
      );
      await eventExpectation;
    },
    expect: () => [
      const ModeratePostState.loading(),
      isA<ModeratePostSuccess>().having(
        (s) => s.newStatus,
        'newStatus',
        PostStatus.approved,
      ),
    ],
  );

  blocTest<ModeratePostCubit, ModeratePostState>(
    'moderate(approved) port failure → emits [loading, error(failure)]',
    build: () => ModeratePostCubit(useCase, eventBus),
    setUp: () {
      when(
        () => useCase(
          postUuid: any(named: 'postUuid'),
          action: any(named: 'action'),
          message: any(named: 'message'),
        ),
      ).thenAnswer(
        (_) async => const Left(Failure.notFound()),
      );
    },
    act: (cubit) => cubit.moderate(
      postUuid: 'uuid-1',
      action: 'approved',
    ),
    expect: () => [
      const ModeratePostState.loading(),
      isA<ModeratePostError>().having(
        (s) => s.failure,
        'failure',
        isA<NotFoundFailure>(),
      ),
    ],
  );

  blocTest<ModeratePostCubit, ModeratePostState>(
    'moderate(changes_requested) + empty message → '
    'emits [loading, error(ValidationFailure)]',
    build: () => ModeratePostCubit(useCase, eventBus),
    setUp: () {
      when(
        () => useCase(
          postUuid: any(named: 'postUuid'),
          action: any(named: 'action'),
          message: any(named: 'message'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          FieldValidationFailure(fields: {'message': 'required'}),
        ),
      );
    },
    act: (cubit) => cubit.moderate(
      postUuid: 'uuid-1',
      action: 'changes_requested',
      message: '',
    ),
    expect: () => [
      const ModeratePostState.loading(),
      isA<ModeratePostError>().having(
        (s) => s.failure,
        'failure',
        isA<FieldValidationFailure>(),
      ),
    ],
  );
}
