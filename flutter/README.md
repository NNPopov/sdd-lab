# sdd-lab Flutter Client

Cross-platform client (iOS-first) for the sdd-lab API.

**Architecture:** Vertical Slice + Hexagonal. Each feature is split into slices; inside each slice — ports (narrow interfaces in `domain/ports/`) and adapters (implementations in `data/`).

Development is iterative and spec-driven: each new slice goes through a full specification cycle — PRD → plan → requirements → validation → tests — and is considered done only when the outside-in acceptance test turns green.

## Stack

| Concern | Choice |
|---|---|
| State | `flutter_bloc` 9.x — Cubit by default, Bloc when event traceability is needed |
| DI | `get_it` + `injectable` |
| Navigation | `auto_route` 9.x |
| HTTP | `dio` + `retrofit` |
| Serialization | `freezed` + `json_serializable` |
| Localization | `slang` (en-US · es-ES · ru-RU · uk-UA) |
| Tests | `bloc_test` + `mocktail` + `flutter_test` |
| Lints | `very_good_analysis` |
| Metrics | `dart_code_linter` (cyclomatic ≤ 10, params ≤ 5, nesting ≤ 5, SLOC ≤ 50) |

## Quick start

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

```bash
flutter test
```

## Architecture gate

Run `scripts/check_arch.sh` to verify four layers in sequence:

1. **dart format** — no formatting drift (`dart format --set-exit-if-changed lib/ test/`)
2. **dart analyze** — no analyzer warnings
3. **dart_code_linter metrics** — complexity, parameter count, nesting, and SLOC thresholds (configured in `analysis_options.yaml`)
4. **Import boundary checks** — grep-based, zero extra dependencies:
   - `domain/` is pure Dart — no Flutter, Dio, or infra packages
   - `presentation/` does not call HTTP directly
   - `core/` does not import `features/` (exception: `app_router.dart` composition root)
   - Feature isolation: `users`, `posts`, and `tiers` do not import each other
   - No `setState` in widgets that already use a Cubit or Bloc

Exit code `0` means all checks passed; non-zero means at least one violation was found.

## Slices

**38 complete, 6 planned.** Features: `users`, `posts`, `tiers`, `core/auth`, `core/rbac`,
`core/routing`, `core/i18n`, `core/quality`.
See `specs/roadmap.md` for the full index.
