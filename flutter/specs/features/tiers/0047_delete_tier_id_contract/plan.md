# Plan 0047 — delete_tier: switch delete-tier contract from name to id

## Task

Migrate the `delete_tier` slice so that it uses `int id` (not `String name`) as the
path identifier when calling `DELETE /tier/{id}`. No new files are created; every
change is a param type/name swap inside the existing slice plus a one-line update
in `_shared/` and one line in the `tier_details` call-site.

---

## Context

READ:
- `CLAUDE.md` — hard rules, verification checklist
- `lib/features/tiers/delete_tier/**` — all files, this is the slice under change
- `lib/features/tiers/_shared/data/tiers_api_client.dart` — `deleteTier` signature to update
- `lib/features/tiers/tier_details/presentation/tier_details_screen.dart` — call-site to update
- `test/features/tiers/delete_tier/**` — all existing tests to update
- `agent_docs/error_handling.md` — adapter catch-all pattern

DO NOT READ:
- `lib/features/tiers/list_tiers/**`
- `lib/features/tiers/create_tier/**`
- `lib/features/tiers/edit_tier/**`
- `lib/features/tiers/tier_details/application/**`, `data/**`, `domain/**`

---

## API

```
DELETE /tier/{id}
Header: Authorization: Bearer <token>
Response 204: no body

Errors:
  401 — token invalid
  403 — caller is not a superuser
  404 — tier with this id does not exist
```

**Key difference from the old contract:**
- Path param type: `String name` → `int id`  (URL: `/tier/42`, not `/tier/free`)

---

## Files to Modify

```
lib/features/tiers/_shared/data/
└── tiers_api_client.dart              ← deleteTier path + param type

lib/features/tiers/delete_tier/
├── domain/
│   ├── ports/
│   │   └── delete_tier_port.dart      ← call(String name) → call(int id)
│   └── usecases/
│       └── delete_tier_usecase.dart   ← required String name → required int id
├── data/
│   └── delete_tier_adapter.dart       ← call(String name) → call(int id)
├── application/
│   └── delete_tier_cubit.dart         ← confirmAndDelete(String) → confirmAndDelete(int)
└── presentation/
    └── delete_tier_button.dart        ← add tierId:int param; pass to confirmAndDelete

lib/features/tiers/tier_details/presentation/
└── tier_details_screen.dart           ← DeleteTierButton gains tierId param
```

No new source files. No files deleted.

Test files to modify or add:
```
test/features/tiers/delete_tier/data/delete_tier_adapter_test.dart      ← update
test/features/tiers/delete_tier/application/delete_tier_cubit_test.dart ← update
test/features/tiers/delete_tier/presentation/delete_tier_button_test.dart ← update
test/features/tiers/delete_tier/domain/usecases/delete_tier_usecase_test.dart ← CREATE
```

---

## Implementation Steps

### Step 1 — Port: `DeleteTierPort`

File: `lib/features/tiers/delete_tier/domain/ports/delete_tier_port.dart`

```dart
abstract class DeleteTierPort {
  Future<Either<Failure, Unit>> call(int id);  // was String name
}
```

### Step 2 — Use-case: `DeleteTierUseCase`

File: `lib/features/tiers/delete_tier/domain/usecases/delete_tier_usecase.dart`

```dart
Future<Either<Failure, Unit>> call({
  required int id,          // was: required String name
  required bool isSuperuser,
}) {
  if (!isSuperuser) {
    return Future.value(const Left(Failure.permissionDenied()));
  }
  return _port(id);         // was: _port(name)
}
```

### Step 3 — Shared API client: `TiersApiClient`

File: `lib/features/tiers/_shared/data/tiers_api_client.dart`

Change the `deleteTier` method:

```dart
@DELETE('/tier/{id}')
Future<void> deleteTier(@Path('id') int id);  // was @Path('name') String name
```

**IMPORTANT:** `_shared/` is outside the slice boundary. After this file is saved, run:
```
dart run build_runner build --delete-conflicting-outputs
```
to regenerate `tiers_api_client.g.dart`.

### Step 4 — Adapter: `DeleteTierAdapter`

File: `lib/features/tiers/delete_tier/data/delete_tier_adapter.dart`

Two changes: signature type and the API call argument:

```dart
@override
Future<Either<Failure, Unit>> call(int id) async {  // was String name
  try {
    try {
      await _api.deleteTier(id);                     // was name
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_mapHttp(e));
    }
  } on Object catch (e, st) {
    _logger.error(
      'DeleteTierAdapter.call failed unexpectedly',
      error: e,
      stackTrace: st,
    );
    return const Left(Failure.unknown());
  }
}
```

The `_mapHttp` method is unchanged.

### Step 5 — Cubit: `DeleteTierCubit`

File: `lib/features/tiers/delete_tier/application/delete_tier_cubit.dart`

```dart
Future<void> confirmAndDelete(int tierId) async {   // was String tierName
  emit(const DeleteTierState.deleting());
  final isSuperuser = _authCubit.currentUser?.isSuperuser ?? false;
  final result = await _deleteTier(id: tierId, isSuperuser: isSuperuser); // was name: tierName
  result.fold(
    (failure) => failure is NotFoundFailure
        ? emit(const DeleteTierState.notFound())
        : emit(DeleteTierState.failure(failure)),
    (_) => emit(const DeleteTierState.success()),
  );
}
```

