# 0021 · list_posts_visibility — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from the project root).
- Test Postgres running (`docker compose up test-db -d`).
- One user `alice` registered and an access token obtained for her.
- One user `bob` registered and an access token obtained for him.
- At least one post by `alice` with `status = 'approved'` and at least one with
  `status = 'pending_review'` seeded directly into the DB (posts default to
  `pending_review`; set `status = 'approved'` directly via `UPDATE`).
- Substitute `<alice_token>` and `<bob_token>` with the actual JWT values.

### Quick seed (psql / SQLAlchemy shell)

```sql
-- after alice creates two posts via POST /api/v1/users/alice/posts
-- get their IDs from the response, then approve one:
UPDATE post SET status = 'approved' WHERE id = <approved_post_id>;
```

---

## Manual scenarios

### S1 — Unauthenticated caller sees only approved posts

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/{username}/posts | jq .
```

Replace `{username}` with `alice`. No `Authorization` header.

**Expected:**

- HTTP 200.
- `items` contains exactly the posts with `status = 'approved'`.
- Pending posts are absent.
- Every item has a `status` field with value `"approved"`.
- All existing fields (`id`, `title`, `text`, `media_url`, `created_at`,
  `created_by_user_id`, `username`) are present and unchanged.

**Covers:** F1, F5, F6.

---

### S2 — Different authenticated user sees only approved posts

**Steps:**

```bash
curl -s \
  -H "Authorization: Bearer <bob_token>" \
  http://localhost:8000/api/v1/{username}/posts | jq .
```

Replace `{username}` with `alice`.

**Expected:**

- HTTP 200.
- `items` contains only `alice`'s approved posts — identical to S1's result.
- Pending posts are absent.
- Every item has a `status` field with value `"approved"`.

**Covers:** F2, F5.

---

### S3 — Author sees all posts regardless of status

**Steps:**

```bash
curl -s \
  -H "Authorization: Bearer <alice_token>" \
  http://localhost:8000/api/v1/{username}/posts | jq .
```

Replace `{username}` with `alice`.

**Expected:**

- HTTP 200.
- `items` contains **all** of `alice`'s non-deleted posts: both the approved
  post and the pending post appear.
- `total_count` equals the full count of alice's non-deleted posts.
- Each item has a `status` field reflecting that post's actual status.

**Covers:** F3, F5.

---

### S4 — Moderator/superuser (non-author) sees only approved posts

**Steps:**

Obtain a moderator or superuser token (`<mod_token>`). Then:

```bash
curl -s \
  -H "Authorization: Bearer <mod_token>" \
  http://localhost:8000/api/v1/{username}/posts | jq .
```

Replace `{username}` with `alice`.

**Expected:**

- HTTP 200.
- `items` contains only `alice`'s approved posts — same result as S2.
- Pending posts are not visible even to moderators on this endpoint.

**Covers:** F2.

---

### S5 — Zero approved posts returns empty list for non-author

**Steps:**

Ensure alice has only `pending_review` posts (or create a fresh user with only
pending posts). Then:

```bash
curl -s http://localhost:8000/api/v1/{username}/posts | jq .
```

No `Authorization` header.

**Expected:**

- HTTP 200.
- `items: []`.
- `total_count: 0`.
- Response still has the full `ListPostsResponse` shape (no 404, no error).

**Covers:** F4.

---

### S6 — Invalid or expired token treated as unauthenticated

**Steps:**

```bash
curl -s \
  -H "Authorization: Bearer invalidtoken123" \
  http://localhost:8000/api/v1/{username}/posts | jq .
