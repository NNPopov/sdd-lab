import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_cubit.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_state.dart';
import 'package:flutter_application_1/features/users/erase_db_user/application/erase_db_user_cubit.dart';
import 'package:flutter_application_1/features/users/erase_db_user/application/erase_db_user_state.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_state.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_state.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_cubit.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_state.dart';
import 'package:flutter_application_1/features/users/user_details/presentation/user_details_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserDetailsCubit extends MockCubit<UserDetailsState>
    implements UserDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockPermissionCubit extends MockCubit<Set<Permission>>
    implements PermissionCubit {}

class _MockDeleteUserCubit extends MockCubit<DeleteUserState>
    implements DeleteUserCubit {}

class _MockEraseDbUserCubit extends MockCubit<EraseDbUserState>
    implements EraseDbUserCubit {}

class _MockGetUserTierCubit extends MockCubit<GetUserTierState>
    implements GetUserTierCubit {}

class _MockUpdateUserTierCubit extends MockCubit<UpdateUserTierState>
    implements UpdateUserTierCubit {}

const _alice = User(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
  isModerator: false,
);

const _currentAlice = CurrentUser(
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

const _currentBob = CurrentUser(
  username: 'bob',
  email: 'bob@example.com',
  name: 'Bob',
  isSuperuser: false,
  isModerator: false,
);

void main() {
  late _MockUserDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockPermissionCubit permissionCubit;
  late _MockGetUserTierCubit tierCubit;
  late _MockUpdateUserTierCubit updateTierCubit;
  late _MockDeleteUserCubit deleteUserCubit;
  late _MockEraseDbUserCubit eraseDbUserCubit;

  setUp(() {
    detailsCubit = _MockUserDetailsCubit();
    authCubit = _MockAuthCubit();
    permissionCubit = _MockPermissionCubit();
    tierCubit = _MockGetUserTierCubit();
    updateTierCubit = _MockUpdateUserTierCubit();
    deleteUserCubit = _MockDeleteUserCubit();
    eraseDbUserCubit = _MockEraseDbUserCubit();

    when(() => detailsCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => permissionCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => tierCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => updateTierCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => deleteUserCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => eraseDbUserCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => detailsCubit.load(any())).thenAnswer((_) async {});
    when(
      () => detailsCubit.state,
    ).thenReturn(const UserDetailsState.loaded(_alice));
    when(() => tierCubit.state).thenReturn(const GetUserTierState.initial());
    when(
      () => updateTierCubit.state,
    ).thenReturn(const UpdateUserTierState.initial());
    when(
      () => deleteUserCubit.state,
    ).thenReturn(const DeleteUserState.initial());
    when(
      () => eraseDbUserCubit.state,
    ).thenReturn(const EraseDbUserState.initial());

    getIt
      ..registerFactory<DeleteUserCubit>(() => deleteUserCubit)
      ..registerFactory<EraseDbUserCubit>(() => eraseDbUserCubit);
  });

  tearDown(() async {
    await detailsCubit.close();
    await authCubit.close();
    await permissionCubit.close();
    await tierCubit.close();
    await updateTierCubit.close();
    await deleteUserCubit.close();
    await eraseDbUserCubit.close();
    await getIt.reset();
  });

  Widget buildScreen() => TranslationProvider(
    child: MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<UserDetailsCubit>.value(value: detailsCubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<PermissionCubit>.value(value: permissionCubit),
          BlocProvider<GetUserTierCubit>.value(value: tierCubit),
          BlocProvider<UpdateUserTierCubit>.value(value: updateTierCubit),
        ],
        child: const UserDetailsScreen(username: 'alice'),
      ),
    ),
  );

  group('0038 · owner_only_user_edit — outside-in', () {
    testWidgets(
      'Scenario 1: non-owner with editUsers permission does not see edit button',
      (tester) async {
        when(() => authCubit.state).thenReturn(
          const AuthState.authenticated(currentUser: _currentBob),
        );
        when(() => permissionCubit.state).thenReturn({Permission.editUsers});

        await tester.pumpWidget(buildScreen());

        expect(find.byIcon(Icons.edit), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
      },
    );

    testWidgets(
      'Scenario 2: owner sees edit button (regression guard)',
      (tester) async {
        when(() => authCubit.state).thenReturn(
          const AuthState.authenticated(currentUser: _currentAlice),
        );
        when(() => permissionCubit.state).thenReturn({Permission.viewCatalog});

        await tester.pumpWidget(buildScreen());

        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      },
    );
  });
}
