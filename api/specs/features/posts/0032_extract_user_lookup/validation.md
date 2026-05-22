# 0032 · extract_user_lookup — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test database migrated (`alembic upgrade head`).
- One **regular user** seeded (username: `alice`), one **superuser** seeded.
- A post seeded under `alice`'s account (post `id` noted as `POST_ID`).
- A second **regular user** seeded (username: `bob`) — used for forbidden-access scenarios.
- A **soft-deleted user** seeded (username: `deleted_user`, `is_deleted = True`).
- Bearer token for `alice` at hand (`ALICE_TOKEN`).
- Bearer token for `bob` at hand (`BOB_TOKEN`).
- Bearer token for the superuser at hand (`SUPER_TOKEN`).

All four scenarios S1–S7 and S10 require that the refactored code is deployed. Run
`pytest tests/features/posts/ -k "outside_in" -v` to confirm the acceptance gate first.

---

## Manual scenarios

### S1 — create_post: happy path

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d '{"title": "Hello", "text": "First post", "media_url": null}'
```

**Expected:**

- Status `201`.
- Body contains `id`, `title: "Hello"`, `text: "First post"`, `status: "pending_review"`.
- Row exists in `post` table with `created_by_user_id = alice.id`.

**Covers:** F14, F15, F27.

---

### S2 — create_post: non-existent username → 404

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/no_such_user/post \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d '{"title": "Test", "text": "Body", "media_url": null}'
```

**Expected:**

- Status `404`.
- Body `{"message": "User not found"}`.

**Covers:** F15, F27.

---

### S3 — create_post: soft-deleted user → 404

Verifies that `get_active_user_by_username` enforces `is_deleted = False` — the core behavioral
contract encoded in the new method name.

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/deleted_user/post \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d '{"title": "Test", "text": "Body", "media_url": null}'
```

**Expected:**

- Status `404`.
- Body `{"message": "User not found"}`.

**Covers:** F5, F7, F8, F15, F27.

---

### S4 — create_post: requester ≠ target username → 403

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -d '{"title": "Hack", "text": "Not mine", "media_url": null}'
```

**Expected:**

- Status `403`.
- Body `{"message": "You can only post under your own username"}` (or the `ForbiddenDomainError`
  default).

**Covers:** F16, F27.

---

### S5 — update_post: happy path

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/alice/post/$POST_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d '{"title": "Updated title", "text": "Updated body", "media_url": null}'
```

**Expected:**

- Status `200`.
- Body `{"message": "Post updated"}`.
- The `post` row in the database reflects updated `title` and `text`.

**Covers:** F17, F18, F27.

---

### S6 — update_post: non-existent username → 404

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/no_such_user/post/$POST_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d '{"title": "X", "text": "Y", "media_url": null}'
```

**Expected:**

- Status `404`.
- Body `{"message": "User not found"}`.

**Covers:** F18, F27.

---

### S7 — erase_post (soft delete): happy path

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/alice/post/$POST_ID \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- Status `200`.
- Body `{"message": "Post deleted"}`.
- The `post` row has `is_deleted = True` (not removed from DB).

**Covers:** F20, F21, F27.

---

### S8 — erase_post: non-existent username → 404

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/no_such_user/post/$POST_ID \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- Status `404`.
- Body `{"message": "User not found"}`.

**Covers:** F21, F27.

---

### S9 — erase_post: requester ≠ owner → 403

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/alice/post/$POST_ID \
  -H "Authorization: Bearer $BOB_TOKEN"
```

**Expected:**

- Status `403`.

**Covers:** F22, F27.

---

### S10 — erase_db_post (hard delete): happy path

Requires a fresh post since S7 may have soft-deleted `POST_ID`. Seed another post as `alice`
first (S1), note its `id` as `POST_ID_2`.

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/alice/db_post/$POST_ID_2 \
  -H "Authorization: Bearer $SUPER_TOKEN"
```

**Expected:**

- Status `200`.
- Body `{"message": "Post deleted from the database"}`.
- Row is fully removed from the `post` table.

**Covers:** F23, F24, F27.

---

### S11 — erase_db_post: non-existent username → 404

**Steps:**

```bash
curl -s -X DELETE http://localhost:8000/api/v1/no_such_user/db_post/999 \
  -H "Authorization: Bearer $SUPER_TOKEN"
```

**Expected:**

- Status `404`.
- Body `{"message": "User not found"}`.

**Covers:** F24, F27.

---

## Code review checklist

For the reviewer to verify on the PR. Reject until all are yes.

### Shared entity

- [ ] `posts/_shared/entities.py` contains `UserIdentity` with fields `id: int`,
      `username: str`, and `model_config = ConfigDict(from_attributes=True)`. (F1, N11)
- [ ] `PostAuthor` class is fully deleted. Running
      `grep -r "PostAuthor" src/app/features/posts/` returns zero hits. (F2)

