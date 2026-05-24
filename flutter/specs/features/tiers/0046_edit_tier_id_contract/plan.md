# Plan 0046 — edit_tier: switch patch-tier contract from name to id

## Task

Migrate the `edit_tier` slice so that it uses `int id` (not `String name`) as the
path identifier when calling `PATCH /tier/{id}`, and `name` (not `new_name`) as the
JSON body field. No new files are created; every change is a field rename or type
change inside the existing slice plus minimal call-site updates in `_shared/` and
`app_router.dart`.

---

## Context

READ:
- `CLAUDE.md` — hard rules, verification checklist
- `lib/features/tiers/edit_tier/**` — all files, this is the slice under change
- `lib/features/tiers/_shared/data/tiers_api_client.dart` — `patchTier` signature to update
- `lib/core/routing/app_router.dart` — route path to update
- `lib/features/tiers/tier_details/presentation/tier_details_screen.dart` — navigation call to update
- `test/features/tiers/edit_tier/**` — all existing tests to update
- `agent_docs/error_handling.md` — adapter pattern (catch-all required)

DO NOT READ:
- `lib/features/tiers/list_tiers/**`
- `lib/features/tiers/create_tier/**`
- `lib/features/tiers/delete_tier/**`
- `lib/features/tiers/tier_details/application/**`, `data/**`, `domain/**`

---

## API

```
PATCH /tier/{id}
Header: Authorization: Bearer <token>
Body:   {"name": "new-tier-name"}
Response 204: no body

Errors:
  403 — caller is not a superuser
  404 — tier with this id does not exist
```

**Key differences from the old contract:**
- Path param type: `String name` → `int id`  (URL: `/tier/42`, not `/tier/free`)
- Body field: `new_name` → `name`  (JSON key changes, Dart field name stays `name`)

---

## Files to Modify

```
lib/features/tiers/_shared/data/
└── tiers_api_client.dart              ← patchTier path + param type

lib/features/tiers/edit_tier/
├── domain/
│   └── entities/
│       └── edit_tier_data.dart        ← tierCurrentName:String → tierId:int
│                                        newName:String → name:String
├── data/
│   ├── dto/
│   │   └── edit_tier_request_dto.dart ← remove @JsonKey(name:'new_name')
│   └── edit_tier_adapter.dart         ← data.tierCurrentName→data.tierId,
│                                        data.newName→data.name
├── application/
│   └── edit_tier_cubit.dart           ← data.newName→data.name in success emit
└── presentation/
    ├── edit_tier_route.dart            ← @PathParam id:int + @QueryParam name:String
    └── edit_tier_screen.dart           ← tierId:int param + updated EditTierData ctor

lib/core/routing/
└── app_router.dart                    ← ':name/edit' → ':id/edit'

lib/features/tiers/tier_details/presentation/
└── tier_details_screen.dart           ← EditTierRoute call adds tierId param
```

No new files. No files deleted.

---

## Implementation Steps

### Step 1 — Domain entity: `EditTierData`

File: `lib/features/tiers/edit_tier/domain/entities/edit_tier_data.dart`

```dart
class EditTierData {
  const EditTierData({required this.tierId, required this.name});

  final int tierId;
  final String name;
}
```

`tierId` replaces `tierCurrentName`; `name` replaces `newName`. No external packages —
`domain/` stays pure Dart.

### Step 2 — DTO: `EditTierRequestDto`

File: `lib/features/tiers/edit_tier/data/dto/edit_tier_request_dto.dart`

Remove the `@JsonKey(name: 'new_name')` annotation from the `name` field. The field
itself stays `name`. After this change the serialised key will be `"name"` (matching
the new backend contract).

```dart
@freezed
sealed class EditTierRequestDto with _$EditTierRequestDto {
  const factory EditTierRequestDto({
    required String name,    // ← no @JsonKey annotation
  }) = _EditTierRequestDto;

  factory EditTierRequestDto.fromJson(Map<String, dynamic> json) =>
      _$EditTierRequestDtoFromJson(json);
}
```

### Step 3 — Shared API client: `TiersApiClient`

