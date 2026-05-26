# Feature Spec — 0048 current_user_id_field

> **Foundation slice of the `{username}` → `{user_id}` API migration.**
> Carry the numeric user `id` from `GET /user/me/` through to the domain
> `CurrentUser`. Additive only: a new required field plus the one-line mapping
> that stops dropping it. No UX, no route, no behavior change.

---

## 1. Header

Add a required `int id` to the `CurrentUser` domain entity (core/auth) and map
the `id` the DTO already receives from `GET /user/me/` into it. There is **no
screen, no route, no cubit, no use-case, and no adapter signature change** in
this slice. It is a pure entity + mapping change in `core/auth`, plus the
mechanical test fallout of making the field required.

---

## 2. Context

This slice lives in **`core/auth`**, not in a feature. It does **not** follow
the standard `domain/ports → data/adapter → application/cubit → presentation`
slice layout, because it adds no port, no use-case, no state, and no widget.

READ:
- `@CLAUDE.md` — fully.
- `@CONTEXT.md` — for the `id` = path-identity vs `username` = handle distinction.
- `@lib/core/auth/domain/entities/current_user.dart` — **edited** (add `id`).
- `@lib/core/auth/data/dto/current_user_dto.dart` — **edited** (`toDomain()` maps `id`).
- `@lib/core/auth/application/auth_cubit.dart` — read-only, to confirm `id`
  flows in via `CurrentUser` from `getCurrentUser()` and that no cubit logic
  needs to change.
- `@specs/features/tiers/0047_delete_tier_id_contract/` — prior art for the shape
  of an id-contract migration slice.

DO NOT READ:
- Any feature slice under `lib/features/**` (no feature is touched by this slice).
- `*.g.dart` / `*.freezed.dart` generated files.
- Routing, RBAC, navigation, localization — none are involved.

---

## 3. API

**No API change.** The endpoint and its payload are unchanged; this slice only
stops discarding a field that already arrives.

```
GET http://127.0.0.1:8000/api/v1/user/me/
Header: Authorization: Bearer <token>
Response 200:
{
  "id": 42,
  "name": "Ada Lovelace",
  "username": "ada",
  "email": "ada@example.com",
  "is_superuser": false,
  "is_moderator": false,
  "profile_image_url": null,
  "tier_id": 3
}
```

- `CurrentUserDto` **already** declares `required int id` and deserializes it
  from the `id` JSON key. No DTO shape change, therefore **no `build_runner`
  run is required**.
- `CurrentUser` is a hand-written `final class` (not `freezed`), so adding a
  field is also **not** codegen-affecting.
- `AuthSession` (login response) is unchanged — `id` flows in via `CurrentUser`
  from `GET /user/me/`, not from the token response.

Errors: unchanged from current `getCurrentUser()` behavior; out of scope here.

---

## 4. Target structure

No new files. Two existing production files are edited:

```
lib/core/auth/
├── domain/entities/current_user.dart   # EDIT: add `final int id` (required);
│                                        #       include in == and hashCode
└── data/dto/current_user_dto.dart       # EDIT: toDomain() maps id: id
```

Test fallout (constructions of `CurrentUser`, made required):

```
test/                                    # EDIT every existing CurrentUser(...)
                                         # construction to pass `id:`
                                         # (~26 files, ~42 sites — see step 3)
```

New test files for this slice's own coverage (added per default coverage):

```
test/core/auth/domain/entities/current_user_id_test.dart   # NEW: id in identity
test/core/auth/data/dto/current_user_dto_to_domain_test.dart # NEW: id mapped through
test/features/core/0048_current_user_id_field/
└── current_user_id_field_outside_in_test.dart              # NEW: acceptance gate (RED first)
```

> Layers that do not apply: there is **no** use-case, cubit transition, or screen
> state in this slice, so the use-case / bloc / widget layers of the default
> coverage have no new behavior to cover here. They are not waived in general —
> later migration slices (0050+) exercise them.

---

## 5. What to do

### Step 1 — Domain entity (`current_user.dart`)

Add a required `int id`:

- Add `required this.id` to the constructor (place it first, as the identity field).
- Add `final int id;`.
- Add `id == other.id` to `operator ==`.
- Add `id` to `Object.hash(...)` in `hashCode`.

