# 0013 · moderation_db_foundation — Outside-in test spec

## Outside-in test: opted out

This slice has no HTTP entry point, no use-case, and no adapter. It delivers
only ORM model changes and an Alembic migration.

The outside-in test is opted out per `plan.md` § 6 and per the parent PRD
`specs/features/moderation/0012_moderation/prd.md` which explicitly states:
"Slice 0013 is a DB-only task — it gets a spec folder but no outside-in test."

Per `agent_docs/testing.md`, opting out the outside-in test is reserved for
slices with no HTTP entry point. This is that case.

## Acceptance verification (replaces outside-in test)

The acceptance gate for this slice is the **smoke test** combined with a
manually reviewed migration.

### Gate 1 — Smoke test passes

```
pytest tests/smoke/test_app_starts.py
```

This boots the real app via uvicorn and confirms that:

- `PostModerationLog` is importable through `adapters/db/models/__init__.py`.
- No import path errors were introduced in the ORM model files.
- The app starts and serves `/api/v1/health` successfully.

The smoke test is the closest functional equivalent to an outside-in test for
a DB-only slice: it exercises the real app boot path, not just pytest's import
resolution.

### Gate 2 — Migration review passed

A human reviewer has confirmed (per `validation.md` S1–S8 and the code review
checklist) that:

- `alembic upgrade head` applies without errors.
- `server_default` is set for `post.status` on existing rows (F6).
- FK constraints and indexes are present (F2, F9, F10, F11).
- `alembic downgrade -1` reverses all changes (F15).

## What the next slice's outside-in test covers

The first slice that uses these schema additions (slice 0014 —
`expose_moderator_flag`) will have an outside-in test that implicitly verifies
the `is_moderator` column exists and is readable. Slice 0020 (`create_post_status`)
will verify `Post.status` end-to-end. Slice 0016 (`moderate_post`) will verify
`PostModerationLog` inserts.

This slice is therefore not left permanently unverified — the foundation is
confirmed by all downstream outside-in tests that depend on it.

## Out of scope for this test spec

- Any automated HTTP test: there is no endpoint.
- Unit tests for the ORM models: SQLAlchemy `MappedAsDataclass` models contain
  no logic to unit-test.
- Performance or concurrency tests.