File: `lib/features/tiers/_shared/data/tiers_api_client.dart`

Change the `patchTier` method:

```dart
@PATCH('/tier/{id}')
Future<void> patchTier(
  @Path('id') int id,           // was @Path('name') String name
  @Body() EditTierRequestDto body,
);
```

**IMPORTANT:** `_shared/` is outside the slice boundary. This change is mandatory for
the slice to compile. After this file is saved, run:
```
dart run build_runner build --delete-conflicting-outputs
```
to regenerate `tiers_api_client.g.dart` and `edit_tier_request_dto.g.dart`.

### Step 4 — Adapter: `EditTierAdapter`

File: `lib/features/tiers/edit_tier/data/edit_tier_adapter.dart`

Two field names change; structure stays identical:

```dart
await _api.patchTier(
  data.tierId,                             // was data.tierCurrentName
  EditTierRequestDto(name: data.name),     // was data.newName
);
```

The catch-all `catch (e, st)` with `_logger.error(...)` must remain unchanged.

### Step 5 — Cubit: `EditTierCubit`

File: `lib/features/tiers/edit_tier/application/edit_tier_cubit.dart`

One field reference changes in the success branch:

```dart
(_) => emit(EditTierState.success(newName: data.name)),  // was data.newName
```

The `EditTierState.success` field is still called `newName` (it holds the name that was
just saved, passed back to the caller so it can update its AppBar). Only the source
field on `EditTierData` changed.

### Step 6 — Route: `EditTierPage`

File: `lib/features/tiers/edit_tier/presentation/edit_tier_route.dart`

Add `tierId` as a path param; change `tierName` from `@PathParam` to `@QueryParam`:

```dart
@RoutePage()
class EditTierPage extends StatelessWidget {
  const EditTierPage({
    @PathParam('id') required this.tierId,
    @QueryParam('name') required this.tierName,
    super.key,
  });

  final int tierId;
  final String tierName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EditTierCubit>(),
      child: EditTierScreen(tierId: tierId, tierName: tierName),
    );
  }
}
```

After saving this file, `auto_route` code-gen must be re-run (same `build_runner`
command above). The generated `app_router.gr.dart` will reflect the new params.

### Step 7 — Screen: `EditTierScreen`

File: `lib/features/tiers/edit_tier/presentation/edit_tier_screen.dart`

Add `tierId` constructor param; use it when building `EditTierData`:

```dart
class EditTierScreen extends StatefulWidget {
  const EditTierScreen({required this.tierId, required this.tierName, super.key});

  final int tierId;
  final String tierName;
  // ...
}
```

Inside `_submit`:

```dart
unawaited(
  context.read<EditTierCubit>().submit(
    data: EditTierData(
      tierId: widget.tierId,              // was tierCurrentName: widget.tierName
      name: _nameController.text.trim(),  // was newName:
    ),
    isSuperuser: isSuperuser,
  ),
);
```

The `_errorMessage` switch already handles `ForbiddenFailure` at the `_` default branch
— add an explicit case to match the error mapping in the adapter:

```dart
String _errorMessage(Failure failure, Translations t) => switch (failure) {
  NotFoundFailure() => t.tiers.editTier.errors.notFound,
  PermissionDenied() => t.tiers.editTier.errors.permissionDenied,
  ForbiddenFailure() => t.tiers.editTier.errors.permissionDenied,
  _ => t.tiers.editTier.errors.generic,
};
```

### Step 8 — Router path

File: `lib/core/routing/app_router.dart`

Inside the Tiers tab children, change:

```dart
// Before
AutoRoute(
  page: EditTierRoute.page,
  path: ':name/edit',
  ...
),

// After
AutoRoute(
  page: EditTierRoute.page,
  path: ':id/edit',
  ...
),
```

### Step 9 — Navigation call-site in `tier_details_screen`

File: `lib/features/tiers/tier_details/presentation/tier_details_screen.dart`

This is the only caller that pushes `EditTierRoute`. Update it to pass both params:

```dart
// Before
EditTierRoute(tierName: widget.tierName)

// After
EditTierRoute(tierId: widget.tierId, tierName: widget.tierName)
```

