# sdd-lab

A learning monorepo for **Spec-Driven Development** with LLM assistance —
from idea to green acceptance test, one slice at a time.

The repo contains two companion projects sharing the same domain:

| Project | Stack | Path |
|---|---|---|
| REST API | Python · FastAPI · PostgreSQL · Redis | [`api/`](api/) |
| Cross-platform client | Flutter · Dart | [`flutter/`](flutter/) |

## What is Spec-Driven Development?

Every feature starts as a specification, not as code.
For each new *slice* (a single use-case or screen) the workflow is:

```
/grill-me             ← optional: stress-test the idea first
/to-prd               → prd.md          (product requirements)
/feature-spec         → plan.md         (technical plan)
/feature-requirements → requirements.md
/feature-validation   → validation.md   (manual test checklist)
/feature-tests        → tests.md        (outside-in test spec)
/slice-test-red       → <slice>_outside_in_test (verified RED)
implementation        → until the outside-in test turns GREEN
```

A slice is **done** only when its acceptance test is green.
Specs live in `specs/features/<resource>/<NNNN>_<slice>/`;
the global index is `specs/roadmap.md`.

## API — `api/`

Async **FastAPI** service, Python 3.11+.

**Architecture:** Vertical Slice + Hexagonal.
Each slice = one use-case class (`__call__()`) with its own
`domain/`, `data/`, `presentation/` sub-layers.

| Concern | Choice |
|---|---|
| Database | PostgreSQL · SQLAlchemy 2.0 async · asyncpg · Alembic |
| Cache | Redis via `@cache` decorator |
| DI | `dependency_injector` + `Annotated[X, Depends(...)]` |
| Errors | `DomainError` hierarchy — never `HTTPException` in use-cases |
| Lint / type-check | Ruff · mypy strict |
| Tests | pytest · pytest-asyncio · httpx.AsyncClient |

### Quick start

```bash
cd api
uv sync
docker-compose up -d        # PostgreSQL + Redis
alembic upgrade head
uvicorn src.app.main:app --reload
```

```bash
pytest
```

**Slices implemented:** 23 complete, 1 planned.
Features: `users`, `posts`, `moderation`.

## Flutter — `flutter/`

Cross-platform client (iOS-first) for the API.

**Architecture:** Vertical Slice + Hexagonal.
Each slice has `domain/ports/`, `data/` (adapters), and `presentation/`.

| Concern | Choice |
|---|---|
| State | `flutter_bloc` — Cubit by default |
| DI | `get_it` + `injectable` |
| Navigation | `auto_route` |
| HTTP | `dio` + `retrofit` |
| Serialization | `freezed` + `json_serializable` |
| Tests | `bloc_test` + `mocktail` |
| Lints | `very_good_analysis` |

### Quick start

```bash
cd flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

```bash
flutter test
```

**Slices implemented:** 36 complete, 1 planned.
Features: `users`, `posts`, `tiers`, `core/auth`, `core/rbac`,
`core/routing`, `core/i18n`.

## Acknowledgements

This project draws ideas and patterns from:

- **[benavlabs/fastapi-boilerplate](https://github.com/benavlabs/fastapi-boilerplate)** —
  the original FastAPI scaffold (MIT, © 2023 Igor Magalhães); heavily reworked
  into Vertical Slice + Hexagonal architecture.
- **[github/spec-kit](https://github.com/github/spec-kit)** — Spec-Driven Development
  methodology and workflow.
- **[Kiro](https://kiro.dev/)** — spec-first AI development approach.
- **[JetBrains Junie](https://www.jetbrains.com/junie/)** — AI coding assistant concepts.
- **[mattpocock/skills](https://github.com/mattpocock/skills)** — prompt and skill patterns.

## License

The original FastAPI boilerplate in `api/` is MIT-licensed
(see [`api/LICENSE.md`](api/LICENSE.md)).
All other code in this repository is the author's own work.
