# Requirements: erase_db_user

## Context

Hard delete of an account — irreversible removal of a user from the database.
Differs from `delete_user` (`/user/{username}`) in that database records are completely erased,
not marked as deleted. The endpoint has the same side effect: the server blacklists the token.

## User story

> As an authenticated user viewing my own profile,
> I want to irreversibly delete my account from the database,
> so that my data is completely erased.

## Functional requirements

| # | Requirement |
|---|---|
| F-01 | ~~Button "Erase from DB" is shown only for `isMe == true`~~ → **Revised in [0003](../../0003_permission_gated_buttons/requirements.md)**: button is shown only for superusers (`Permission.eraseUsers`) |
| F-02 | Before deletion, a confirmation dialog is shown with an explicit warning about irreversibility |
| F-03 | After confirmation, `DELETE /api/v1/db_user/{username}` is called |
| F-04 | On success — local `forceLogout(notifyUser: false)` + `replaceAll([UsersRoute()])` + snackbar |
| F-05 | On dialog dismissal (Cancel) — return to `initial` without a request |
| F-06 | During the request the button is disabled, `CircularProgressIndicator` is shown |
| F-07 | On 403/401/404 error — snackbar with a localized message |
| F-08 | New method `eraseDbUser(username)` is added to `UsersApiClient` (`_shared/data/`) |

## Non-functional requirements

| # | Requirement |
|---|---|
| NF-01 | The adapter must have a two-level catch (§8.4 CLAUDE.md) |
| NF-02 | All UI strings — via slang, new keys under `users.eraseDbUser.*` |
| NF-03 | The slice does not import `delete_user` and does not depend on it |
| NF-04 | ~~Use-case checks via implicit mechanism~~ → **Revised in [0003](../../0003_permission_gated_buttons/requirements.md)**: use-case explicitly accepts `isSuperuser: bool` and returns `Left(PermissionDenied())` if `!isSuperuser` |

## Out of scope

- Button in `list_users` — not needed
- Separate route / screen — slice has no route, only a widget
- Admin deletion of other users' accounts — not implemented in this slice
- Cancelling the operation after the request has been sent