The rest of `tier_details_screen.dart` is unchanged. Do not touch any other file in
the `tier_details` slice.

### Step 10 — Code-gen

Run once after all source edits are saved:

```
dart run build_runner build --delete-conflicting-outputs
```

This regenerates:
- `tiers_api_client.g.dart`
- `edit_tier_request_dto.g.dart` / `edit_tier_request_dto.freezed.dart`
- `app_router.gr.dart`

### Step 11 — Update existing tests

All three test files reference the old `EditTierData` constructor. Update each:

**a) `test/features/tiers/edit_tier/data/edit_tier_adapter_test.dart`**

- `const data = EditTierData(tierCurrentName: 'free', newName: 'basic')`
  → `const data = EditTierData(tierId: 1, name: 'basic')`
- Update `_dioError` path helper (cosmetic, not required but keeps it consistent):
  `path: '/tier/1'`
- In the success test, add a `verify` that `patchTier` was called with `1` as the
  first argument and a DTO with `name: 'basic'`:

```dart
verify(
  () => apiClient.patchTier(1, const EditTierRequestDto(name: 'basic')),
).called(1);
```

**b) `test/features/tiers/edit_tier/domain/usecases/edit_tier_usecase_test.dart`**

- `const data = EditTierData(tierCurrentName: 'free', newName: 'basic')`
  → `const data = EditTierData(tierId: 1, name: 'basic')`
- `registerFallbackValue(data)` automatically picks up the new value.

**c) `test/features/tiers/edit_tier/application/edit_tier_cubit_test.dart`**

- `const data = EditTierData(tierCurrentName: 'free', newName: 'basic')`
  → `const data = EditTierData(tierId: 1, name: 'basic')`
- The success state assertion `EditTierState.success(newName: 'basic')` is unchanged
  (the state field is still `newName`).

### Step 12 — Add missing widget test

File: `test/features/tiers/edit_tier/presentation/edit_tier_screen_test.dart` (create)

Cover the three observable UI states:

1. **Pre-filled form** — mount `EditTierScreen(tierId: 1, tierName: 'free')` with
   `EditTierCubit` stubbed at `EditTierInitial`; assert the text field shows `'free'`.
2. **Submit triggers cubit** — tap the Save button (with valid text); verify
   `cubit.submit(data: EditTierData(tierId:1, name:'free'), isSuperuser: true)` called.
3. **Success state** — emit `EditTierSuccess(newName: 'updated')`; assert snackbar
   with `t.tiers.editTier.success` is visible.
4. **Failure state** — emit `EditTierFailure(Failure.notFound())`; assert snackbar
   with `t.tiers.editTier.errors.notFound` is visible.

Wrap the widget in the standard `BlocProvider<EditTierCubit>` + `AuthCubit` (mocked
with `AuthAuthenticated` containing a superuser) test harness.

### Step 13 — Verify

```
dart format .
dart analyze
flutter test test/features/tiers/edit_tier/
```

All tests must be green. No warnings from `dart analyze`.

---

## What NOT to do

- Do NOT change `EditTierState` — the `success({required String newName})` field name
  stays as is; only the source (`EditTierData`) field was renamed.
- Do NOT touch `tier_details/application/`, `tier_details/data/`, or
  `tier_details/domain/` — only the single navigation line in the presentation file.
- Do NOT change `delete_tier` (slice 0047) or `tier_details` route params (slice 0045).
- Do NOT add `@JsonKey` back to `EditTierRequestDto.name` — the JSON key is now `name`.
- Do NOT rename `EditTierState.success.newName` to `name` — that would break the
  presentation listener and the cubit test in a way that adds no value.
- Do NOT push changes to `pubspec.yaml` — no new packages.

---

## Report

On completion, provide:

1. List of every file modified (no file should appear that is not in this plan).
2. Confirmation that `tier_details/application/`, `data/`, `domain/` were not touched.
3. Confirmation that `dart analyze` passes with zero warnings.
4. Confirmation that `flutter test test/features/tiers/edit_tier/` is green.
5. Output of the final `flutter test` run (pass/fail counts).
