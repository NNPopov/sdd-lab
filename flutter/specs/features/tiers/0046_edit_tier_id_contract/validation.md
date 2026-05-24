# 0046 · edit_tier_id_contract — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Log in as superuser. Navigate to any tier in the tier list. Open tier details. Tap the edit (pencil) icon in the AppBar. | The edit form opens and the name field is pre-populated with the tier's current name. |
| M2 | On the edit form, change the name to a new valid string and tap Save. | A success snackbar appears. The form closes. The tier-details AppBar title immediately shows the new name. |
| M3 | Open the edit form. Clear the name field entirely and tap Save. | A validation error is shown below the field. No network request is made. The screen stays open. |
| M4 | Open the edit form. With the backend returning 404 for this tier ID (simulate or use a deleted tier), tap Save. | A "not found" error snackbar is shown. The screen stays open. No navigation occurs. |
| M5 | Open the edit form. With the backend returning 403 (simulate or revoke permissions between load and submit), tap Save. | A "permission denied" error snackbar is shown. The screen stays open. No navigation occurs. |
| M6 | Open the edit form. Tap Save with a valid name. Immediately observe the Save button before the response arrives. | The Save button is disabled and shows a small circular progress indicator instead of the label text. |
| M7 | Log in as a non-superuser (regular user). Navigate to any tier details screen. | The edit (pencil) icon is absent from the AppBar. The delete button is also absent. |
| M8 | As a superuser, navigate to tier details and tap the edit icon. Observe the URL or route path in the navigation stack. | The route path is `tiers/<id>/edit` where `<id>` is an integer (e.g. `tiers/3/edit`), not a string name. |
| M9 | Inspect the outgoing HTTP request when tapping Save on a valid edit form (via network proxy or device logs). | The request is `PATCH /tier/<id>` with body `{"name":"<new-name>"}` — not `new_name` and not a string in the path. |
| M10 | After a successful edit, tap Back from tier details to return to the tier list. Tap the same tier again to reopen its details. | The tier in the list and in tier details reflects the updated name (no stale data). |

## Code review

- [ ] `EditTierData` has fields `tierId: int` and `name: String`; fields `tierCurrentName` and `newName` do not exist anywhere in the file.
- [ ] `EditTierRequestDto.name` has no `@JsonKey` annotation — the serialised JSON key is `"name"`.
- [ ] `EditTierAdapter.call` contains an inner `on DioException catch (e)` block and an outer `catch (e, st)` block that calls `_logger.error(...)` and returns `Left(const Failure.unknown())`.
- [ ] `TiersApiClient.patchTier` is declared as `@PATCH('/tier/{id}') Future<void> patchTier(@Path('id') int id, @Body() EditTierRequestDto body)`.
- [ ] `app_router.dart` lists the `EditTierRoute` path as `':id/edit'` (not `':name/edit'`).
- [ ] `EditTierPage` declares `@PathParam('id') required this.tierId` (int) and `@QueryParam('name') required this.tierName` (String).
- [ ] `EditTierScreen` receives `tierId: int` and `tierName: String`; it builds `EditTierData(tierId: widget.tierId, name: _nameController.text.trim())` on submit.
- [ ] `EditTierCubit.submit` emits `EditTierState.success(newName: data.name)` on the right branch.
- [ ] `EditTierState` is annotated with `@freezed` and declared as a `sealed class`.
- [ ] No hardcoded UI strings in `EditTierScreen` — all text is accessed via `context.t.tiers.editTier.*`.
- [ ] No `setState` calls in `EditTierScreen` or `_EditTierScreenState`.
- [ ] `edit_tier` source files import only from `edit_tier/`, `_shared/`, and `core/`; no imports from other `tiers` slices.
- [ ] In `tier_details_screen.dart`, exactly one line was changed: the `EditTierRoute(...)` call now includes `tierId: widget.tierId`. No other file in `tier_details/` was modified.
- [ ] All three existing unit tests (`edit_tier_adapter_test`, `edit_tier_usecase_test`, `edit_tier_cubit_test`) use `EditTierData(tierId: ..., name: ...)` — not the old field names.
- [ ] A widget test exists at `test/features/tiers/edit_tier/presentation/edit_tier_screen_test.dart` covering: pre-filled form, submit triggers cubit, success snackbar, failure snackbar.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
