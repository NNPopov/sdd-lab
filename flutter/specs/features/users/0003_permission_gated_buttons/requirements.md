# Requirements: permission_gated_buttons

## Context

After implementing `PermissionCubit` (0002), the `isSuperuser` field became available
from `CurrentUser`. The visibility and usage rules for the Delete and Erase buttons
on the `user_details_screen` must be corrected, and permission checks must be added
at the use-case level per §7 CLAUDE.md.

**Current behavior (before this task):**
- Delete and Erase are shown together for `isMe || canEdit`
- Use-cases do not check permissions — they rely solely on 403 from the server

**Target behavior:**
- Delete: account owner only
- Erase: superuser only (`isSuperuser == true`)
- Use-cases check permissions independently (final line of defense)

---

## User stories

> As a superuser, I want to see an "Erase" button on any profile,
> so that I can hard-delete an account from the database.

> As a regular user viewing my own profile,
> I want to see a "Delete" button only on my own page,
> so that I cannot accidentally delete someone else's account.

> As a regular user with `editUsers` permission viewing another user's profile,
> I should not see a Delete button — only my own account can be deleted.

---

## Functional requirements

| # | Requirement |
|---|---|
| F-01 | `DeleteAccountButton` is displayed **only** if `isMe == true` (account owner) |
| F-02 | `EraseDbUserButton` is displayed **only** if `isSuperuser == true` for the current user (via `Permission.eraseUsers`) |
| F-03 | Edit button (`IconButton`) is displayed if `isMe \|\| canEdit` — unchanged |
| F-04 | `Permission.eraseUsers` is added to the `Permission` enum; it enters the admin policy automatically via `{...Permission.values}` |
| F-05 | `DeleteUserUseCase.call` accepts `currentUsername` and returns `Left(PermissionDenied())` if `username != currentUsername` |
| F-06 | `EraseDbUserUseCase.call` accepts `isSuperuser` and returns `Left(PermissionDenied())` if `!isSuperuser` |
| F-07 | `DeleteUserCubit.confirmAndDelete` passes `currentUsername` from `AuthCubit.currentUser` |
| F-08 | `EraseDbUserCubit.confirmAndDelete` passes `isSuperuser` from `AuthCubit.currentUser` |

## Non-functional requirements

| # | Requirement |
|---|---|
| NF-01 | Ports (`DeleteUserPort`, `EraseDbUserPort`) are NOT changed — permission logic lives in the use-case, not in the adapter |
| NF-02 | Adapters are NOT changed |
| NF-03 | `kRolePolicy` is NOT changed — `admin` gets `eraseUsers` automatically via `{...Permission.values}` |
| NF-04 | `PermissionCubit` is NOT changed |
| NF-05 | Tests for existing use-case calls are updated to the new signatures |

## Out of scope

- Erase button in `list_users` — not needed
- Ability for superuser to soft-delete other accounts — separate decision
- Role matrix for delete (currently only `isMe`, no role)
- Server-side logic changes
