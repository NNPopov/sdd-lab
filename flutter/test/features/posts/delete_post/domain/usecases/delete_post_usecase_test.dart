import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/delete_post/domain/ports/delete_post_port.dart';
import 'package:flutter_application_1/features/posts/delete_post/domain/usecases/delete_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeletePostPort extends Mock implements DeletePostPort {}

class _MockAuthCubit extends Mock implements AuthCubit {}

const _alice = CurrentUser(
  id: 1,
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

const _bob = CurrentUser(
  id: 1,
  username: 'bob',
  email: 'bob@example.com',
  name: 'Bob',
  isSuperuser: false,
  isModerator: false,
);

void main() {
  late _MockDeletePostPort port;
  late _MockAuthCubit authCubit;
  late DeletePostUseCase useCase;

  const username = 'alice';
  const postId = 42;

  setUp(() {
    port = _MockDeletePostPort();
    authCubit = _MockAuthCubit();
    useCase = DeletePostUseCase(port, authCubit);
  });

  const forbidden = Left<Failure, Unit>(
    Failure.forbidden(message: "Cannot delete another user's post"),
  );

  group('ownership enforcement', () {
    test(
      'returns ForbiddenFailure without calling port when currentUser is null',
      () async {
        when(() => authCubit.currentUser).thenReturn(null);

        final result = await useCase(username, postId);

        expect(result, forbidden);
        verifyNever(() => port(any(), any()));
      },
    );

    test(
      'returns ForbiddenFailure without calling port when username differs',
      () async {
        when(() => authCubit.currentUser).thenReturn(_bob);

        final result = await useCase(username, postId);

        expect(result, forbidden);
        verifyNever(() => port(any(), any()));
      },
    );

    test(
      'delegates to port when username matches currentUser',
      () async {
        when(() => authCubit.currentUser).thenReturn(_alice);
        when(
          () => port(username, postId),
        ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

        final result = await useCase(username, postId);

        expect(result, const Right<Failure, Unit>(unit));
        verify(() => port(username, postId)).called(1);
      },
    );
  });
}