### Shared port

- [ ] `posts/_shared/user_lookup_port.py` exists, starts with
      `# FEATURE: posts._shared — ...` on line 1. (N4)
- [ ] `UserLookupPort` is decorated with `@runtime_checkable` and inherits from
      `typing.Protocol`. (F3, F4, N2)
- [ ] The single method signature is
      `async def get_active_user_by_username(self, username: str) -> UserIdentity | None`. (F3)

### Shared adapter

- [ ] `posts/_shared/user_lookup_adapter.py` exists, starts with
      `# FEATURE: posts._shared — ...` on line 1. (N4)
- [ ] Class declaration is `class UserLookupAdapter(UserLookupPort):` — explicit inheritance
      from the port is mandatory. (N1)
- [ ] The query filters on `User.username == username` AND `User.is_deleted.is_(False)`. (F5)
- [ ] Returns `UserIdentity.model_validate(user)` when a user is found, `None` otherwise. (F6, F7, F8)
- [ ] `get_active_user_by_username` contains **no** `try/except` block. (N3)
- [ ] No logging statements inside the adapter. (per `agent_docs/error_handling.md`)

### Per-slice ports (all four)

- [ ] `create_post_port.py` no longer declares `get_user_by_username`. (F9)
- [ ] `update_post_port.py` no longer declares `get_user_by_username`. (F10)
- [ ] `erase_post_port.py` no longer declares `get_user_by_username`. (F11)
- [ ] `erase_db_post_port.py` no longer declares `get_user_by_username`. (F12)
- [ ] None of the four port files imports `PostAuthor` or `UserIdentity` (user identity is
      no longer a port concern). (F9–F12)

### Per-slice adapters (all four)

- [ ] `create_post/data/adapter.py` does not implement `get_user_by_username`. (F13)
- [ ] `update_post/data/adapter.py` does not implement `get_user_by_username`. (F13)
- [ ] `erase_post/data/adapter.py` does not implement `get_user_by_username`. (F13)
- [ ] `erase_db_post/data/adapter.py` does not implement `get_user_by_username`. (F13)
- [ ] None of the four adapters imports `User` ORM model for user lookup (that import now
      belongs only to `UserLookupAdapter`). (F13)

### Use-case signatures (all four)

- [ ] `CreatePostUseCase.__init__` signature: `(self, port: CreatePostPort, user_lookup: UserLookupPort)`. (F14)
- [ ] `UpdatePostUseCase.__init__` signature: `(self, port: UpdatePostPort, user_lookup: UserLookupPort)`. (F17)
- [ ] `ErasePostUseCase.__init__` signature: `(self, port: ErasePostPort, user_lookup: UserLookupPort)`. (F20)
- [ ] `EraseDbPostUseCase.__init__` signature: `(self, port: EraseDbPostPort, user_lookup: UserLookupPort)`. (F23)
- [ ] Each use-case calls `self._user_lookup.get_active_user_by_username(...)` — not
      `self._port.get_user_by_username(...)`. (F15, F18, F21, F24)
- [ ] Each use-case raises `NotFoundDomainError("User not found")` when the result is
      `None`. (F15, F18, F21, F24)
- [ ] No `HTTPException` raised in any use-case. (N6)

### DI container (`bootstrap/container.py`)

- [ ] `UserLookupAdapter` is imported at the top of `container.py`. (F25)
- [ ] `user_lookup_adapter = providers.Factory(UserLookupAdapter, session_factory=session_factory)`
      is declared. (F25)
- [ ] All four use-case providers (`create_post_use_case`, `update_post_use_case`,
      `erase_post_use_case`, `erase_db_post_use_case`) pass
      `user_lookup=user_lookup_adapter`. (F26)
- [ ] No new router module was added to `wiring_config` (this refactor adds no new router). (plan §8)
- [ ] No STABLE file other than `bootstrap/container.py` was modified. (N4, `agent_docs/stable_vs_feature.md`)

### Import conventions

- [ ] All imports inside `src/app/` are **relative** (`from ....._shared...`,
      `from .....domain.errors...`). No `from app...` inside source files. (N5)
- [ ] Test files use absolute imports (`from app.features.posts...`). (N5)

### Quality gates

Run in order:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

- [ ] `ruff format` produces no diff.
- [ ] `ruff check` reports zero violations.
- [ ] `mypy src/app` passes with zero errors (N9) — this is the primary static check that
      `UserLookupAdapter` structurally satisfies `UserLookupPort`, and that all four use-cases
      accept the new constructor signature.
- [ ] `pytest` passes entirely, including `tests/smoke/test_app_starts.py`. (N10)
- [ ] The four existing outside-in tests pass: `pytest tests/features/posts/ -k "outside_in" -v`. (F27)
