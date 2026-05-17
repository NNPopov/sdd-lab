import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
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

class _MockStackRouter extends Mock implements StackRouter {}

class _FakePageRouteInfo extends Fake implements PageRouteInfo<dynamic> {}

const _user = User(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
  isModerator: false,
);

const _meAlice = CurrentUser(
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

const _meBob = CurrentUser(
  username: 'bob',
  email: 'bob@example.com',
  name: 'Bob',
  isSuperuser: false,
  isModerator: false,
);

Widget _wrap({
  required Widget child,
  required UserDetailsCubit detailsCubit,
  required AuthCubit authCubit,
  required PermissionCubit permissionCubit,
  required GetUserTierCubit tierCubit,
  required UpdateUserTierCubit updateTierCubit,
  StackRouter? router,
}) {
  final providers = MultiBlocProvider(
    providers: [
      BlocProvider<UserDetailsCubit>.value(value: detailsCubit),
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<PermissionCubit>.value(value: permissionCubit),
      BlocProvider<GetUserTierCubit>.value(value: tierCubit),
      BlocProvider<UpdateUserTierCubit>.value(value: updateTierCubit),
    ],
    child: child,
  );

  final app = MaterialApp(home: providers);

  if (router != null) {
    return TranslationProvider(
      child: StackRouterScope(
        controller: router,
        stateHash: 0,
        child: app,
      ),
    );
  }
  return TranslationProvider(child: app);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePageRouteInfo());
  });

  group('UserDetailsScreen — Edit button visibility', () {
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
      when(
        () => permissionCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(() => tierCubit.stream).thenAnswer((_) => const Stream.empty());
      when(
        () => updateTierCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => deleteUserCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => eraseDbUserCubit.stream,
      ).thenAnswer((_) => const Stream.empty());

      when(() => detailsCubit.load(any())).thenAnswer((_) async {});
      when(
        () => detailsCubit.state,
      ).thenReturn(const UserDetailsState.loaded(_user));
      when(
        () => permissionCubit.state,
      ).thenReturn({Permission.viewCatalog, Permission.viewReports});
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

      // DeleteAccountButton and EraseDbUserButton use getIt to create cubits.
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

    Widget buildScreen() => _wrap(
      child: const UserDetailsScreen(username: 'alice'),
      detailsCubit: detailsCubit,
      authCubit: authCubit,
      permissionCubit: permissionCubit,
      tierCubit: tierCubit,
      updateTierCubit: updateTierCubit,
    );

    testWidgets(
      'Edit and Delete buttons are visible when '
      'currentUser.username == profile username',
      (tester) async {
        when(() => authCubit.state).thenReturn(
          const AuthState.authenticated(currentUser: _meAlice),
        );

        await tester.pumpWidget(buildScreen());

        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      },
    );

    testWidgets(
      'Edit button is hidden when currentUser.username != profile username',
      (tester) async {
        when(() => authCubit.state).thenReturn(
          const AuthState.authenticated(currentUser: _meBob),
        );

        await tester.pumpWidget(buildScreen());

        expect(find.byIcon(Icons.edit), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
      },
    );

    testWidgets(
      'Edit button is hidden when authenticated but currentUser is null',
      (tester) async {
        when(() => authCubit.state).thenReturn(
          const AuthState.authenticated(),
        );

        await tester.pumpWidget(buildScreen());

        expect(find.byIcon(Icons.edit), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
      },
    );

    testWidgets('Edit button is hidden when unauthenticated', (tester) async {
      when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());

      await tester.pumpWidget(buildScreen());

      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });

  group('UserDetailsScreen — Posts navigation', () {
    late _MockUserDetailsCubit detailsCubit;
    late _MockAuthCubit authCubit;
    late _MockPermissionCubit permissionCubit;
    late _MockGetUserTierCubit tierCubit;
    late _MockUpdateUserTierCubit updateTierCubit;
    late _MockDeleteUserCubit deleteUserCubit;
    late _MockEraseDbUserCubit eraseDbUserCubit;
    late _MockStackRouter mockRouter;

    setUp(() {
      detailsCubit = _MockUserDetailsCubit();
      authCubit = _MockAuthCubit();
      permissionCubit = _MockPermissionCubit();
      tierCubit = _MockGetUserTierCubit();
      updateTierCubit = _MockUpdateUserTierCubit();
      deleteUserCubit = _MockDeleteUserCubit();
      eraseDbUserCubit = _MockEraseDbUserCubit();
      mockRouter = _MockStackRouter();

      when(() => detailsCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
      when(
        () => permissionCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(() => tierCubit.stream).thenAnswer((_) => const Stream.empty());
      when(
        () => updateTierCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => deleteUserCubit.stream,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => eraseDbUserCubit.stream,
      ).thenAnswer((_) => const Stream.empty());

      when(() => detailsCubit.load(any())).thenAnswer((_) async {});
      when(
        () => detailsCubit.state,
      ).thenReturn(const UserDetailsState.loaded(_user));
      when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
      when(() => permissionCubit.state).thenReturn({});
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

      when(() => mockRouter.push(any())).thenAnswer((_) async => null);

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

    Widget buildScreen() => _wrap(
      child: const UserDetailsScreen(username: 'alice'),
      detailsCubit: detailsCubit,
      authCubit: authCubit,
      permissionCubit: permissionCubit,
      tierCubit: tierCubit,
      updateTierCubit: updateTierCubit,
      router: mockRouter,
    );

    testWidgets(
      'T-04: Tap Posts button pushes UserPostsRoute with correct username',
      (tester) async {
        await tester.pumpWidget(buildScreen());

        await tester.tap(find.byIcon(Icons.article_outlined));
        await tester.pump();

        final captured = verify(
          () => mockRouter.push(captureAny()),
        ).captured;
        expect(captured.single, isA<UserPostsRoute>());
        final route = captured.single as UserPostsRoute;
        expect(route.args?.username, 'alice');
      },
    );

    testWidgets(
      'T-05: After Posts tap, load() is not called again (fire-and-forget)',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pump();

        await tester.tap(find.byIcon(Icons.article_outlined));
        await tester.pump();

        // initState triggers exactly one load(); no reload after Posts tap
        verify(() => detailsCubit.load('alice')).called(1);
      },
    );
  });
}