`requestConfirmation()` and `cancel()` are unchanged.

### Step 6 — Widget: `DeleteTierButton`

File: `lib/features/tiers/delete_tier/presentation/delete_tier_button.dart`

Add `tierId: int` alongside the existing `tierName: String`. The `tierId` is passed
to `confirmAndDelete`; `tierName` continues to be displayed in the confirmation dialog.

```dart
class DeleteTierButton extends StatelessWidget {
  const DeleteTierButton({
    required this.tierId,      // NEW
    required this.tierName,
    super.key,
  });

  final int tierId;            // NEW
  final String tierName;
  // ...
}
```

Inside `_DeleteTierButtonInner`, update the `confirmAndDelete` call:

```dart
unawaited(
  context.read<DeleteTierCubit>().confirmAndDelete(tierId),  // was tierName
);
```

Pass both fields down to `_DeleteTierButtonInner` as well.

### Step 7 — Call-site: `TierDetailsScreen`

File: `lib/features/tiers/tier_details/presentation/tier_details_screen.dart`

Only one line changes — the `DeleteTierButton` construction:

```dart
// Before
DeleteTierButton(tierName: widget.tierName),

// After
DeleteTierButton(tierId: widget.tierId, tierName: widget.tierName),
```

Do not touch any other line in this file.

### Step 8 — Code-gen

Run once after all source edits are saved:

```
dart run build_runner build --delete-conflicting-outputs
```

Regenerates: `tiers_api_client.g.dart`.

`delete_tier_state.dart` uses `freezed` but its shape does not change — no regeneration
needed for it beyond what `build_runner` does globally.

### Step 9 — Update existing tests

**a) `test/features/tiers/delete_tier/data/delete_tier_adapter_test.dart`**

- In `_dioError` helper, update path cosmetically: `path: '/tier/1'`.
- Replace `adapter('Free')` with `adapter(1)` in every test case.
- Replace `apiClient.deleteTier(any())` stubs with `apiClient.deleteTier(any())` — the
  matcher stays `any()`, only the test call argument changes to `1`.

**b) `test/features/tiers/delete_tier/application/delete_tier_cubit_test.dart`**

- Replace every `confirmAndDelete('Free')` with `confirmAndDelete(1)`.
- Update use-case mock matchers: `name: any(named: 'name')` → `id: any(named: 'id')`.
- Update explicit use-case stub calls from `name: any(named: 'name'), isSuperuser: false`
  to `id: any(named: 'id'), isSuperuser: false`.

**c) `test/features/tiers/delete_tier/presentation/delete_tier_button_test.dart`**

- Update `DeleteTierButton(tierName: 'gold')` to
  `DeleteTierButton(tierId: 1, tierName: 'gold')`.

### Step 10 — Add missing use-case test

File: `test/features/tiers/delete_tier/domain/usecases/delete_tier_usecase_test.dart`
(create new)

Cover two cases:

1. **Permission denied** — `isSuperuser: false` → returns `Left(PermissionDenied())`;
   port is never called.
2. **Success** — `isSuperuser: true`, port returns `Right(unit)` → use-case returns
   `Right(unit)`; port is called with `id: 42`.

```dart
group('DeleteTierUseCase', () {
  late MockDeleteTierPort port;

  setUp(() {
    port = MockDeleteTierPort();
  });

  test('returns Left(permissionDenied) when isSuperuser is false', () async {
    final useCase = DeleteTierUseCase(port);
    final result = await useCase(id: 42, isSuperuser: false);
    expect(result, const Left(Failure.permissionDenied()));
    verifyNever(() => port(any()));
  });

  test('returns Right(unit) when isSuperuser is true and port succeeds', () async {
    when(() => port(42)).thenAnswer((_) async => const Right(unit));
    final useCase = DeleteTierUseCase(port);
    final result = await useCase(id: 42, isSuperuser: true);
    expect(result, const Right<Failure, Unit>(unit));
    verify(() => port(42)).called(1);
  });
});
```

### Step 11 — Verify

```
dart format .
dart analyze
flutter test test/features/tiers/delete_tier/
```

All tests must be green. No warnings from `dart analyze`.

---

## What NOT to do

- Do NOT change `DeleteTierState` — its shape is unchanged.
- Do NOT change `DeleteTierConfirmationDialog` — it still receives `tierName: String`
  for display and nothing else.
- Do NOT touch `tier_details/application/`, `data/`, `domain/` — only the one
  presentation line that calls `DeleteTierButton`.
- Do NOT change `edit_tier` or `create_tier` slices.
- Do NOT add a separate route for `delete_tier` — it has no screen.
- Do NOT push changes to `pubspec.yaml` — no new packages required.

---

## Report

On completion, provide:

1. List of every file modified (no file should appear that is not in this plan).
2. Confirmation that `tier_details/application/`, `data/`, `domain/` were not touched.
3. Confirmation that `dart analyze` passes with zero warnings.
4. Confirmation that `flutter test test/features/tiers/delete_tier/` is green.
5. Output of the final `flutter test` run (pass/fail counts).
