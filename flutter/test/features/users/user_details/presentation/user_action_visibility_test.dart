import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/features/users/user_details/presentation/user_action_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

const _alice = CurrentUser(
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

void main() {
  group('UserActionVisibility.from', () {
    test(
      'eraseUsers permission + viewing other user → showErase only',
      () {
        final v = UserActionVisibility.from(
          {Permission.eraseUsers},
          const AuthState.authenticated(currentUser: _alice),
          'bob',
        );
        expect(v.showErase, isTrue);
        expect(v.showEdit, isFalse);
        expect(v.showDelete, isFalse);
        expect(v.isMe, isFalse);
        expect(v.showAny, isTrue);
      },
    );

    test(
      'no permissions + viewing own profile → showEdit and showDelete',
      () {
        final v = UserActionVisibility.from(
          {},
          const AuthState.authenticated(currentUser: _alice),
          'alice',
        );
        expect(v.showEdit, isTrue);
        expect(v.showDelete, isTrue);
        expect(v.showErase, isFalse);
        expect(v.isMe, isTrue);
        expect(v.showAny, isTrue);
      },
    );

    test(
      'manageModerators + unauthenticated → canManageModerators, not isMe',
      () {
        final v = UserActionVisibility.from(
          {Permission.manageModerators},
          const AuthState.unauthenticated(),
          'alice',
        );
        expect(v.canManageModerators, isTrue);
        expect(v.isMe, isFalse);
        expect(v.showEdit, isFalse);
        expect(v.showAny, isTrue);
      },
    );

    test(
      'editUserTier + eraseUsers + unauthenticated → canEditTier + showErase',
      () {
        final v = UserActionVisibility.from(
          {Permission.editUserTier, Permission.eraseUsers},
          const AuthState.unauthenticated(),
          'x',
        );
        expect(v.canEditTier, isTrue);
        expect(v.showErase, isTrue);
        expect(v.showAny, isTrue);
      },
    );
  });
}
