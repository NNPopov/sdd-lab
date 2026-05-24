# 0047 · delete_tier_id_contract — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Log in as a **superuser**, open a tier detail screen. | The delete (trash) icon button is visible in the AppBar action area. |
| M2 | Log in as a **non-superuser** (regular user), open a tier detail screen. | The delete button is absent; no trash icon appears in the AppBar. |
| M3 | Log in as a superuser, open a tier detail, tap the delete button. | A confirmation dialog appears containing the tier's name (e.g. "Free"). |
| M4 | In the confirmation dialog, tap **Cancel**. | The dialog closes; the user remains on the tier detail screen; no deletion is made; the delete button is still enabled. |
| M5 | Tap the delete button again after cancelling (from M4). | The confirmation dialog appears again, proving the cubit returned to the initial state. |
| M6 | In the confirmation dialog, tap the **Confirm** (destructive) button for a tier that exists. | The dialog closes, a success snackbar appears, and the screen is popped back to the tiers list. |
| M7 | While the deletion is in flight (tap Confirm on a slow connection), observe the delete button. | The trash icon is replaced by a circular progress indicator; the button is non-interactive and cannot be tapped again. |
| M8 | Using a network proxy (or test environment), intercept the DELETE call and verify the request URL. | The URL is `DELETE /tier/{id}` where `{id}` is an integer (e.g. `/tier/3`), not a string name. |
| M9 | Simulate a **404** response (tier deleted concurrently) and confirm. | A "not found" snackbar is shown and the screen is popped back to the tiers list. |
| M10 | Simulate a **403** response (permissions revoked mid-session) and confirm. | A "forbidden" snackbar is shown; the screen is NOT popped; the user remains on the detail screen. |
| M11 | Simulate a **401** response and confirm. | An "unauthorized" snackbar is shown; the screen is NOT popped. |
| M12 | Simulate an unexpected network error (e.g. connection timeout) and confirm. | A generic error snackbar is shown; the screen is NOT popped. |
| M13 | After a failed deletion (M10–M12), tap the delete button again. | The confirmation dialog appears normally, proving the cubit is still functional. |

## Code review

- [ ] `TiersApiClient.deleteTier` is annotated `@DELETE('/tier/{id}')` and its parameter is `@Path('id') int id` — the old `@Path('name') String name` is gone.
- [ ] `DeleteTierPort.call` signature is `Future<Either<Failure, Unit>> call(int id)`.
- [ ] `DeleteTierUseCase.call` named parameter is `required int id`; internal call is `_port(id)`.
- [ ] `DeleteTierCubit.confirmAndDelete` parameter is `int tierId`; use-case is invoked as `_deleteTier(id: tierId, isSuperuser: ...)`.
- [ ] `DeleteTierButton` constructor has `required this.tierId` (`int`) in addition to `required this.tierName` (`String`); `tierId` is passed to `confirmAndDelete`, `tierName` is passed to the confirmation dialog.
- [ ] `TierDetailsScreen` passes `tierId: widget.tierId` to `DeleteTierButton` alongside `tierName: widget.tierName`.
- [ ] `DeleteTierAdapter.call` has an inner `on DioException catch (e)` and an outer `catch (e, st)` with `_logger.error(...)`.
- [ ] The outer catch in `DeleteTierAdapter` passes both `error: e` and `stackTrace: st` to `_logger.error`; it returns `Left(Failure.unknown())` and does not rethrow.
- [ ] No hardcoded UI strings in `delete_tier_button.dart` or `delete_tier_confirmation_dialog.dart` — all text accessed via `context.t.tiers.deleteTier.*`.
- [ ] `DeleteTierState` shape is unchanged: same five variants (`initial`, `confirming`, `deleting`, `success`, `notFound`, `failure`).
- [ ] `delete_tier` imports nothing from `edit_tier`, `tier_details`, `create_tier`, or `list_tiers` — only `_shared/` is permitted.
- [ ] `delete_tier/domain/` imports only `dartz`, `freezed_annotation`, and pure Dart packages — no `flutter` or `dio` imports.
- [ ] No route page or `@RoutePage()` annotation was added to `delete_tier/presentation/` — the slice has no screen of its own.
- [ ] Only the `DeleteTierButton(tierId: ..., tierName: ...)` line was changed in `tier_details_screen.dart` — no other lines in that file were modified.
- [ ] The existing adapter, cubit, and widget tests compile and assert against `int` arguments (`1` or similar) instead of `String` arguments (`'Free'`).
- [ ] A new use-case test file exists at `test/features/tiers/delete_tier/domain/usecases/delete_tier_usecase_test.dart` covering permission-denied and success paths.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
