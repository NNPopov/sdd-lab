# 0011 · edit_tier — Requirements

## Functional requirements

| # | Requirement |
|---|---|
| F1 | A superuser can rename a tier via a form |
| F2 | The edit button is visible in the `tier_details` AppBar only if `currentUser.isSuperuser == true` |
| F3 | The form contains one field — the new tier name, pre-populated with the current name |
| F4 | After a successful rename a snackbar "Tier updated" is shown |
| F5 | After a successful rename the user is navigated to `tier_details` with the new name |
| F6 | If the tier is not found (404) — the appropriate error is shown |
| F7 | A non-superuser who bypassed the UI receives `PermissionDenied` from the use-case |

## Non-functional requirements

| # | Requirement |
|---|---|
| N1 | The Save button is disabled while the request is in progress |
| N2 | Access to the `/tier/:name/edit` route is protected by `AuthGuard` + `PermissionGuard({Permission.manageTiers})` |
| N3 | The adapter uses two-level catch per §8.4 CLAUDE.md |
| N4 | All UI strings — via slang (no hardcoded strings) |

## API contract

```
PATCH /api/v1/tier/{name}
Authorization: Bearer <token>
Content-Type: application/json
Body: {"name": "<new_name>"}

200 OK:  {"message": "Tier updated"}
404:     {"error": {"code": "notfound", "message": "Tier not found"}}
```

The server does not document 403, but the client must protect itself via the use-case.
