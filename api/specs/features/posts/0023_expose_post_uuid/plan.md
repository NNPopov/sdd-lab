# 0023 · expose_post_uuid — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0023_expose_post_uuid
- **PRD:** ./prd.md
- **Reference slice (if any):** `../0022_list_all_posts_visibility/plan.md` — same pattern
  of modifying existing files across multiple slices with no new use-case folder.
- **HTTP path:** Modifies four existing endpoints:
  - `GET /api/v1/{username}/posts` (`list_posts`)
  - `GET /api/v1/posts` (`list_all_posts`)
  - `POST /api/v1/{username}/post` (`create_post`)
  - `GET /api/v1/{username}/post/{id}` (`read_post`)
- **STABLE files touched:** None. The `uuid` column already exists on the `Post` ORM model;
  no database migration is required.

## 2. Context summary

Four existing post endpoints return integer IDs but no UUID. Slice 0024 (`get_moderation_log`)
addresses posts by UUID in its URL; without UUID in listing and creation responses, clients
cannot construct that URL from data they already have. This slice surgically adds `post_uuid: UUID`
to the shared `PostItem` entity (covering `list_posts` and `list_all_posts`), to `CreatedPost`
(covering `create_post`), and to `PostRead` (covering `read_post`). No new use-case, port,
adapter class, DI provider, router, or migration is introduced — all changes are modifications
to existing files.

## 3. API contract

This slice adds one field to four existing responses. No new endpoints, no new request parameters,
no new error paths.

**Field added to all four responses:**

| Field | Type | Source |
|---|---|---|
| `post_uuid` | `UUID` | `post.uuid` ORM attribute (UUID v7, time-ordered) |

**Responses changed:**

| Endpoint | Schemas changed | Field added |
|---|---|---|
| `GET /api/v1/{username}/posts` | `PostItem` (_shared) + `PostItemSchema` (list_posts) | `post_uuid` |
| `GET /api/v1/posts` | `PostItem` (_shared) + `PostItemSchema` (list_all_posts) | `post_uuid` |
| `POST /api/v1/{username}/post` | `CreatedPost` (entity) + `CreatePostResponse` | `post_uuid` |
| `GET /api/v1/{username}/post/{id}` | `PostRead` (posts/schemas.py) | `post_uuid` |

**Status codes:** unchanged — no new `DomainError` subclasses, no new 4xx paths.

`list_pending_posts` already returns `post_uuid` and is not modified. `patch_post` and
`erase_post` return `{ "message": "..." }` only and are not modified.

## 4. File structure

This slice modifies existing files only. No new files are created inside any slice folder.

Files modified:

```
src/app/features/posts/_shared/
└── entities.py                  # add post_uuid: uuid.UUID to PostItem

src/app/features/posts/list_posts/
├── data/
│   └── adapter.py               # pass post_uuid=post.uuid in PostItem(...)
└── presentation/
    └── schemas.py               # add post_uuid: uuid.UUID to PostItemSchema

src/app/features/posts/list_all_posts/
├── data/
│   └── adapter.py               # pass post_uuid=post.uuid in PostItem(...)
└── presentation/
    └── schemas.py               # add post_uuid: uuid.UUID to PostItemSchema

src/app/features/posts/create_post/
├── domain/
│   └── entities.py              # add post_uuid: uuid.UUID to CreatedPost
├── data/
│   └── adapter.py               # replace model_validate(post) with explicit construction
└── presentation/
    └── schemas.py               # add post_uuid: uuid.UUID to CreatePostResponse

src/app/features/posts/
└── schemas.py                   # add uuid: UUID (excluded) + computed_field post_uuid to PostRead
```

New test files:

```
tests/features/posts/0023_expose_post_uuid/
├── __init__.py
├── data/
│   ├── __init__.py
│   └── test_adapters.py
├── presentation/
│   ├── __init__.py
│   └── test_router.py
└── expose_post_uuid_outside_in_test.py
```

## 5. Implementation steps

### Step 1 — _shared: add `post_uuid` to `PostItem`

**File:** `src/app/features/posts/_shared/entities.py`

Add `import uuid` at the top. Add `post_uuid: uuid.UUID` to `PostItem`. This single change
covers both `list_posts` and `list_all_posts` since both adapters construct `PostItem` directly.
The field is required (not `Optional`) — every post in the system has a UUID.

