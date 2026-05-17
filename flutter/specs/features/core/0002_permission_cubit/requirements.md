# 0002 · PermissionCubit — Requirements

## Context

The server already returns `is_superuser` in the `GET /api/v1/user/me/` response.
The client side (DTO + domain entity) already fully supports this field:
- `CurrentUserDto.isSuperuser` — deserialized from `is_superuser`, `@Default(false)`
- `CurrentUser.isSuperuser` — stored in `AuthAuthenticated.currentUser`

The missing piece is a `PermissionCubit` that translates the `isSuperuser` flag
into a concrete `Set<Permission>` and makes it available in the widget tree.

## Functional Requirements

| # | Requirement |
|---|---|
| F1 | `PermissionCubit` is reactively subscribed to `AuthCubit.stream` and recalculates permissions on every auth state change |
| F2 | If `AuthAuthenticated` and `currentUser.isSuperuser == true` → `Set<Permission>` = `kRolePolicy[UserRole.admin]` (all permissions) |
| F3 | If `AuthAuthenticated` and `currentUser.isSuperuser == false` → `Set<Permission>` = `kRolePolicy[UserRole.user]` |
| F4 | If `AuthUnauthenticated`, `AuthUnknown`, or `currentUser == null` → `Set<Permission>` = `kRolePolicy[UserRole.guest]` |
| F5 | `PermissionCubit` is accessible from any point in the widget tree via `context.read<PermissionCubit>()` |
| F6 | On the `UserDetailsScreen`, the Edit / Delete / EraseDb buttons are visible if `isMe OR has(Permission.editUsers)` |

## Non-functional Requirements

| # | Requirement |
|---|---|
| N1 | `PermissionCubit` is a singleton in DI (`@lazySingleton`) |
| N2 | No dependency from the infrastructure layer on `PermissionCubit` (CLAUDE.md §3 DI rule) |
| N3 | The subscription to `AuthCubit.stream` is cancelled in `close()` |
| N4 | State is a plain value type `Set<Permission>`, without freezed |

## Out of Scope

- Modifying `kRolePolicy` or adding new roles
- `PermissionGuard` for `auto_route`
- `PermissionBuilder` widget (separate scope, if needed)
- Permission checks in use-cases (no mutating operation under guard)
- Modifying DTO or domain entity (already complete)
