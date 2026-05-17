# Requirements: list_tiers

## Context

The first slice of the new `tiers` feature. Establishes the infrastructure: a route guarded by
`PermissionGuard`, and a skeleton tier management screen. The actual CRUD operations are separate
future slices (`create_tier`, `edit_tier`, `delete_tier`).

Parallel task: implement `PermissionGuard` — a reusable guard for
routes that require specific permissions. Lives in `core/routing/guards/`.

## User story

> As a superuser (`isSuperuser == true`), I want to navigate to the tier management page
> at path `/tiers`, so that I can create, view,
> edit, and delete tiers in the future.

> As a non-superuser, I must not have access to `/tiers` either through the UI or
> directly via the address bar.

## Functional requirements

| # | Requirement |
|---|---|
| F-01 | The `/tiers` route is registered in `AppRouter` and guarded by two guards: `AuthGuard` + `PermissionGuard({Permission.manageTiers})` |
| F-02 | `Permission.manageTiers` is added to `enum Permission` |
| F-03 | A superuser (`isSuperuser == true`) automatically receives `Permission.manageTiers` through the existing `PermissionCubit` mechanism (mapping `isSuperuser → admin → all permissions`) |
| F-04 | When attempting to navigate to `/tiers` without the required permission — navigation is blocked (`resolver.next(false)`) |
| F-05 | `TiersScreen` displays an AppBar with a title and placeholder body (future tier list) |
| F-06 | Navigation buttons to `/tiers` in the UI are **absent** (to be implemented later) |

## Non-functional requirements

| # | Requirement |
|---|---|
| NF-01 | `PermissionGuard` is a plain class, **not `@injectable`**, parameterized with `Set<Permission>` + `PermissionCubit` in the constructor. Instances are created in `AppRouter` |
| NF-02 | `AppRouter` receives `PermissionCubit` in its constructor and creates `PermissionGuard` locally for each route |
| NF-03 | All UI strings — via slang, keys under `tiers.listTiers.*` |
| NF-04 | `TiersScreen` — `StatelessWidget` without a Cubit (no data to load) |
| NF-05 | The `tiers` feature does not import `features/users/` or other features |

## Out of scope

- CRUD operations on tiers (separate slices)
- Tier list with real data
- Navigation button / menu item for navigating to `/tiers`
- 403 handling in `PermissionGuard` (redirect to error page) — `resolver.next(false)` without UI
