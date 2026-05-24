# PRD 0046 — edit_tier: switch patch-tier contract from name to id

## Problem Statement

The backend API for editing a tier has changed its identifier and request body:
`PATCH /tier/{name}` with body `{"new_name": "..."}` is now
`PATCH /tier/{id}` with body `{"name": "..."}`. The Flutter client still sends
a string name in the path and `new_name` in the body, causing all patch
requests to fail.

## Solution

Update the `edit_tier` slice so that the API client, DTO, port, use-case,
cubit, and all presentation code use `int id` as the path identifier and `name`
as the request body field. The edit route receives the tier id as a path param
and the current tier name as a query param for pre-populating the form. After a
successful edit, the screen returns the new name to the caller so the
tier-details screen can update its AppBar title immediately.

## User Stories

1. As a superuser, I want to edit a tier's name so that I can keep the tier
   list up to date.
2. As a superuser, I want the edit form to be pre-filled with the current tier
   name so that I can make incremental edits without retyping the whole name.
3. As a superuser, I want to see a success message after saving so that I know
   the change was applied.
4. As a superuser, I want to see a "not found" error message when the tier no
   longer exists so that I understand it was deleted concurrently.
5. As a superuser, I want to see a "forbidden" error message when my permissions
   are revoked mid-session so that I understand why the save failed.
6. As a non-superuser, I want the edit action to be blocked so that I cannot
   accidentally modify a tier.

## Implementation Decisions

- **API client:** `patchTier(@Path('id') int id, @Body() EditTierRequestDto body)`
  — path param type changes from `String` to `int`, path template changes from
  `/tier/{name}` to `/tier/{id}`.
- **DTO:** `EditTierRequestDto` field `name` loses the `@JsonKey(name: 'new_name')`
  annotation — the JSON key is now `name` directly.
- **Domain entity:** `EditTierData` fields change: `tierCurrentName: String` →
  `tierId: int`; `newName: String` → `name: String`.
- **Port:** `EditTierPort.call(EditTierData data)` — signature unchanged; only
  `EditTierData` shape changes.
- **Use-case:** `EditTierUseCase.call({required EditTierData data, required bool isSuperuser})`
  — unchanged; passes updated `EditTierData` through to the port.
- **Cubit:** `EditTierCubit.submit({required EditTierData data, required bool isSuperuser})`
  — unchanged; emits `EditTierState.success(newName: data.name)` on success.
- **Route params:** `EditTierPage` receives `@PathParam('id') int tierId` and
  `@QueryParam('name') String tierName`. Path in `app_router.dart` changes from
  `tiers/:name/edit` to `tiers/:id/edit`.
- **Screen:** `EditTierScreen` receives `tierId: int` and `tierName: String`.
  The name field is pre-populated from `tierName`. On success, the screen pops
  with the new name string so the caller can update its AppBar.
- **Navigation from tier-details:** caller passes both `tierId` and current
  `tier.name` when pushing `EditTierRoute`.

## Testing Decisions

Good tests verify external behavior only — they do not assert on private
fields, internal method calls, or adapter implementation details.

- **Adapter unit test:** mock `TiersApiClient`; assert `call(EditTierData)`
  returns `Right(unit)` on 204, `Left(Failure.notFound())` on 404,
  `Left(Failure.forbidden())` on 403, `Left(Failure.unknown())` on unexpected
  exception. Verify the correct `tierId` is passed as path param and `name`
  appears in the request body (not `new_name`).
- **Use-case unit test:** mock port; assert permission guard short-circuits
  with `Left(Failure.permissionDenied())` when `isSuperuser` is false; assert
  port is called with the given `EditTierData` otherwise.
- **Cubit test (`bloc_test`):** cover `initial → submitting → success(newName)`,
  `initial → submitting → failure(notFound)`, `initial → submitting → failure(forbidden)`.
- **Widget test:** mount `EditTierScreen` with a mocked cubit; assert form is
  pre-filled with `tierName`; assert submit triggers cubit; assert success
  snackbar and pop on success state; assert error snackbar on failure state.

## Out of Scope

- Changes to `tier_details` or `delete_tier` slices (covered by PRDs 0045 and
  0047).
- Renaming any tier fields beyond `new_name` → `name` in the request body.

## Further Notes

- `auto_route` code-gen must be re-run after changing `@PathParam` type and
  adding `@QueryParam` to `EditTierPage`.
- `freezed` / `json_serializable` code-gen must be re-run after removing
  `@JsonKey(name: 'new_name')` from `EditTierRequestDto`.
