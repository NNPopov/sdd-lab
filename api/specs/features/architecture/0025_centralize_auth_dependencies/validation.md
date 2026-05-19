# 0025 · centralize_auth_dependencies — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn src.app.main:app --reload` from the project root.
- Test database running (Docker): `docker compose up test-db -d`.
- Alembic migrations applied: `alembic upgrade head`.
- DB seeded with:
  - One regular user: `alice` / `alice@example.com` / password `Pa$$w0rd123`
  - One superuser: `admin` / `admin@example.com` / password `Admin$$w0rd1`
  - One moderator (non-superuser): `mod` / `mod@example.com` / password `Mod$$w0rd123`
  - One soft-deleted user: `deleted_user` / `deleted@example.com` (row with `is_deleted=True`)
- Bearer tokens at hand (obtained via scenario S1 before running subsequent scenarios).
- `lint-imports` installed (`pip install import-linter`).

---

## Manual scenarios

### S1 — Username-based login (get_current_user via username credential)

**Steps:**

1. POST to login with username:
   ```
   curl -X POST http://localhost:8000/api/v1/login \
     -F "username=alice" -F "password=Pa\$\$w0rd123"
   ```

**Expected:**

- Status 200.
- Body contains `{"access_token": "<jwt>", "token_type": "bearer"}`.
- Save the token as `$TOKEN_ALICE` for use in subsequent scenarios.

**Covers:** F4, F8.

---

### S2 — Email-based login (get_current_user via email credential)

**Steps:**

1. POST to login with email address:
   ```
   curl -X POST http://localhost:8000/api/v1/login \
     -F "username=alice@example.com" -F "password=Pa\$\$w0rd123"
   ```

**Expected:**

- Status 200.
- Body contains a valid `access_token`.
- The returned token is functionally equivalent to the one in S1 (same user).

**Covers:** F3, F8.

---

### S3 — Authenticated endpoint succeeds with valid token (get_current_user happy path)

**Steps:**

1. Using `$TOKEN_ALICE` from S1, create a post as `alice`:
   ```
   curl -X POST http://localhost:8000/api/v1/alice/post \
     -H "Authorization: Bearer $TOKEN_ALICE" \
     -H "Content-Type: application/json" \
     -d '{"title": "Hello", "text": "Test post"}'
   ```

**Expected:**

- Status 201.
- Body includes `id`, `title`, `text`, `author_username: "alice"`.

**Covers:** F6, F7, F8.

---

### S4 — Invalid token rejected (get_current_user raises 401)

**Steps:**

1. Call an authenticated endpoint with a garbage token:
   ```
   curl -X POST http://localhost:8000/api/v1/alice/post \
     -H "Authorization: Bearer not.a.real.token" \
     -H "Content-Type: application/json" \
     -d '{"title": "X", "text": "Y"}'
   ```

**Expected:**

- Status 401.
- Body `{"message": "..."}` (exact message depends on `UnauthorizedException` default).

**Covers:** F6.

---

### S5 — Soft-deleted user cannot authenticate (is_deleted filter)

**Steps:**

1. Attempt to log in as the soft-deleted user:
   ```
   curl -X POST http://localhost:8000/api/v1/login \
     -F "username=deleted_user" -F "password=Pa\$\$w0rd123"
   ```

**Expected:**

- Status 401.
- The login is rejected — `_get_user_by_credential` returns `None` because the WHERE clause includes `is_deleted IS FALSE`.

**Covers:** F1, F5.

---

### S6 — Optional auth: no Authorization header (get_optional_user returns None)

**Steps:**

1. Call a list-posts endpoint for `alice` without any Authorization header:
   ```
   curl http://localhost:8000/api/v1/alice/posts
   ```

**Expected:**

- Status 200.
- Posts returned in `"public"` view (no author-only drafts). The absence of a token is not an error.

**Covers:** F9.

---

### S7 — Optional auth: non-Bearer Authorization header (get_optional_user returns None)

**Steps:**

1. Call the list-posts endpoint with a Basic auth header (wrong scheme):
   ```
   curl http://localhost:8000/api/v1/alice/posts \
     -H "Authorization: Basic dXNlcjpwYXNz"
   ```

**Expected:**

- Status 200.
- Posts returned in `"public"` view. The wrong scheme is silently treated as no auth.

**Covers:** F10.

---

### S8 — Optional auth: invalid token (get_optional_user returns None)

**Steps:**

1. Call the list-posts endpoint with a malformed Bearer token:
   ```
   curl http://localhost:8000/api/v1/alice/posts \
     -H "Authorization: Bearer this.is.garbage"
   ```

**Expected:**

- Status 200.
- Posts returned in `"public"` view. A bad token on an optional-auth endpoint does not produce 401.

**Covers:** F11.

---

