import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/moderate_post/domain/ports/i_moderate_post_port.dart';
import 'package:flutter_application_1/features/posts/moderate_post/domain/usecases/moderate_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPort extends Mock implements IModeratePostPort {}

void main() {
  late _MockPort port;
  late ModeratePostUseCase useCase;

  setUp(() {
    port = _MockPort();
    useCase = ModeratePostUseCase(port);
  });

  test(
    'changes_requested + empty message → ValidationFailure, port not called',
    () async {
      final result = await useCase(
        postUuid: 'uuid-1',
        action: 'changes_requested',
        message: '',
      );
      expect(result.isLeft(), isTrue);
      expect(result.fold(id, id), isA<FieldValidationFailure>());
      verifyNever(
        () => port(
          postUuid: any(named: 'postUuid'),
          action: any(named: 'action'),
          message: any(named: 'message'),
        ),
      );
    },
  );

  test(
    'changes_requested + null message → ValidationFailure, port not called',
    () async {
      final result = await useCase(
        postUuid: 'uuid-1',
        action: 'changes_requested',
      );
      expect(result.isLeft(), isTrue);
      expect(result.fold(id, id), isA<FieldValidationFailure>());
      verifyNever(
        () => port(
          postUuid: any(named: 'postUuid'),
          action: any(named: 'action'),
          message: any(named: 'message'),
        ),
      );
    },
  );

  test('approved + null message → port called → Right(PostStatus)', () async {
    when(
      () => port(
        postUuid: any(named: 'postUuid'),
        action: any(named: 'action'),
        message: any(named: 'message'),
      ),
    ).thenAnswer((_) async => const Right(PostStatus.approved));

    final result = await useCase(
      postUuid: 'uuid-1',
      action: 'approved',
    );

    expect(
      result,
      equals(const Right<Failure, PostStatus>(PostStatus.approved)),
    );
    verify(
      () => port(
        postUuid: 'uuid-1',
        action: 'approved',
      ),
    ).called(1);
  });

  test(
    'port returns Left(failure) → use-case propagates it unchanged',
    () async {
      const failure = Failure.notFound();
      when(
        () => port(
          postUuid: any(named: 'postUuid'),
          action: any(named: 'action'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        postUuid: 'uuid-1',
        action: 'approved',
      );

      expect(result, equals(const Left<Failure, PostStatus>(failure)));
    },
  );
}
