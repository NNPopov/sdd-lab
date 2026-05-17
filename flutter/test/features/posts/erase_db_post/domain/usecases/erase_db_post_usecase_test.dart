import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/domain/ports/erase_db_post_port.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/domain/usecases/erase_db_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEraseDbPostPort extends Mock implements EraseDbPostPort {}

void main() {
  late _MockEraseDbPostPort port;
  late EraseDbPostUseCase useCase;

  const username = 'alice';
  const postId = 42;

  setUp(() {
    port = _MockEraseDbPostPort();
    useCase = EraseDbPostUseCase(port);
  });

  group('EraseDbPostUseCase', () {
    test(
      'returns Left(PermissionDenied) and does NOT call port '
      'when isSuperuser is false',
      () async {
        final result = await useCase(
          username: username,
          id: postId,
          isSuperuser: false,
        );

        expect(
          result,
          const Left<Failure, Unit>(Failure.permissionDenied()),
        );
        verifyNever(() => port(any(), any()));
      },
    );

    test(
      'delegates to port and returns Right(unit) '
      'when isSuperuser is true and port succeeds',
      () async {
        when(
          () => port(username, postId),
        ).thenAnswer((_) async => const Right(unit));

        final result = await useCase(
          username: username,
          id: postId,
          isSuperuser: true,
        );

        expect(result, const Right<Failure, Unit>(unit));
        verify(() => port(username, postId)).called(1);
      },
    );

    test(
      'returns Left(NotFoundFailure) when isSuperuser is true '
      'and port returns NotFoundFailure',
      () async {
        when(
          () => port(username, postId),
        ).thenAnswer(
          (_) async => const Left(Failure.notFound(message: 'Post not found')),
        );

        final result = await useCase(
          username: username,
          id: postId,
          isSuperuser: true,
        );

        result.fold(
          (f) => expect(f, isA<NotFoundFailure>()),
          (_) => fail('expected Left'),
        );
      },
    );
  });
}
