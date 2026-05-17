import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/entities/new_post_data.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/ports/create_post_port.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/usecases/create_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreatePostPort extends Mock implements CreatePostPort {}

class _MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late _MockCreatePostPort port;
  late _MockAuthCubit authCubit;
  late CreatePostUseCase useCase;

  const currentUser = CurrentUser(
    username: 'alice',
    email: 'alice@example.com',
    name: 'Alice',
    isSuperuser: false,
    isModerator: false,
  );

  const longText =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  const data = NewPostData(
    username: 'alice',
    title: 'My Post',
    text: longText,
  );

  setUp(() {
    port = _MockCreatePostPort();
    authCubit = _MockAuthCubit();
    useCase = CreatePostUseCase(port, authCubit);
    registerFallbackValue(data);
  });

  test(
    'username matches currentUser → delegates to port and returns result',
    () async {
      when(() => authCubit.currentUser).thenReturn(currentUser);
      when(() => port(any())).thenAnswer((_) async => const Right(null));

      final result = await useCase(data);

      expect(result, const Right<Failure, void>(null));
      verify(() => port(data)).called(1);
    },
  );

  test('port returns Left(NetworkFailure) → propagates failure', () async {
    when(() => authCubit.currentUser).thenReturn(currentUser);
    when(
      () => port(any()),
    ).thenAnswer((_) async => const Left(Failure.network()));

    final result = await useCase(data);

    expect(result, const Left<Failure, void>(Failure.network()));
  });

  test('username differs from currentUser → '
      'Left(ForbiddenFailure), port not called', () async {
    when(() => authCubit.currentUser).thenReturn(currentUser);

    const otherData = NewPostData(
      username: 'bob',
      title: 'My Post',
      text: longText,
    );

    final result = await useCase(otherData);

    expect(result.isLeft(), isTrue);
    expect(result.fold((f) => f, (_) => null), isA<ForbiddenFailure>());
    verifyNever(() => port(any()));
  });

  test(
    'currentUser is null → Left(ForbiddenFailure), port not called',
    () async {
      when(() => authCubit.currentUser).thenReturn(null);

      final result = await useCase(data);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ForbiddenFailure>());
      verifyNever(() => port(any()));
    },
  );
}