```

**Expected:**

- HTTP 200 (the `get_optional_user` dependency returns `None` on auth failure;
  the endpoint is not gated on authentication).
- `items` contains only approved posts — same result as S1 (public view).
- No HTTP 401 is returned.

**Covers:** F1.

---

### S7 — Comparison: same request authenticated vs unauthenticated

**Steps:**

1. Run S1 (unauthenticated) and record `items`.
2. Run S2 (as bob) and record `items`.
3. Run S3 (as alice) and record `items`.

**Expected:**

- S1 and S2 return identical `items` (only approved posts).
- S3 returns a superset of S1/S2 — it includes the pending posts plus the same
  approved post.

**Covers:** F1, F2, F3.

---

### S8 — Existing response fields are unchanged

**Steps:**

Run S1. Inspect one item in the response.

**Expected:**

All seven original fields are present: `id`, `title`, `text`, `media_url`,
`created_at`, `created_by_user_id`, `username`. The new `status` field is present
too. No field has been removed or renamed.

**Covers:** F6.

---

## Code review checklist

This slice is a **modification** of existing files only — no new slice folder,
no new port, no new adapter class, no new DI provider. The checklist is adapted
accordingly.

### Modifications to `posts/_shared/entities.py`

- [ ] `PostItem` gains `status: str` as a required field (no default value).
- [ ] No other fields on `PostItem` or `PostPage` are altered.

### Modifications to `list_all_posts/data/adapter.py`

- [ ] `PostItem(...)` construction inside `ListAllPostsAdapter.list()` includes
      `status=post.status`.
- [ ] No `try/except` block is added. This is still a read-only query.
- [ ] No other logic in `ListAllPostsAdapter` is altered.

### Modifications to `list_all_posts/presentation/schemas.py`

- [ ] `PostItemSchema` gains `status: str`.
- [ ] No other fields are altered.

### Modifications to `list_posts/domain/commands.py`

- [ ] `ListPostsQuery` gains `requester_username: str | None = None`.
- [ ] Default is `None` so existing use-sites remain valid without update.

### Modifications to `list_posts/data/adapter.py`

- [ ] `is_author = query.requester_username == query.username` is computed once.
- [ ] `WHERE post.status = 'approved'` is applied to the **count query** when
      `not is_author`.
- [ ] `WHERE post.status = 'approved'` is applied to the **rows query** when
      `not is_author`, using the same condition.
- [ ] `PostItem(...)` construction includes `status=post.status` in all paths.
- [ ] No `try/except` block is added or modified.
- [ ] Infrastructure failures propagate unchanged; the adapter does not log
      exceptions (per `agent_docs/error_handling.md`).

### Modifications to `list_posts/presentation/schemas.py`

- [ ] `PostItemSchema` gains `status: str`.
- [ ] `ListPostsResponse` is unchanged.

### Modifications to `list_posts/presentation/router.py`

- [ ] `get_optional_user` is imported with a relative import:
      `from ....users.dependencies import get_optional_user`.
- [ ] `_get_view` is defined as a local async dependency function that accepts
      `username: str` and `optional_user: Annotated[dict | None, Depends(get_optional_user)]`
      and returns `"author"` or `"public"`.
- [ ] The endpoint function signature includes `view: Annotated[str, Depends(_get_view)]`
      so the `@cache` decorator can interpolate `{view}` from kwargs.
- [ ] The `@cache` key_prefix is
      `"{username}_posts:{view}:page_{page}:items_per_page:{items_per_page}"`.
- [ ] `requester_username` is derived inside the endpoint body as
      `username if view == "author" else None`.
- [ ] `ListPostsQuery` is constructed with the `requester_username` field.
- [ ] No business logic (visibility decision) appears in the router; it belongs
      in the adapter.

### Import conventions

- [ ] All imports inside `src/app/` use **relative** paths (`from ..`, `from ....`).
      No `from app...` or `from src.app...` inside the source tree.
- [ ] The import of `get_optional_user` crosses into the `users` feature — verify
      it imports only from `features/users/dependencies.py`, not from any
      `domain/`, `data/`, or `presentation/` sub-folder of a users slice.

### Error handling

- [ ] No `HTTPException` is raised inside `ListPostsUseCase`.
- [ ] `ListPostsUseCase` is unchanged (thin pass-through; no new logic added).
- [ ] No new `DomainError` subclass was added in any feature folder.

### File headers

- [ ] No new `.py` files were created. All modified files retain their existing
      `# FEATURE:` header on line 1.
- [ ] No STABLE file was modified.

### 0009 pre-condition

- [ ] `tests/features/posts/0009_list_posts/list_posts_outside_in_test.py` seeds
      posts with `status = 'approved'` (or an equivalent approach that makes them
      visible to unauthenticated callers).
- [ ] 0009 outside-in test passes after the test update and before any production
      code is changed.

### Tests

- [ ] Adapter unit test exists at
      `tests/features/posts/0021_list_posts_visibility/data/test_adapter.py`.
- [ ] Adapter unit test covers: author view (no filter), non-author view (filter),
      unauthenticated view (filter), and `status` field mapping on every item.
- [ ] Endpoint integration test exists at
      `tests/features/posts/0021_list_posts_visibility/presentation/test_router.py`.
- [ ] Endpoint integration test covers: unauthenticated, different user, author,
      empty result, and `status` field presence.
- [ ] Outside-in test exists at
      `tests/features/posts/0021_list_posts_visibility/list_posts_visibility_outside_in_test.py`
      and is GREEN.
- [ ] All pre-existing tests (including 0009 outside-in) remain GREEN.

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. `tests/smoke/test_app_starts.py` is included in `pytest` and must
also pass — a green smoke test confirms that the import changes in the router
(relative import of `get_optional_user`) work correctly under uvicorn, not just
under pytest's `pythonpath` setting.
