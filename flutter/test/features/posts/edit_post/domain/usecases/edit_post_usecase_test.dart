import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/ports/edit_post_port.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/ports/i_revise_post_port.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/usecases/edit_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEditPostPort extends Mock implements EditPostPort {}

class _MockRevisePostPort extends Mock implements IRevisePostPort {}

class _MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late _MockEditPostPort editPort;
  late _MockRevisePostPort revisePort;
  late _MockAuthCubit authCubit;
  late EditPostUseCase useCase;

  const currentUser = CurrentUser(
    id: 1,
    username: 'alice',
    email: 'alice@example.com',
    name: 'Alice',
    isSuperuser: false,
    isModerator: false,
  );

  const pendingData = UpdatedPostData(
    username: 'alice',
    id: 1,
    postUuid: 'post-uuid-001',
    status: PostStatus.pendingReview,
    title: 'Updated Title',
    text: 'Updated text',
  );

  const changesRequestedData = UpdatedPostData(
    username: 'alice',
    id: 1,
    postUuid: 'post-uuid-001',
    status: PostStatus.changesRequested,
    title: 'Revised Title',
    text: 'Revised body text with enough content to pass validation.',
    revisionMessage: 'Addressed the moderator feedback.',
  );

  const changesRequestedEmptyMsg = UpdatedPostData(
    username: 'alice',
    id: 1,
    postUuid: 'post-uuid-001',
    status: PostStatus.changesRequested,
    title: 'Revised Title',
    text: 'Revised body text with enough content to pass validation.',
  );

  const approvedData = UpdatedPostData(
    username: 'alice',
    id: 1,
    postUuid: 'post-uuid-001',
    status: PostStatus.approved,
    title: 'Approved Title',
    text: 'Approved text',
  );

  setUp(() {
    editPort = _MockEditPostPort();
    revisePort = _MockRevisePostPort();
    authCubit = _MockAuthCubit();
    useCase = EditPostUseCase(editPort, revisePort, authCubit);
    registerFallbackValue(pendingData);
  });

  test(
    'currentUser is null → Left(ForbiddenFailure), port not called',
    () async {
      when(() => authCubit.currentUser).thenReturn(null);

      final result = await useCase(pendingData);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ForbiddenFailure>());
      verifyNever(() => editPort(any()));
      verifyNever(() => revisePort(any()));
    },
  );

  test('username differs from currentUser → '
      'Left(ForbiddenFailure), port not called', () async {
    when(() => authCubit.currentUser).thenReturn(currentUser);

    const otherData = UpdatedPostData(
      username: 'bob',
      id: 1,
      postUuid: 'post-uuid-001',
      status: PostStatus.pendingReview,
      title: 'Title',
      text: 'Text',
    );

    final result = await useCase(otherData);

    expect(result.isLeft(), isTrue);
    expect(result.fold((f) => f, (_) => null), isA<ForbiddenFailure>());
    verifyNever(() => editPort(any()));
    verifyNever(() => revisePort(any()));
  });

  test(
    'pendingReview → delegates to editPort, not revisePort',
    () async {
      when(() => authCubit.currentUser).thenReturn(currentUser);
      when(() => editPort(any())).thenAnswer((_) async => const Right(null));

      final result = await useCase(pendingData);

      expect(result, const Right<Failure, void>(null));
      verify(() => editPort(pendingData)).called(1);
      verifyNever(() => revisePort(any()));
    },
  );

  test(
    'changesRequested + empty revisionMessage → '
    'Left(ValidationFailure), neither port called',
    () async {
      when(() => authCubit.currentUser).thenReturn(currentUser);

      final result = await useCase(changesRequestedEmptyMsg);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<FieldValidationFailure>());
      verifyNever(() => editPort(any()));
      verifyNever(() => revisePort(any()));
    },
  );

  test(
    'changesRequested + non-empty revisionMessage → '
    'calls revisePort, not editPort',
    () async {
      when(() => authCubit.currentUser).thenReturn(currentUser);
      when(
        () => revisePort(any()),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(changesRequestedData);

      expect(result, const Right<Failure, void>(null));
      verify(() => revisePort(changesRequestedData)).called(1);
      verifyNever(() => editPort(any()));
    },
  );

  test(
    'approved → delegates to editPort '
    '(UI disables button; use-case does not block)',
    () async {
      when(() => authCubit.currentUser).thenReturn(currentUser);
      when(() => editPort(any())).thenAnswer((_) async => const Right(null));

      final result = await useCase(approvedData);

      expect(result, const Right<Failure, void>(null));
      verify(() => editPort(approvedData)).called(1);
      verifyNever(() => revisePort(any()));
    },
  );

  test(
    'adapter failure propagates unchanged',
    () async {
      when(() => authCubit.currentUser).thenReturn(currentUser);
      when(
        () => editPort(any()),
      ).thenAnswer((_) async => const Left(Failure.network()));

      final result = await useCase(pendingData);

      expect(result, const Left<Failure, void>(Failure.network()));
    },
  );
}
