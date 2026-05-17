# 0020 · create_post_status — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0020_create_post_status
- **PRD:** ./prd.md
- **Reference slice:** `../../users/0014_expose_moderator_flag/plan.md` — closest
  match: a modification of an existing slice that adds one field to a domain
  entity, a response schema, and a data adapter without touching routing, ports,
  or DI wiring.
- **HTTP path modified:** `POST /api/v1/{username}/post` — `CreatePostResponse`
  gains `status: str`.
- **STABLE files touched:** none. All three modified files carry `# FEATURE:`
  headers and live entirely within `features/posts/create_post/`.

## 2. Context summary

Slice 0013 added the `status` column to the `Post` ORM model with a DB-level
default of `"pending_review"`. The `create_post` slice has been inserting rows
since then without surfacing this field: the `CreatedPost` domain entity, the
`CreatePostResponse` HTTP schema, and the adapter's `Post(...)` constructor call
all pre-date the `status` column and were never updated. Slice 0020 closes this
gap with three purely additive changes: the entity and the response schema each
gain `status: str`, and the adapter makes the `status="pending_review"` setting
explicit rather than relying silently on the ORM default. No new endpoints, use
cases, commands, ports, DI entries, or migrations are introduced.

## 3. API contract

### `POST /api/v1/{username}/post` (modified)

**Path parameters:**

| Param | Type | Validation |
|---|---|---|
| `username` | `str` | required; must match authenticated user |

**Request body** (`CreatePostRequest`) — unchanged:

| Field | Type | Validation |
|---|---|---|
| `title` | `str` | `min_length=1`, `max_length=30` |
| `text` | `str` | `min_length=1`, `max_length=63206` |
| `media_url` | `str \| None` | optional |

**Response body** (`CreatePostResponse`) — one new field:

| Field | Type | Notes |
|---|---|---|
| `id` | `int` | unchanged |
| `title` | `str` | unchanged |
| `text` | `str` | unchanged |
| `media_url` | `str \| None` | unchanged |
| `created_by_user_id` | `int` | unchanged |
| `created_at` | `datetime` | unchanged |
| `status` | `str` | **new** — always `"pending_review"` at creation time |

**Status codes:** unchanged (`201`, `401`, `403`, `404`, `422`, `500`).

## 4. File structure

No new files. Three existing FEATURE files are modified:

```
src/app/features/posts/create_post/
├── domain/
│   └── entities.py          # CreatedPost — add status: str
├── data/
│   └── adapter.py           # Post(...) constructor — add status="pending_review"
└── presentation/
    └── schemas.py           # CreatePostResponse — add status: str
```

The following files are read-only for this slice:

```
src/app/features/posts/create_post/
├── domain/
│   ├── commands.py          # no change
│   ├── ports/
│   │   └── create_post_port.py   # no change — returns CreatedPost; entity change flows through
│   └── use_case.py          # no change — pass-through
└── presentation/
    └── router.py            # no change — model_validate picks up the new field automatically
```

No ORM model, migration, container, or router-registration changes are needed.

## 5. Implementation steps

### Step 1 — Domain entity: `CreatedPost`

**File:** `src/app/features/posts/create_post/domain/entities.py`

Add `status: str` to `CreatedPost`. Place it after `created_at` to group
lifecycle fields together:

```python
class CreatedPost(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    text: str
    media_url: str | None
    created_by_user_id: int
    created_at: datetime
    status: str          # new
```

No import changes — `str` is a stdlib type; `domain/` already imports only
stdlib and pydantic per `agent_docs/architecture.md` § Layer rules. Pydantic's
`model_validate(orm_row)` will populate `status` from the `Post` ORM row
automatically because both names match and `from_attributes=True` is set.

### Step 2 — Data adapter: `CreatePostAdapter.create()`

**File:** `src/app/features/posts/create_post/data/adapter.py`

Add `status="pending_review"` as an explicit keyword argument to the `Post(...)`
constructor inside `create()`:

