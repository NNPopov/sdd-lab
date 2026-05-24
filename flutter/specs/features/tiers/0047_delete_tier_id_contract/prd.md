# PRD 0047 — delete_tier: switch delete-tier contract from name to id

## Problem Statement

The backend API for deleting a tier has changed its identifier:
`DELETE /tier/{name}` is now `DELETE /tier/{id}`. The Flutter client still
passes a string name in the path, causing all delete requests to fail.

## Solution

Update the `delete_tier` slice so that the API client, port, use-case, cubit,
and all presentation code use `int id` as the path identifier. The tier name is
passed separately to `DeleteTierButton` so the confirmation dialog can still
display it, giving the user a clear indication of which tier is about to be
deleted.

## User Stories

1. As a superuser, I want to delete a tier by pressing the delete button on the
   tier detail screen so that I can remove obsolete tiers.
2. As a superuser, I want a confirmation dialog showing the tier name before
   deletion so that I can verify I am deleting the correct tier.
3. As a superuser, I want to see a success snackbar and be navigated back to
   the list after a successful deletion so that I know the operation completed.
4. As a superuser, I want to see a "not found" message when the tier was
   already deleted so that I understand the concurrent change.
5. As a superuser, I want to see a "forbidden" error message when my permissions
   are revoked mid-session so that I understand why the deletion failed.
6. As a non-superuser, I want the delete button to be hidden so that I cannot
   accidentally trigger a deletion.

## Implementation Decisions

- **API client:** `deleteTier(@Path('id') int id)` — path param type changes
  from `String` to `int`, path template changes from `/tier/{name}` to
  `/tier/{id}`.
- **Port:** `DeleteTierPort.call(int id)` — param type changes from
  `String name` to `int id`.
- **Use-case:** `DeleteTierUseCase.call({required int id, required bool isSuperuser})`
  — param renamed from `name` to `id`, type changes from `String` to `int`.
- **Cubit:** `DeleteTierCubit.confirmAndDelete(int tierId)` — param type
  changes from `String tierName` to `int tierId`.
- **Widget (`DeleteTierButton`):** receives both `tierId: int` and
  `tierName: String`. The `tierId` is passed to `confirmAndDelete`; the
  `tierName` is passed to the confirmation dialog for display.
- **Call-site in tier-details screen:** reads `tierId` and `tier.name` from the
  loaded state and passes both to `DeleteTierButton`.

## Testing Decisions

Good tests verify external behavior only — they do not assert on private
fields, internal method calls, or adapter implementation details.

- **Adapter unit test:** mock `TiersApiClient`; assert `call(id)` returns
  `Right(unit)` on 204, `Left(Failure.notFound())` on 404,
  `Left(Failure.unauthorized())` on 401, `Left(Failure.forbidden())` on 403,
  `Left(Failure.unknown())` on unexpected exception.
- **Use-case unit test:** mock port; assert permission guard short-circuits
  with `Left(Failure.permissionDenied())` when `isSuperuser` is false; assert
  port is called with the given `id` otherwise.
- **Cubit test (`bloc_test`):** cover `initial → confirming`, `confirming →
  initial (cancel)`, `confirming → deleting → success`, `confirming → deleting
  → notFound`, `confirming → deleting → failure`.
- **Widget test:** mount `DeleteTierButton` with a mocked cubit; assert
  confirmation dialog shows `tierName`; assert `confirmAndDelete(tierId)` is
  called on confirm; assert success snackbar and pop on success state.

## Out of Scope

- Changes to `tier_details` or `edit_tier` slices (covered by PRDs 0045 and
  0046).
- Changing the confirmation dialog wording beyond what is necessary.

## Further Notes

- `auto_route` code-gen does not need to be re-run for this slice — the delete
  action is triggered from within `TierDetailsPage`, not via a separate route.
- `freezed` / `json_serializable` code-gen does not need to be re-run — no
  DTOs are modified in this slice.
