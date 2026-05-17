import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_cubit.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_state.dart';
import 'package:flutter_application_1/features/users/create_user/domain/entities/new_user_data.dart';
import 'package:flutter_application_1/features/users/create_user/domain/usecases/create_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateUserUseCase extends Mock implements CreateUserUseCase {}

void main() {
  group('CreateUserCubit', () {
    late _MockCreateUserUseCase useCase;

    const data = NewUserData(
      name: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
      password: 'Password1!',
    );

    const user = User(
      id: 1,
      name: 'Test User',
      username: 'testuser',
      email: 'test@example.com',
      isModerator: false,
    );

    setUpAll(() {
      registerFallbackValue(data);
    });

    setUp(() {
      useCase = _MockCreateUserUseCase();
    });

    blocTest<CreateUserCubit, CreateUserState>(
      'emits [submitting, success] on successful create',
      build: () {
        when(() => useCase(any())).thenAnswer((_) async => const Right(user));
        return CreateUserCubit(useCase);
      },
      act: (cubit) => cubit.submit(data),
      expect: () => [
        const CreateUserState.submitting(),
        const CreateUserState.success(user),
      ],
    );

    blocTest<CreateUserCubit, CreateUserState>(
      'emits [submitting, failure] with ConflictFailure on 409',
      build: () {
        const failure = Failure.conflict(message: 'Username already taken');
        when(() => useCase(any())).thenAnswer((_) async => const Left(failure));
        return CreateUserCubit(useCase);
      },
      act: (cubit) => cubit.submit(data),
      expect: () => [
        const CreateUserState.submitting(),
        const CreateUserState.failure(
          Failure.conflict(message: 'Username already taken'),
        ),
      ],
    );
  });
}
