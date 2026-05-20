import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/auth/infrastructure/auth_guard.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/i18n/locale_cubit.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_cubit.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_state.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_state.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_cubit.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_state.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_state.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_cubit.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockLocaleCubit extends MockCubit<AppLocale> implements LocaleCubit {}

class _MockUsersListCubit extends MockCubit<UsersListState>
    implements UsersListCubit {}

class _MockUserDetailsCubit extends MockCubit<UserDetailsState>
    implements UserDetailsCubit {}

class _MockGetUserTierCubit extends MockCubit<GetUserTierState>
    implements GetUserTierCubit {}

class _MockUpdateUserTierCubit extends MockCubit<UpdateUserTierState>
    implements UpdateUserTierCubit {}

class _MockDeleteUserCubit extends MockCubit<DeleteUserState>
    implements DeleteUserCubit {}

// AuthGuard subclass that always allows navigation.
class _PermissiveAuthGuard extends AuthGuard {
  _PermissiveAuthGuard(AuthCubit auth) : super(auth);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      resolver.next();
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _alice = CurrentUser(
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

// ---------------------------------------------------------------------------
// App builder (mirrors the pattern in app_shell_screen_test.dart)
// ---------------------------------------------------------------------------

Widget _buildApp({
  required _MockAuthCubit authCubit,
  required PermissionCubit permCubit,
}) {
  final localeCubit = _MockLocaleCubit();
  whenListen(
    localeCubit,
    const Stream<AppLocale>.empty(),
    initialState: AppLocale.enUs,
  );

  final router = AppRouter(
    authGuard: _PermissiveAuthGuard(authCubit),
    permissionCubit: permCubit,
  );

  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<PermissionCubit>.value(value: permCubit),
      BlocProvider<LocaleCubit>.value(value: localeCubit),
    ],
    child: TranslationProvider(
      child: MaterialApp.router(routerConfig: router.config()),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockAuthCubit authCubit;
  late PermissionCubit permCubit;
  late StreamController<AuthState> authStateCtrl;

  setUp(() {
    authStateCtrl = StreamController<AuthState>.broadcast();

    authCubit = _MockAuthCubit();
    when(() => authCubit.stream).thenAnswer((_) => authStateCtrl.stream);
    when(() => authCubit.state).thenReturn(
      const AuthState.authenticated(currentUser: _alice),
    );
    // logout is not expected to be called in these scenarios; no stub needed
    // but declare it mockable for verifyNever
    when(authCubit.logout).thenAnswer((_) async {});

    permCubit = PermissionCubit(authCubit);

    // Stub cubits that are resolved via getIt by destination pages.

    final usersListCubit = _MockUsersListCubit();
    when(() => usersListCubit.stream)
        .thenAnswer((_) => const Stream.empty());
    when(() => usersListCubit.state)
        .thenReturn(const UsersListState.initial());
    when(usersListCubit.fetchUsers).thenAnswer((_) async {});

    final userDetailsCubit = _MockUserDetailsCubit();
    when(() => userDetailsCubit.stream)
        .thenAnswer((_) => const Stream.empty());
    when(() => userDetailsCubit.state)
        .thenReturn(const UserDetailsState.initial());
    when(() => userDetailsCubit.load(any())).thenAnswer((_) async {});
    when(() => userDetailsCubit.retry(any())).thenAnswer((_) async {});

    final getUserTierCubit = _MockGetUserTierCubit();
    when(() => getUserTierCubit.stream)
        .thenAnswer((_) => const Stream.empty());
    when(() => getUserTierCubit.state)
        .thenReturn(const GetUserTierState.initial());
    when(() => getUserTierCubit.load(any())).thenAnswer((_) async {});

    final updateUserTierCubit = _MockUpdateUserTierCubit();
    when(() => updateUserTierCubit.stream)
        .thenAnswer((_) => const Stream.empty());
    when(() => updateUserTierCubit.state)
        .thenReturn(const UpdateUserTierState.initial());

    final deleteUserCubit = _MockDeleteUserCubit();
    when(() => deleteUserCubit.stream)
        .thenAnswer((_) => const Stream.empty());
    when(() => deleteUserCubit.state)
        .thenReturn(const DeleteUserState.initial());
    when(deleteUserCubit.requestConfirmation).thenReturn(null);

    getIt
      ..registerFactory<UsersListCubit>(() => usersListCubit)
      ..registerFactory<UserDetailsCubit>(() => userDetailsCubit)
      ..registerFactory<GetUserTierCubit>(() => getUserTierCubit)
      ..registerFactory<UpdateUserTierCubit>(() => updateUserTierCubit)
      ..registerFactory<DeleteUserCubit>(() => deleteUserCubit);
  });

  tearDown(() async {
    await authStateCtrl.close();
    await authCubit.close();
    await permCubit.close();
    await getIt.reset();
  });

  group('user_header_menu outside-in', () {
    testWidgets(
      'Scenario 1: opening the menu and navigating to My Profile',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(authCubit: authCubit, permCubit: permCubit),
        );
        await tester.pumpAndSettle();

        // Username appears in the AppBar.
        expect(find.text('alice'), findsWidgets);

        // Tap the username to open the popup menu.
        await tester.tap(find.text('alice').first);
        await tester.pumpAndSettle();

        // All three menu items are visible after the popup opens.
        expect(find.text('My Profile'), findsOneWidget);
        expect(find.text('My Posts'), findsOneWidget);
        expect(find.text('Sign out'), findsOneWidget);

        // The standalone logout icon button is gone.
        expect(find.byIcon(Icons.logout), findsNothing);

        // Tap My Profile.
        await tester.tap(find.text('My Profile'));
        await tester.pumpAndSettle();

        // UserDetailsScreen is rendered: its AppBar auto-implies a BackButton
        // because it was pushed as a nested route onto the tab's inner stack.
        expect(find.byType(BackButton), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 2: tapping Sign out opens the confirmation dialog',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(authCubit: authCubit, permCubit: permCubit),
        );
        await tester.pumpAndSettle();

        // Tap the username to open the popup menu.
        await tester.tap(find.text('alice').first);
        await tester.pumpAndSettle();

        // Sign out item is present in the open popup.
        expect(find.text('Sign out'), findsOneWidget);

        // Tap Sign out.
        await tester.tap(find.text('Sign out'));
        await tester.pumpAndSettle();

        // Confirmation dialog appeared.
        expect(find.byType(AlertDialog), findsOneWidget);

        // AuthCubit.logout was NOT called — user must confirm in the dialog first.
        verifyNever(authCubit.logout);
      },
    );
  });
}
