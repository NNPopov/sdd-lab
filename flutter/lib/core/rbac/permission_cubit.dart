import 'dart:async';

import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/role.dart';
import 'package:flutter_application_1/core/rbac/role_policy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PermissionCubit extends Cubit<Set<Permission>> {
  PermissionCubit(this._auth) : super(kRolePolicy[UserRole.guest]!) {
    _sub = _auth.stream.listen(_onAuthState);
    _onAuthState(_auth.state);
  }

  final AuthCubit _auth;
  late final StreamSubscription<AuthState> _sub;

  void _onAuthState(AuthState state) {
    final permissions = switch (state) {
      AuthAuthenticated(:final currentUser)
          when currentUser?.isSuperuser == true =>
        kRolePolicy[UserRole.admin]!,
      AuthAuthenticated(:final currentUser)
          when currentUser?.isModerator == true =>
        {...kRolePolicy[UserRole.user]!, Permission.moderatePosts},
      AuthAuthenticated(:final currentUser) when currentUser != null =>
        kRolePolicy[UserRole.user]!,
      _ => kRolePolicy[UserRole.guest]!,
    };
    emit(Set.unmodifiable(permissions));
  }

  bool has(Permission permission) => state.contains(permission);

  @override
  Future<void> close() {
    unawaited(_sub.cancel());
    return super.close();
  }
}
