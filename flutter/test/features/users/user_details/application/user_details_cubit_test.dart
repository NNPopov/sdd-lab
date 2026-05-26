import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_cubit.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_state.dart';
import 'package:flutter_application_1/features/users/user_details/domain/usecases/get_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetUserUseCase extends Mock implements GetUserUseCase {}

const _user = User(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
  isModerator: false,
);

void main() {
  group('UserDetailsCubit', () {
    late _MockGetUserUseCase useCase;
    late UserDetailsCubit cubit;

    setUp(() {
      useCase = _MockGetUserUseCase();
      cubit = UserDetailsCubit(useCase);
    });

    tearDown(() => cubit.close());

    blocTest<UserDetailsCubit, UserDetailsState>(
      'load emits [loading, loaded] on success',
      build: () {
        when(
          () => useCase(1),
        ).thenAnswer((_) async => const Right(_user));
        return cubit;
      },
      act: (c) => c.load(1),
      expect: () => [
        const UserDetailsState.loading(),
        const UserDetailsState.loaded(_user),
      ],
    );

    blocTest<UserDetailsCubit, UserDetailsState>(
      'load emits [loading, error(NotFoundFailure)] on 404',
      build: () {
        when(() => useCase(2)).thenAnswer(
          (_) async => const Left(Failure.notFound(message: 'User not found')),
        );
        return cubit;
      },
      act: (c) => c.load(2),
      expect: () => [
        const UserDetailsState.loading(),
        const UserDetailsState.error(
          Failure.notFound(message: 'User not found'),
        ),
      ],
    );

    blocTest<UserDetailsCubit, UserDetailsState>(
      'load emits [loading, error(NetworkFailure)] on network error',
      build: () {
        when(() => useCase(1)).thenAnswer(
          (_) async => const Left(Failure.network(message: 'timeout')),
        );
        return cubit;
      },
      act: (c) => c.load(1),
      expect: () => [
        const UserDetailsState.loading(),
        const UserDetailsState.error(Failure.network(message: 'timeout')),
      ],
    );

    blocTest<UserDetailsCubit, UserDetailsState>(
      'retry delegates to load',
      build: () {
        when(
          () => useCase(1),
        ).thenAnswer((_) async => const Right(_user));
        return cubit;
      },
      act: (c) => c.retry(1),
      expect: () => [
        const UserDetailsState.loading(),
        const UserDetailsState.loaded(_user),
      ],
    );

    blocTest<UserDetailsCubit, UserDetailsState>(
      'updateIsModerator from loaded emits updated user',
      build: () => cubit,
      seed: () => const UserDetailsState.loaded(_user),
      act: (c) => c.updateIsModerator(true),
      expect: () => [
        UserDetailsState.loaded(_user.copyWith(isModerator: true)),
      ],
    );

    blocTest<UserDetailsCubit, UserDetailsState>(
      'updateIsModerator when not loaded emits nothing',
      build: () => cubit,
      act: (c) => c.updateIsModerator(true),
      expect: () => <UserDetailsState>[],
    );
  });
}
