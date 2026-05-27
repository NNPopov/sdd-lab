# 0055 · migrate_create_post_route_username_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test Postgres running (`docker compose up test-db -d`).
- At least two registered users whose integer `id`s you know. The scripts
  `create_first_superuser` and `create_first_tier` must have been run once.
- A valid Bearer token for each user, obtained via `POST /api/v1/login`.

Placeholders used below:

- `$USER_ID` — integer primary key of the authenticated author.
- `$USERNAME` — that author's `username` string (used only to demonstrate the
  old route is gone).
- `$OTHER_ID` — integer primary key of a different registered user.
- `$TOKEN_OWNER` — JWT for the author (`$USER_ID`).
- `$UNKNOWN_ID` — an integer matching no user (e.g. `999999`).

---

## Manual scenarios

### S1 — Happy path: create a post under your own integer ID

**Steps:**

1. Log in as the author to obtain `$TOKEN_OWNER`.
2. Send:
   ```
   curl -i -X POST http://localhost:8000/api/v1/$USER_ID/post \
     -H "Authorization: Bearer $TOKEN_OWNER" \
     -H "Content-Type: application/json" \
     -d '{"title": "Hello", "text": "First post", "media_url": null}'
   ```

**Expected:**

- Status 201.
- Body matches `CreatePostResponse`: `created_by_user_id == $USER_ID`,
  `status == "pending_review"`, `id` set, `post_uuid` set, `created_at` set.
- Body has **no** `username` field.

**Covers:** F1, F2, F3, F14.

---

### S2 — Forbidden: create a post under another user's ID

**Steps:**

1. As the same author (`$TOKEN_OWNER`), target a different user's ID:
   ```
   curl -i -X POST http://localhost:8000/api/v1/$OTHER_ID/post \
     -H "Authorization: Bearer $TOKEN_OWNER" \
     -H "Content-Type: application/json" \
     -d '{"title": "Hi", "text": "Body", "media_url": null}'
   ```

**Expected:**

