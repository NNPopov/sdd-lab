# 0045 · tier_details_id_contract — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open the tiers tab as a superuser. Tap any tier in the list. | Navigation pushes; the URL/route path contains the tier's numeric id (e.g. `tiers/3`), not its name. |
| M2 | Repeat M1 with a slow/throttled network connection. Observe the AppBar title the instant the screen opens, before the API response arrives. | AppBar title shows the tier name supplied by the list screen (query param) — not blank. |
| M3 | While the screen from M2 is still loading, observe the body. | A circular progress indicator is visible in the body centre. |
| M4 | Allow M2 to complete (API responds 200). | AppBar title updates to `tier.name` from the response. The detail card shows the tier's name, numeric id, and creation date. |
| M5 | Open tier details for a tier that has been renamed since the list last refreshed (name in list is stale). | AppBar title changes from the stale query-param name to the fresh API name once loaded (F5). |
| M6 | Log in as a user who does not have the `manageTiers` permission. Open a tier details URL directly (deep-link). | Screen shows the "permission denied" message instead of the detail card. No spinner is shown. |
| M7 | Open a tier details URL with an id that does not exist (e.g. `/tiers/99999`). | Screen shows the "not found" message. No retry button is visible. |
| M8 | With a working id, cut network connectivity and load tier details. | Generic error message is shown with a retry button. |
| M9 | While on the error screen from M8, restore connectivity and tap Retry. | Spinner reappears in the body; tier detail card loads successfully. |
| M10 | Open tier details as a superuser (manageTiers + isSuperuser). | Edit (pencil) icon and delete (trash) icon are both visible in the AppBar. |
| M11 | Tap the edit icon in M10, rename the tier, save. | The tier details screen reloads in place. AppBar shows the new name. The URL still contains the original numeric id. |
| M12 | Open tier details as a regular authenticated user (manageTiers but not superuser). | Neither the edit nor the delete icon appears in the AppBar. |
| M13 | Open tier details as an unauthenticated user navigating via direct URL. | Auth guard redirects to login (no detail screen is shown). |
| M14 | Simulate a 401 response (e.g. force-expire the token, then open tier details). | Screen shows a generic error (the 401 is mapped to `UnauthorizedFailure`). |
| M15 | Simulate a 403 response (e.g. remove `manageTiers` server-side while the client still has the permission cached). | Screen shows a generic error (the 403 is mapped to `ForbiddenFailure`). |
| M16 | From the list screen, tap a tier, confirm the detail loads, then press Back. Observe the list. | Back navigation works; list is still visible and scroll position is preserved. |

## Code review

- [ ] `GetTierPort.call` signature is `Future<Either<Failure, TierDetail>> call(int id)` — no `String name` parameter remaining.
- [ ] `GetTierUsecase.call(int id)` — short-circuits with `Left(Failure.permissionDenied())` when `manageTiers` is absent, otherwise delegates to port with `id`.
- [ ] `GetTierAdapter.call(int id)` — passes `id` to `_api.getTier(id)`. Method has two-level error handling: inner `on DioException catch (e)` mapping 401→`UnauthorizedFailure`, 403→`ForbiddenFailure`, 404→`NotFoundFailure`, other→`ServerFailure`; outer `catch (e, st)` calls `_logger.error(...)` and returns `Left(Failure.unknown())`.
- [ ] `TiersApiClient.getTier` annotation is `@GET('/tier/{id}')` with `@Path('id') int id` — the old `/tier/{name}` template and `String name` parameter are gone.
- [ ] Only the `getTier` method in `TiersApiClient` was changed — `patchTier` and `deleteTier` still use `String name`.
- [ ] `TierDetailsCubit.load(int id)` and `retry(int id)` — no `String` overload remains; no id is stored in the cubit itself.
- [ ] `TierDetailsPage` (`@RoutePage()`) has `@PathParam('id') int tierId` and `@QueryParam('name') String tierName`; both are forwarded to `TierDetailsScreen`.
- [ ] `app_router.dart` tiers-tab child route for `TierDetailsRoute.page` uses `path: ':id'` (not `':name'`).
- [ ] `TierDetailsScreen` constructor accepts `int tierId` and `String tierName`. `initState` calls `cubit.load(widget.tierId)`.
- [ ] AppBar title is a `BlocBuilder<TierDetailsCubit, TierDetailsState>` that returns `Text(widget.tierName)` for initial/loading/error states and `Text(tier.name)` for the loaded state — no `setState` present.
- [ ] Retry button `onPressed` calls `context.read<TierDetailsCubit>().retry(widget.tierId)` — not `retry(widget.tierName)`.
- [ ] Edit button `onPressed` passes `widget.tierName` to `EditTierRoute` and on success replaces the route with `TierDetailsRoute(tierId: widget.tierId, tierName: newName)`.
- [ ] `ListTiersScreen` `TierDetailsRoute` call passes both `tierId: tiers[index].id` and `tierName: tiers[index].name`.
- [ ] No `import` inside `tier_details/` references another slice of the `tiers` feature except via `_shared/`.
- [ ] No hardcoded UI strings in `tier_details/presentation/` — all user-visible text uses `context.t.*` slang keys.
- [ ] `domain/` files in `tier_details/` import only `dartz`, `freezed_annotation`, or pure Dart — no `package:flutter/*` or `package:dio/*`.
- [ ] Existing adapter test updated: all `adapter('Free')` calls replaced with `adapter(1)`.
- [ ] Existing cubit test updated: all `cubit.load('Free')` / `cubit.retry('Free')` replaced with `cubit.load(1)` / `cubit.retry(1)`.
- [ ] New use-case test exists at `test/features/tiers/tier_details/domain/usecases/get_tier_usecase_test.dart` covering: permission-denied short-circuit, success pass-through, failure pass-through.
- [ ] New widget test exists at `test/features/tiers/tier_details/presentation/tier_details_screen_test.dart` covering: AppBar shows `tierName` during loading, AppBar shows `tier.name` when loaded, not-found message, generic error + retry button.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
