import 'dart:async';

import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/rbac/role.dart';
import 'package:flutter_application_1/core/rbac/role_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late _MockAuthCubit mockAuth;
  late StreamController<AuthState> authCtrl;

  const superUser = CurrentUser(
    username: 'admin',
    email: 'admin@example.com',
    name: 'Admin',
    isSuperuser: true,
    isModerator: false,
  );
  const normalUser = CurrentUser(
    username: 'user',
    email: 'user@example.com',
    name: 'User',
    isSuperuser: false,
    isModerator: false,
  );

  setUp(() {
    mockAuth = _MockAuthCubit();
    authCtrl = StreamController<AuthState>.broadcast();
    when(() => mockAuth.stream).thenAnswer((_) => authCtrl.stream);
  });

  tearDown(() async {
    await authCtrl.close();
  });

  PermissionCubit buildCubit(AuthState initialState) {
    when(() => mockAuth.state).thenReturn(initialState);
    return PermissionCubit(mockAuth);
  }

  group('PermissionCubit', () {
    test('a) AuthUnknown → guest permissions', () async {
      final cubit = buildCubit(const AuthUnknown());

      expect(cubit.state, unorderedEquals(kRolePolicy[UserRole.guest]!));

      await cubit.close();
    });

    test('b) superuser → admin permissions, has(editUsers) = true', () async {
      final cubit = buildCubit(const AuthUnknown());

      authCtrl.add(const AuthAuthenticated(currentUser: superUser));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, unorderedEquals(kRolePolicy[UserRole.admin]!));
      expect(cubit.has(Permission.editUsers), isTrue);

      await cubit.close();
    });

    test(
      'c) normal user → user permissions, has(editUsers) = false, '
      'has(viewCatalog) = true',
      () async {
        final cubit = buildCubit(const AuthUnknown());

        authCtrl.add(const AuthAuthenticated(currentUser: normalUser));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, unorderedEquals(kRolePolicy[UserRole.user]!));
        expect(cubit.has(Permission.editUsers), isFalse);
        expect(cubit.has(Permission.viewCatalog), isTrue);

        await cubit.close();
      },
    );

    test(
      'd) logout: Authenticated → Unauthenticated → guest permissions',
      () async {
        final cubit = buildCubit(
          const AuthAuthenticated(currentUser: superUser),
        );

        authCtrl.add(const AuthUnauthenticated());
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, unorderedEquals(kRolePolicy[UserRole.guest]!));

        await cubit.close();
      },
    );

    test(
      'e) AuthAuthenticated(currentUser: null) → guest permissions',
      () async {
        final cubit = buildCubit(const AuthUnknown());

        authCtrl.add(const AuthAuthenticated());
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, unorderedEquals(kRolePolicy[UserRole.guest]!));

        await cubit.close();
      },
    );

    test('close() cancels subscription without exception', () async {
      final cubit = buildCubit(const AuthUnknown());

      await expectLater(cubit.close(), completes);
    });

    test(
      'f) superuser → contains moderatePosts and manageModerators',
      () async {
        final cubit = buildCubit(const AuthUnknown());

        authCtrl.add(const AuthAuthenticated(currentUser: superUser));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.has(Permission.moderatePosts), isTrue);
        expect(cubit.has(Permission.manageModerators), isTrue);

        await cubit.close();
      },
    );

    test(
      'g) moderator (isModerator:true, isSuperuser:false) → '
      'contains moderatePosts, NOT manageModerators',
      () async {
        const moderatorUser = CurrentUser(
          username: 'mod',
          email: 'mod@example.com',
          name: 'Moderator',
          isSuperuser: false,
          isModerator: true,
        );
        final cubit = buildCubit(const AuthUnknown());

        authCtrl.add(const AuthAuthenticated(currentUser: moderatorUser));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.has(Permission.moderatePosts), isTrue);
        expect(cubit.has(Permission.manageModerators), isFalse);

        await cubit.close();
      },
    );

    test(
      'h) regular user → contains neither moderatePosts nor manageModerators',
      () async {
        final cubit = buildCubit(const AuthUnknown());

        authCtrl.add(const AuthAuthenticated(currentUser: normalUser));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.has(Permission.moderatePosts), isFalse);
        expect(cubit.has(Permission.manageModerators), isFalse);

        await cubit.close();
      },
    );
  });
}
