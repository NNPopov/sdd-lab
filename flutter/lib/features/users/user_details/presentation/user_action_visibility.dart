import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';

final class UserActionVisibility {
  const UserActionVisibility({
    required this.showEdit,
    required this.showDelete,
    required this.showErase,
    required this.canEditTier,
    required this.canManageModerators,
    required this.isMe,
  });

  final bool showEdit;
  final bool showDelete;
  final bool showErase;
  final bool canEditTier;
  final bool canManageModerators;
  final bool isMe;

  bool get showAny =>
      showEdit || showDelete || showErase || canEditTier || canManageModerators;

  factory UserActionVisibility.from(
    Set<Permission> permissions,
    AuthState auth,
    String username,
  ) {
    final currentUsername = auth is AuthAuthenticated
        ? auth.currentUser?.username
        : null;
    final isMe = currentUsername == username;
    return UserActionVisibility(
      isMe: isMe,
      showEdit: isMe,
      showDelete: isMe,
      showErase: permissions.contains(Permission.eraseUsers),
      canEditTier: permissions.contains(Permission.editUserTier),
      canManageModerators: permissions.contains(Permission.manageModerators),
    );
  }
}