Leave every other field, including `username` (the handle), untouched.

### Step 2 — DTO→domain mapping (`current_user_dto.dart`)

In `CurrentUserDtoX.toDomain()`, add `id: id,` to the `CurrentUser(...)`
construction. The DTO already exposes `id`; this is the one line that stops it
being dropped. Do not change the DTO factory, JSON keys, or generated code.

### Step 3 — Downstream re-green (mechanical, in scope)

Making `id` required breaks every existing `CurrentUser(...)` construction.

- Production code: exactly **one** site — the `toDomain()` mapping edited in
  step 2. After step 2 it already supplies `id`.
- Tests: every `CurrentUser(...)` construction across the suite (~26 files,
  ~42 sites at time of writing) must be updated to pass an `id`. Use a stable,
  distinct literal per construction so identity assertions elsewhere stay
  meaningful (e.g. `id: 1` unless a test already pins a specific user).
- Procedure: grep the whole `test/` tree for `CurrentUser(`, add `id:` to each
  construction, then run the full suite to confirm zero **new** failures
  (baseline-compare against `dev`, per the route-migration practice).

> This re-green is the slice's acceptance proof that the change is non-breaking
> in behavior: the entire existing suite stays green with only `id:` added.

### Step 4 — Verify

- `dart format .` — no diff.
- `dart analyze` — no warnings.
- **No `build_runner` run** — neither edited file is codegen-affecting.
- `flutter test` — full suite green (zero new failures vs. baseline).

---

## 6. Tests

Per default coverage, only the layers with new behavior are covered (entity +
mapping). No use-case / cubit / widget tests are added in this slice.

### a) `test/core/auth/domain/entities/current_user_id_test.dart` (entity unit)

- Two `CurrentUser` values **identical except for `id`** are **not equal**, and
  have **different** `hashCode`s.
- Two `CurrentUser` values **identical including `id`** are **equal**, and have
  the **same** `hashCode`.
- (Guard) changing only the `username` handle still produces inequality — i.e.
  the handle remains part of identity alongside `id`.

### b) `test/core/auth/data/dto/current_user_dto_to_domain_test.dart` (mapping unit)

- `toDomain()` on a DTO carrying a known `id` (e.g. `99`) produces a
  `CurrentUser` whose `id == 99`.
- The handle (`username`) and the other fields (`email`, `name`,
  `isSuperuser`, `isModerator`, `profileImageUrl`) are carried through
  unchanged by the same call.

### c) Outside-in acceptance test (RED first — written by `/slice-test-red`)

`test/features/core/0048_current_user_id_field/current_user_id_field_outside_in_test.dart`

- Drives the realistic path: a `CurrentUserDto` deserialized from a `GET
  /user/me/`-shaped JSON map (with `id`) is converted via `toDomain()`, and the
  resulting `CurrentUser.id` equals the server's `id`.
- Asserts the entity treats `id` as identity (the two values differing only by
  `id` are unequal).
- This single test is the slice's acceptance gate. The detailed scenario list
  is owned by `tests.md`.

---

## 7. Report (on completion of implementation)

- Files changed: `current_user.dart`, `current_user_dto.dart` (production);
  list of every test file touched for the re-green.
- Confirmation that **no feature slice** and **no other core module** changed.
- Confirmation that **no `build_runner`** run was needed and none was performed.
- Baseline comparison: existing suite has **zero new failures**; the slice's
  own new tests are green; the outside-in test went RED→GREEN.

---

## 8. What NOT to do

- ❌ Do **not** make `id` optional or give it a default — every authenticated
  user has one; an optional id models an impossible state.
- ❌ Do **not** touch `AuthSession`, the login flow, or the token response.
- ❌ Do **not** change `AuthCubit.isMe(String)` — that is slice 0050.
- ❌ Do **not** change any route path segment, `@PathParam`, port, or adapter
  signature.
- ❌ Do **not** change the DTO shape, JSON keys, or run `build_runner` — the DTO
  already deserializes `id`.
- ❌ Do **not** touch the `username` handle (display, login, self-rename).
- ❌ Do **not** add use-case / cubit / widget tests for this slice — there is no
  new behavior in those layers here.
- ❌ Do **not** edit production code in any feature slice; the only production
  edits are the two `core/auth` files above.