```python
post = Post(
    created_by_user_id=command.created_by_user_id,
    title=command.title,
    text=command.text,
    media_url=command.media_url,
    status="pending_review",   # new — explicit; ORM default remains as safety net
)
```

No error-handling changes: creating a post row has no business-meaningful
infrastructure exceptions beyond those already handled (none in the current
adapter). No `try/except` is added per `agent_docs/error_handling.md`
§ Right shape: create with one specific catch.

### Step 3 — Presentation schema: `CreatePostResponse`

**File:** `src/app/features/posts/create_post/presentation/schemas.py`

Add `status: str` to `CreatePostResponse`:

```python
class CreatePostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    text: str
    media_url: str | None
    created_by_user_id: int
    created_at: datetime
    status: str          # new
```

The router already calls `CreatePostResponse.model_validate(result)` where
`result` is `CreatedPost`. Once both the entity and the schema carry `status`,
the field flows through without any router change.

### Step 4 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Confirm the smoke test (`tests/smoke/test_app_starts.py`) passes and the
existing outside-in test for slice 0011 remains green:

```
pytest tests/features/posts/0011_create_post/create_post_outside_in_test.py -v
```

The existing test does not assert `"status" not in body`, so adding the field
is non-breaking. All existing assertions (`title`, `text`, `media_url`,
`created_by_user_id`, `id`, `created_at`, `"uuid" not in body`,
`"is_deleted" not in body`) still pass unchanged.

## 6. Tests planned

- **Use-case unit test** — **opted out**. `CreatePostUseCase.__call__()` is
  unchanged; it calls `self._port.create(internal)` and returns the result
  with no branching. No new behavior is introduced. Opt-out is valid per
  `agent_docs/testing.md` (no new behavior, trivial pass-through).

- **Adapter unit test** —
  `tests/features/posts/0020_create_post_status/data/test_adapter.py`.
  Uses a real async session against the test Postgres database (pattern from
  `tests/features/posts/0011_create_post/data/test_adapter.py`). One case:
  - Call `CreatePostAdapter.create()` with a valid `CreatePostInternalCommand`.
  - Assert `result.status == "pending_review"`.
  - Assert the DB row also has `status = "pending_review"` via a direct SQL
    query (confirms the adapter wrote it explicitly, not only the ORM default).

- **Endpoint integration test** —
  `tests/features/posts/0020_create_post_status/presentation/test_router.py`.
  Uses `httpx.AsyncClient` against the running app with test Postgres (pattern
  from `tests/features/posts/0011_create_post/presentation/test_router.py`).
  One case:
  - Happy path: `POST /api/v1/{username}/post` with valid body → HTTP 201.
  - Assert `response.json()["status"] == "pending_review"`.

- **Outside-in test** —
  `tests/features/posts/0020_create_post_status/create_post_status_outside_in_test.py`.
  Full HTTP stack with real adapter and test Postgres. Three-step scenario:
  1. Create and authenticate an author (alice).
  2. `POST /api/v1/{username}/post` with valid title and text.
  3. Assert HTTP 201 and `response.json()["status"] == "pending_review"`.
  4. Assert the DB row has `status = "pending_review"` via direct SQL query.
  This is the acceptance gate; the slice is not done until this test is green.

**Opt-outs:** use-case unit test only (documented above).

## 7. Out of scope for this slice

- Post visibility filtering (`GET /users/{username}/posts` and `GET /posts`
  returning only `approved` posts) — slices 0021 and 0022.
- Exposing `post_uuid` in the create-post response — out of scope for the
  original `create_post` slice and remains so here.
- Enforcing or validating status transitions at creation time — there is only
  one valid creation status (`pending_review`); transitions belong to slices
  0017 and 0018.
- Cache invalidation — `create_post` uses no cache decorator; no change needed.
- Any change to `CreatePostRequest`, `CreatePostCommand`, or
  `CreatePostInternalCommand` — the creation input is unchanged.

## 8. Open questions

None — all decisions resolved in the PRD.
