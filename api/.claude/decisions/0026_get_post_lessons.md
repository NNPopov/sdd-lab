# Decision log — 0026_get_post

**Slice:** `specs/features/posts/0026_get_post`
**Date:** 2026-05-19
**Type:** Vertical slice (use-case + adapter + HTTP endpoint)

---

## Problems encountered and resolutions

### Problem 1 — Outside-in test expected flat `{"message": ...}` instead of nested error body

**What happened:** The outside-in test asserted:
```python
assert response.json() == {"message": "Post not found"}
```
But the global exception handler in `adapters/http/exception_handlers.py` returns:
```json
{"error": {"code": "notfound", "message": "Post not found"}}
```
The test was RED because of a wrong expected format, not a wrong implementation.

**Resolution:** Updated the three affected assertions in `get_post_outside_in_test.py`:
```python
# before
assert response.json() == {"message": "Post not found"}
# after
assert response.json() == {"error": {"code": "notfound", "message": "Post not found"}}
```

**How to spot this quickly:** The test's status code assertion passes (404) but the
body assertion fails. The left side of the diff always starts with `{'error': {...}}`.

**Lesson:** When writing outside-in test assertions for error responses, always use
the nested format:
```python
assert response.json() == {"error": {"code": "<code>", "message": "<msg>"}}
# or, when only checking the message:
assert response.json()["error"]["message"] == "Post not found"
```
The flat `{"message": "..."}` format does **not** match our exception handler. The correct
shape is documented by `adapters/http/exception_handlers.py` and visible in all
existing `presentation/test_router.py` files (e.g. `0017_moderate_post`).

The `/slice-test-red` skill should be updated to use the correct format in generated
test templates so this defect does not recur in future slices.

---

### Problem 2 — pytest module-name collision from `__init__.py` in test sub-packages

**What happened:** After adding `tests/features/posts/0026_get_post/presentation/__init__.py`
(and similarly for `domain/` and `data/`), pytest collected the presentation test functions
**twice** — once under the correct path and once under an unrelated slice's path:
```
tests/features/posts/0026_get_post/presentation/test_router.py::test_approved_post_returns_200_unauthenticated  ← correct
tests/features/users/0003_list_users/presentation/test_router.py::test_approved_post_returns_200_unauthenticated  ← wrong
```
The "wrong" copy ran without the Redis mock → `MissingClientError: Client is None.`

**Root cause:** With `--import-mode=importlib` and `__init__.py` present in
`presentation/`, pytest tries to import the module as a Python package using the short
name `presentation.test_router`. Two slices that both have
`presentation/__init__.py` and `presentation/test_router.py` share the same Python
module name. Python's import cache returns the first imported module for both paths,
making pytest believe the second file contains the same functions as the first.

**Resolution:** Deleted `__init__.py` from the test sub-packages:
```
tests/features/posts/0026_get_post/presentation/  ← no __init__.py
tests/features/posts/0026_get_post/domain/         ← no __init__.py
tests/features/posts/0026_get_post/data/           ← no __init__.py
```
Kept `__init__.py` only at the **slice root** (`tests/features/posts/0026_get_post/`),
which is the pattern used by all pre-existing slices (`0009_list_posts`, `0024_get_moderation_log`, etc.).

**Lesson:** Test sub-packages (`presentation/`, `domain/`, `data/`) must **not** have
`__init__.py`. Only the slice root directory gets one. Check this in any new slice before
running the full suite. The symptom is always: a test function appears twice in
`--collect-only` output under two different file paths.

---

### Problem 3 — Access-control change broke 0023 tests that relied on legacy read_post

**What happened:** The old flat `read_post` endpoint returned any post regardless of
`status`. The 0023 slice (`expose_post_uuid`) wrote tests that create a post (default
`status = "pending_review"`) and immediately GET it without auth, expecting 200.
After `read_post` was replaced by `GetPostEndpoint` (which enforces access control),
those unauthenticated GETs returned 404 instead.

**Affected tests:**
- `0023_expose_post_uuid/expose_post_uuid_outside_in_test.py::test_read_post_exposes_post_uuid_not_raw_uuid_field`
- `0023_expose_post_uuid/presentation/test_router.py::test_read_post_response_contains_post_uuid_not_raw_uuid`

**Resolution:** Added a `get_optional_user` dependency override (as the post author)
around the GET call in both tests:
```python
_fastapi_app.dependency_overrides[get_optional_user] = lambda: seeded_alice
try:
    read_resp = await async_client.get(_READ_POST_PATH.format(...))
finally:
    del _fastapi_app.dependency_overrides[get_optional_user]
```

**Lesson:** When a slice replaces a legacy endpoint that had no access control with one
that does, search the full test suite for tests that:
1. Call that endpoint path without auth, AND
2. Expect a non-404 status.

Run `grep -r '"{username}/post/{id}"' tests/` (or the relevant path template) across
all test files before declaring the slice done. Update the affected tests to authenticate
as the resource owner, or promote the post to `approved` before reading, depending on
what the test is actually trying to verify.

---

## Checklist for future access-control slices

- [ ] Outside-in test error body assertions use `{"error": {"code": "...", "message": "..."}}` format
- [ ] Test sub-packages (`presentation/`, `domain/`, `data/`) have **no** `__init__.py`
- [ ] Full `pytest --collect-only` output checked — no test function appears at two paths
- [ ] `grep` for the endpoint URL pattern across all tests — existing tests that assume
      the old permissive behavior updated before the full suite is run
- [ ] `ruff format`, `ruff check`, `mypy src/app`, `pytest` all pass