### S9 — Optional auth: valid token (get_optional_user returns user dict)

**Steps:**

1. Call the list-posts endpoint with `alice`'s valid token:
   ```
   curl http://localhost:8000/api/v1/alice/posts \
     -H "Authorization: Bearer $TOKEN_ALICE"
   ```

**Expected:**

- Status 200.
- Posts returned in `"author"` view (alice's own posts, including drafts). Confirms `get_optional_user` resolved the user dict and the view logic used it correctly.

**Covers:** F12.

---

### S10 — Superuser-only endpoint blocks regular user (get_current_superuser raises 403)

**Steps:**

1. Using `$TOKEN_ALICE` (a non-superuser), attempt to create a tier:
   ```
   curl -X POST http://localhost:8000/api/v1/tier \
     -H "Authorization: Bearer $TOKEN_ALICE" \
     -H "Content-Type: application/json" \
     -d '{"name": "gold"}'
   ```

**Expected:**

- Status 403.
- Body `{"message": "..."}` (ForbiddenException from `get_current_superuser`).

**Covers:** F13.

---

### S11 — Superuser-only endpoint succeeds for superuser (get_current_superuser happy path)

**Steps:**

1. Obtain a superuser token:
   ```
   curl -X POST http://localhost:8000/api/v1/login \
     -F "username=admin" -F "password=Admin\$\$w0rd1"
   ```
   Save as `$TOKEN_ADMIN`.

2. Create a tier:
   ```
   curl -X POST http://localhost:8000/api/v1/tier \
     -H "Authorization: Bearer $TOKEN_ADMIN" \
     -H "Content-Type: application/json" \
     -d '{"name": "platinum"}'
   ```

**Expected:**

- Status 201.
- Body contains the created tier record.

**Covers:** F13.

---

### S12 — Moderator endpoint blocks non-privileged user (get_current_moderator_or_superuser raises 403)

**Steps:**

1. Using `$TOKEN_ALICE` (not a moderator, not a superuser), call the pending posts endpoint:
   ```
   curl http://localhost:8000/api/v1/posts/pending \
     -H "Authorization: Bearer $TOKEN_ALICE"
   ```

**Expected:**

- Status 403.
- Body `{"message": "..."}` (ForbiddenException from `get_current_moderator_or_superuser`).

**Covers:** F14.

---

### S13 — Moderator endpoint succeeds for moderator (get_current_moderator_or_superuser happy path)

**Steps:**

1. Obtain a moderator token:
   ```
   curl -X POST http://localhost:8000/api/v1/login \
     -F "username=mod" -F "password=Mod\$\$w0rd123"
   ```
   Save as `$TOKEN_MOD`.

2. Call the pending posts endpoint:
   ```
   curl http://localhost:8000/api/v1/posts/pending \
     -H "Authorization: Bearer $TOKEN_MOD"
   ```

**Expected:**

- Status 200.
- Body contains a paginated list of pending posts (may be empty if none exist).

**Covers:** F14.

---

### S14 — Architecture tests pass (VSA independence verified)

**Steps:**

1. From the project root:
   ```
   pytest tests/architecture/ -v
   ```

**Expected:**

- `test_vsa_domains_do_not_import_each_other[posts-users]` — PASSED (previously failing before this slice).
- `test_vsa_domains_do_not_import_each_other[users-posts]` — PASSED.
- All other tests in `tests/architecture/` — PASSED.

**Covers:** F21.

---

### S15 — importlinter contract passes

**Steps:**

1. From `src/`:
   ```
   cd src && lint-imports --config ../.importlinter
   ```

**Expected:**

- Contract `vsa-feature-independence` — KEPT.
- No violations listed.

**Covers:** F22.

---

## Code review checklist

### Architecture and imports

- [ ] `src/app/shared_dependencies.py` contains no import from `features.users` after this change. Verify: `grep -r "features.users" src/app/shared_dependencies.py` — must return no results. (F20)
- [ ] `src/app/features/users/dependencies.py` no longer exists. Verify: `ls src/app/features/users/dependencies.py` — must report "not found". (F16)
- [ ] No re-export shim exists anywhere in `features/users/` that forwards auth symbols to `shared_dependencies`. (N5)
- [ ] All 10 FEATURE router files listed in plan.md § 4 updated their import. Verify: `grep -r "features.users.dependencies" src/app/` — must return no results. (F17)
- [ ] Relative import depths in each router file are correct for that file's location (5 dots for `presentation/` routers, 3 dots for top-level feature routers). (F17)
- [ ] `src/app/bootstrap/factory.py` imports `get_current_superuser` from `..shared_dependencies`, not from `..features.users.dependencies`. (F18)
- [ ] All test files updated: `grep -r "features.users.dependencies" tests/` — must return no results. (F19)
- [ ] All test files that previously imported from `app.features.users.dependencies` now use absolute imports from `app.shared_dependencies` with identical symbol names. (F19, N6)
- [ ] No `from app…` or `from src.app…` absolute imports inside any modified file under `src/app/`. Relative imports only inside source. (N6)

### Implementation correctness

- [ ] `_get_user_by_credential` is private (leading underscore) and not re-exported from `shared_dependencies.py`. (F2)
- [ ] `_get_user_by_credential` branches on `"@" in credential`: email predicate when true, username predicate when false. (F3, F4)
- [ ] Both branches of `_get_user_by_credential` always include `User.is_deleted.is_(False)` in the WHERE clause. (F5)
- [ ] The dict returned by `_get_user_by_credential` contains exactly `{"id", "username", "email", "is_superuser", "is_moderator", "tier_id"}`. No `hashed_password` or other column is present. (F2)
- [ ] `get_current_user` raises `UnauthorizedException` (not `HTTPException`) when `verify_token` returns `None`. (F6)
- [ ] `get_current_user` raises `UnauthorizedException` (not `HTTPException`) when `_get_user_by_credential` returns `None`. (F7)
- [ ] `get_current_superuser` raises `ForbiddenException` when `current_user["is_superuser"]` is falsy. (F13)
- [ ] `get_current_moderator_or_superuser` raises `ForbiddenException` when both `current_user.get("is_moderator")` and `current_user.get("is_superuser")` are falsy. (F14)
- [ ] `rate_limiter_dependency` in `shared_dependencies.py` still references the now-local `get_optional_user` — no import needed for it. (F15)

### Error handling

- [ ] `_get_user_by_credential` has **no** `try/except` block. Infrastructure exceptions propagate unchanged to the global handler. (N1)
- [ ] `get_optional_user` catches `HTTPException` (for 401) and generic `Exception` and returns `None` in both cases — intentional: this function is an optional-auth gateway, not an adapter, so the broad catch is correct here and does not violate the adapter error rule. (F9–F11)
- [ ] No new `DomainError` subclass was added inside `features/` or `shared_dependencies.py`. All domain errors live in `app/domain/errors.py`. (error_handling.md)
- [ ] No adapter in this slice wraps a `try/except Exception` around non-business-meaningful exceptions. (Not applicable — no new Adapter class in this slice.)

### Files and headers

- [ ] New test file `tests/features/architecture/0025_centralize_auth_dependencies/test_shared_dependencies.py` starts with `# FEATURE: centralize_auth_dependencies —` on line 1. (N3)
- [ ] `src/app/shared_dependencies.py` retains its `# STABLE:` header on line 1 (not replaced with `# FEATURE:`). (stable_vs_feature.md)
- [ ] `src/app/bootstrap/factory.py` retains its `# STABLE:` header on line 1. (stable_vs_feature.md)
- [ ] All 10 modified FEATURE router files retain their `# FEATURE:` header on line 1. (stable_vs_feature.md)

### DI

Not applicable — this slice introduces no new use-case class, no new adapter, no new port, and no new DI container provider.

### Tests

- [ ] `tests/features/architecture/0025_centralize_auth_dependencies/test_shared_dependencies.py` exists and contains all 5 `_get_user_by_credential` test cases from plan.md § 6: no-match returns None, match returns allowlisted dict, `@` routes to email branch, no-`@` routes to username branch, `is_deleted=True` row returns None. (F1–F5)
- [ ] File contains all 3 `get_current_user` test cases: raises 401 on invalid token, raises 401 when user not found, returns dict on success. (F6–F8)
- [ ] File contains all 3 `get_optional_user` test cases: returns None for missing header, returns None for non-Bearer format, returns None when `verify_token` returns None. (F9–F11)
- [ ] Mocks use `AsyncMock(spec=…)` for async dependencies; `mocker.patch` is used for `verify_token` and `_get_user_by_credential` where appropriate. (testing.md)
- [ ] No outside-in test present — opted out per plan.md § 6: no new HTTP surface, no new acceptance contract.
- [ ] No adapter unit test present — opted out: no new `*Adapter` class.
- [ ] No endpoint integration test present — opted out: no new HTTP endpoint.

### Quality gates

Run from project root in this order:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
cd src && lint-imports --config ../.importlinter
cd ..
pytest tests/architecture/
pytest
```

All must pass. Key gates:

- `importlinter` contract `vsa-feature-independence` — KEPT.
- `tests/architecture/test_architecture.py::test_vsa_domains_do_not_import_each_other[posts-users]` — PASSED.
- `tests/architecture/test_architecture.py::test_vsa_domains_do_not_import_each_other[users-posts]` — PASSED.
- `tests/smoke/test_app_starts.py` — PASSED. This boots the full app under uvicorn and catches any import that works in pytest but fails in production (the most common failure mode for this type of path-refactoring slice).