### Step 2 — list_posts adapter: pass `post_uuid`

**File:** `src/app/features/posts/list_posts/data/adapter.py`

In the `PostItem(...)` constructor call inside the list comprehension, add:

```python
post_uuid=post.uuid,
```

No other change. No `try/except` addition — this remains a read-only query with no
business-meaningful exception path (per `agent_docs/error_handling.md`).

### Step 3 — list_all_posts adapter: pass `post_uuid`

**File:** `src/app/features/posts/list_all_posts/data/adapter.py`

Identical change to Step 2: add `post_uuid=post.uuid` in the `PostItem(...)` constructor.

### Step 4 — list_posts presentation: add `post_uuid` to `PostItemSchema`

**File:** `src/app/features/posts/list_posts/presentation/schemas.py`

Add `import uuid` and `post_uuid: uuid.UUID` to `PostItemSchema`. The router already converts
`PostItem` → `PostItemSchema` via `PostItemSchema.model_validate(p)` (`from_attributes=True`),
so `post_uuid` flows through automatically by name.

### Step 5 — list_all_posts presentation: add `post_uuid` to `PostItemSchema`

**File:** `src/app/features/posts/list_all_posts/presentation/schemas.py`

Same change as Step 4.

### Step 6 — create_post entity: add `post_uuid` to `CreatedPost`

**File:** `src/app/features/posts/create_post/domain/entities.py`

Add `import uuid` and `post_uuid: uuid.UUID` to `CreatedPost`. The ORM attribute is named `uuid`,
not `post_uuid`, so `model_validate(post)` cannot map the field automatically — Step 7 switches
to explicit construction.

### Step 7 — create_post adapter: switch to explicit construction

**File:** `src/app/features/posts/create_post/data/adapter.py`

Replace `return CreatedPost.model_validate(post)` with an explicit constructor that maps
`post.uuid` → `post_uuid`:

```python
return CreatedPost(
    id=post.id,
    title=post.title,
    text=post.text,
    media_url=post.media_url,
    created_by_user_id=post.created_by_user_id,
    created_at=post.created_at,
    status=post.status,
    post_uuid=post.uuid,
)
```

This mirrors the established pattern in `list_pending_posts` adapter, which also maps
`row.Post.uuid` → `post_uuid` explicitly.

### Step 8 — create_post response schema: add `post_uuid`

**File:** `src/app/features/posts/create_post/presentation/schemas.py`

Add `import uuid` and `post_uuid: uuid.UUID` to `CreatePostResponse`. The router converts
`CreatedPost → CreatePostResponse` via `CreatePostResponse.model_validate(result)`. Since both
models have `post_uuid: uuid.UUID`, the mapping works automatically.

### Step 9 — posts/schemas.py: extend `PostRead` for `read_post`

**File:** `src/app/features/posts/schemas.py`

The `read_post` endpoint in `posts/router.py` uses `crud_posts.get(..., schema_to_select=PostRead)`.
FastCRUD reads `PostRead.model_fields` to determine which ORM columns to SELECT. The ORM column is
`uuid`; the desired response field name is `post_uuid`.

Approach: add `uuid: uuid_pkg.UUID = Field(exclude=True)` so FastCRUD selects the column but it
is excluded from the serialized JSON output. Then add a `@computed_field` property named
`post_uuid` that returns `self.uuid` — this is included in the JSON output.

Changes to `posts/schemas.py`:

1. Add `import uuid as uuid_pkg` to imports.
2. Add `from pydantic import computed_field, Field` (extend existing `pydantic` import).
3. Add to `PostRead`:
   ```python
   uuid: uuid_pkg.UUID = Field(exclude=True)

   @computed_field
   @property
   def post_uuid(self) -> uuid_pkg.UUID:
       return self.uuid
   ```

FastCRUD selects `uuid` → dict contains `uuid` → `PostRead` instance stores it (excluded from
output) → `post_uuid` computed property is serialized in the JSON response. No change to the
`read_post` endpoint body or `response_model` declaration.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test for this slice:

```
pytest tests/features/posts/0023_expose_post_uuid/expose_post_uuid_outside_in_test.py -v
```

Existing outside-in tests that must remain green:

```
pytest tests/features/posts/0009_list_posts/ -v
pytest tests/features/posts/0010_list_all_posts/list_all_posts_outside_in_test.py -v
pytest tests/features/posts/0011_create_post/ -v
pytest tests/features/posts/0022_list_all_posts_visibility/list_all_posts_visibility_outside_in_test.py -v
```

The slice is not done until all tests pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

### Use-case unit test

**Opt-out.** No use-case is modified. `list_posts` and `list_all_posts` use-cases are thin
pass-throughs with no branching. `create_post` use-case is unaffected. A unit test adds no
value for a field-passthrough change.

### Adapter unit tests

**File:** `tests/features/posts/0023_expose_post_uuid/data/test_adapters.py`

Using a real async session against the test Postgres database (no mocks), seed one user and
one approved post. Call `ListPostsAdapter.list()` and `ListAllPostsAdapter.list()` directly.
Assert:
- The returned `PostItem` objects carry a `post_uuid` field.
- `post_uuid` matches the `uuid` column on the seeded `Post` row (equality check after UUID
  string comparison).

No exception-path assertions — neither adapter has `try/except`.

Prior art: `tests/features/posts/0022_list_all_posts_visibility/data/test_adapter.py`.

**Opt-out for `create_post` adapter:** The field mapping change in `CreatePostAdapter.create()`
is mechanical (explicit field assignment). The end-to-end coverage from the outside-in test
is sufficient; a separate adapter unit test adds no new signal.

### Endpoint integration test

**File:** `tests/features/posts/0023_expose_post_uuid/presentation/test_router.py`

`httpx.AsyncClient` against the running app with test Postgres. Seed one user and one post.
Assert:
- `GET /api/v1/{username}/posts` → HTTP 200, each item contains `post_uuid` as a valid UUID.
- `GET /api/v1/posts` → HTTP 200, each item contains `post_uuid` as a valid UUID.
- `POST /api/v1/{username}/post` → HTTP 201, response contains `post_uuid` as a valid UUID.
- `GET /api/v1/{username}/post/{id}` → HTTP 200, response contains `post_uuid` as a valid UUID.
- All four `post_uuid` values for the same post are identical.

Prior art: `tests/features/posts/0022_list_all_posts_visibility/presentation/test_router.py`.

### Outside-in test

**File:** `tests/features/posts/0023_expose_post_uuid/expose_post_uuid_outside_in_test.py`

Full HTTP stack with real adapter, test Postgres, no mocks. Single scenario per PRD §
Outside-in test:

1. Register and authenticate `alice`.
2. `alice` creates one post via `POST /api/v1/users/alice/post` → capture `post_uuid` from the
   `201` response body.
3. Approve the post directly via the test session factory (set `status = 'approved'`) so it
   appears in the public feeds.
4. `GET /api/v1/alice/posts` → assert `post_uuid` is present in the first item and is a valid
   UUID string.
5. `GET /api/v1/posts` → assert `post_uuid` is present in the first item and is a valid UUID
   string.
6. `GET /api/v1/alice/post/{id}` → assert `post_uuid` is present and is a valid UUID string.
7. Assert all three `post_uuid` values from steps 4–6 match the one captured in step 2.

This is the acceptance gate. The slice is not done until this test is green and existing
outside-in tests also remain green.

**Opt-outs:** use-case unit test and `create_post` adapter unit test (both justified above).

## 7. Out of scope for this slice

- Adding `post_uuid` to `patch_post` or `erase_post` responses (those return only a message string).
- Adding `post_uuid` to `list_pending_posts` (already present from slice 0019).
- The `GET /posts/{post_uuid}/moderation-log` endpoint — that is slice 0024.
- Cache key changes — `post_uuid` is additive to the response and not a filter or selector;
  existing cache key patterns remain valid.
- Filtering or searching posts by UUID.

## 8. Open questions

None. All decisions resolved in the PRD:

- `uuid` column already exists on `Post`; no migration needed.
- Field name in all responses is `post_uuid`, matching the convention established by
  `list_pending_posts` (slice 0019).
- The `Field(exclude=True)` + `@computed_field` pattern in `PostRead` accommodates FastCRUD's
  column-selection behaviour, which reads Python field names from `model_fields` directly.
  `uuid` is selected from the DB; `post_uuid` is what appears in the JSON response.
- `patch_post` and `erase_post` responses are not changed.