- Status 403.
- Body carries no ownership-specific message (bare `ForbiddenDomainError()`):
  `{"error": {"code": "forbidden", "message": ""}}` (or the project's empty/default 403 body) — the old "You can only post under your own username" text is gone.

**Covers:** F7, F18.

---

### S3 — Not found: create a post for an unknown user_id

**Steps:**

1. Send (authenticated) to an id matching no user:
   ```
   curl -i -X POST http://localhost:8000/api/v1/$UNKNOWN_ID/post \
     -H "Authorization: Bearer $TOKEN_OWNER" \
     -H "Content-Type: application/json" \
     -d '{"title": "Hi", "text": "Body", "media_url": null}'
   ```

**Expected:**

- Status 404 (returned before any ownership check).
- Body `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F6, F8.

---

### S4 — Unauthenticated → 401

**Steps:**

1. Send without an `Authorization` header:
   ```
   curl -i -X POST http://localhost:8000/api/v1/$USER_ID/post \
     -H "Content-Type: application/json" \
     -d '{"title": "Hi", "text": "Body", "media_url": null}'
   ```

**Expected:**

- Status 401. The use-case is never reached.

**Covers:** F5.

---

### S5 — Non-integer user_id → 422 (old string route is gone)

**Steps:**

1. Send with the author's username string instead of the ID:
   ```
   curl -i -X POST http://localhost:8000/api/v1/$USERNAME/post \
     -H "Authorization: Bearer $TOKEN_OWNER" \
     -H "Content-Type: application/json" \
     -d '{"title": "Hi", "text": "Body", "media_url": null}'
   ```

**Expected:**

- Status 422.
- Body contains a `detail` array reporting that the path value is not a valid
  integer.

**Covers:** F10, F11.

---

### S6 — Invalid body → 422

**Steps:**

1. Send (authenticated) with a title that exceeds 30 chars or an extra field:
   ```
   curl -i -X POST http://localhost:8000/api/v1/$USER_ID/post \
     -H "Authorization: Bearer $TOKEN_OWNER" \
     -H "Content-Type: application/json" \
     -d '{"title": "", "text": "Body", "media_url": null, "rogue": 1}'
   ```

**Expected:**

- Status 422 (empty title violates `min_length=1`; `rogue` violates `extra="forbid"`).

**Covers:** F4.

---

### S7 — erase_post still works (cross-slice regression)

**Steps:**

1. Create a post via S1; note its `id` as `$POST_ID`.
2. As the owner, delete it via the **unchanged** username route:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USERNAME/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OWNER"
   ```

**Expected:**

- Status 200, `{"message": "Post deleted"}`. The `erase_post` route, cache keys,
  and target lookup are unchanged; only its internal ownership check is now id-based.

**Covers:** F19, F20.

---

## Code review checklist

### Architecture

- [ ] `create_post` slice files were modified **in place**; no new `src/app` slice folder was created for 0055.
- [ ] `CreatePostUseCase` is still a class with `__call__(command: CreatePostCommand) -> CreatedPost`; only the lookup, ownership, and imports changed.
- [ ] `CreatePostPort` lives in `domain/ports/create_post_port.py`, carries `@runtime_checkable`, inherits `Protocol`, and its `create(command)` signature is unchanged.
- [ ] `CreatePostAdapter` class signature is `class CreatePostAdapter(CreatePostPort):` — explicit inheritance retained; the adapter file is unchanged.
- [ ] `UserLookupAdapter` is `class UserLookupAdapter(UserLookupPort):`; `UserLookupPort` carries `@runtime_checkable` and inherits `Protocol`.
- [ ] Adapters are the only files using SQLAlchemy directly; `domain/`, `presentation/`, and `_shared/policies.py` have no ORM imports.
- [ ] Router accepts `user_id: int` from the path, builds `CreatePostCommand`, awaits the use-case, returns `CreatePostResponse`.
- [ ] No cross-slice imports outside `features/posts/_shared/`; `create_post` imports `check_post_owner` and `UserLookupPort` from `posts/_shared` only.
- [ ] All imports inside `src/app/` are **relative**; no `from app…` / `from src.app…` in source.
- [ ] No `HTTPException` raised inside the use-case, adapter, policy, or lookup.

### Migration correctness

- [ ] `CreatePostCommand` has `target_user_id: int` and `requester_user_id: int`; `target_username` and `requester_username` are gone. `title`, `text`, `media_url` unchanged.
- [ ] `CreatePostInternalCommand` and `CreatePostAdapter` are unchanged.
- [ ] Use-case calls `get_active_user_by_id(command.target_user_id)`, raises `NotFoundDomainError("User not found")` on `None`, then `check_post_owner(command.requester_user_id, author.id)`, then builds the internal command with `created_by_user_id=author.id` — 404-before-403 ordering preserved.
- [ ] The inline username comparison and the "You can only post under your own username" message are removed; `ForbiddenDomainError` is no longer imported by the use-case.
- [ ] Router path is `"/{user_id}/post"`; command is built with `target_user_id=user_id`, `requester_user_id=current_user["id"]`. No `@cache` decorator was added.
- [ ] `CreatePostResponse` / `CreatePostRequest` fields are unchanged from 0011.

### Shared-module evolution

- [ ] `UserLookupPort` declares **both** `get_active_user_by_username` and the new `get_active_user_by_id`; neither is removed.
- [ ] `UserLookupAdapter.get_active_user_by_id` filters `User.id == user_id` and `User.is_deleted.is_(False)`, uses `scalar_one_or_none()`, and maps to `UserIdentity`; the username method is unchanged.
- [ ] `check_post_owner(requester_user_id: int, owner_user_id: int)` compares ints and raises a bare `ForbiddenDomainError()`; no message; no username parameter remains.

### Cross-slice (erase_post kept green)

- [ ] `ErasePostCommand` has `requester_user_id: int` (was `requester_username: str`); `username` and `post_id` unchanged.
- [ ] `erase_post` use-case calls `check_post_owner(command.requester_user_id, user.id)`.
- [ ] `erase_post` router passes `requester_user_id=current_user["id"]`.
- [ ] `erase_post` route path (`/{username}/post/{id}`), cache keys, and `get_active_user_by_username(command.username)` target lookup are **unchanged**.

### Error handling

- [ ] No new `DomainError` subclass was added; only `NotFoundDomainError` and `ForbiddenDomainError` (existing STABLE subclasses) are raised.
- [ ] `UserLookupAdapter.get_active_user_by_id` has **no `try/except`** (read-only query).
- [ ] No adapter or policy logs exceptions.

### Files and headers

- [ ] Every modified `.py` file keeps its `# FEATURE: <slice> — …` header on line 1.
- [ ] No STABLE file was modified (no `bootstrap/container.py`, `bootstrap/router.py`, or `.importlinter` change was needed; confirm none was made).

### DI

- [ ] `bootstrap/container.py` `create_post_adapter`, `create_post_use_case`, and `user_lookup_adapter` providers are unchanged.
- [ ] `Container.wiring_config.modules` still includes the `create_post` router module.
- [ ] Endpoint still uses `Annotated[CreatePostUseCase, Depends(Provide[Container.create_post_use_case])]`.

### Tests

- [ ] Use-case unit test at `tests/features/posts/0055_…/domain/test_use_case.py` passes (happy path owner, user not found, not owner; create port not called on the two error branches).
- [ ] Shared adapter unit test in `tests/features/posts/0032_extract_user_lookup/` covers `get_active_user_by_id` (found, unknown id, soft-deleted).
- [ ] Endpoint integration test at `tests/features/posts/0055_…/presentation/test_router.py` passes (201 owner, 403 non-owner, 404 unknown user, 401 unauthenticated, 422 non-integer, old route gone).
- [ ] Outside-in test `tests/features/posts/0055_…/migrate_create_post_route_username_to_user_id_outside_in_test.py` is GREEN.
- [ ] The old `tests/features/posts/0011_create_post/` tests were updated to the integer route and id-based command (or explicitly superseded) and the whole suite is green.
- [ ] The `erase_post` use-case unit test was updated to the id-based ownership check and passes; the `erase_post` endpoint/outside-in tests are unchanged and still green.
- [ ] Full-suite baseline before and after shows zero net-new failures (user memory `project_route_migration_downstream_tests`).
- [ ] `conftest.py` savepoint-mode rollback works; no test leaves rows in the DB.

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest                       # includes tests/smoke/test_app_starts.py
```

Plus the architecture gate (import-linter via `.importlinter`, run from `api/src` with UTF-8 / `lint-imports`).

All must pass. No `alembic` step is needed — `Post.created_by_user_id` already exists. If `tests/smoke/test_app_starts.py` fails after editing the router's relative imports, an import is using the wrong convention for its layer.
