# PRD 0045 — tier_details: switch get-tier contract from name to id

## Problem Statement

The backend API for retrieving tier details has changed its identifier: the
`GET /tier/{name}` endpoint now uses an integer `id` as the path parameter
(`GET /tier/{id}`). The Flutter client still passes a string `name`, which
causes every `GET` call to fail with a 404 or routing error in production.

## Solution

Update the `tier_details` slice so that the API client, port, use-case, cubit,
and all presentation code use `int id` as the identifier for loading tier
details. The list-tiers screen already has the `id` from the paginated
response, so navigation passes it naturally. The tier name is carried as an
additional query parameter for immediate display while the detail loads.

## User Stories

1. As a user with the `manageTiers` permission, I want to open a tier's detail
   screen so that I can view its name, id, and creation date.
2. As a user, I want the tier name to appear in the AppBar immediately (before
   the API response arrives) so that I do not see a blank title while loading.
3. As a user, I want the AppBar title to update to the freshly loaded name
   after the API response arrives so that it reflects any recent renames.
4. As a user, I want to see a "not found" message when a tier with the given id
   does not exist so that I understand the resource is gone.
5. As a user, I want a retry button when an unexpected error occurs so that I
   can recover without leaving the screen.
6. As a superuser, I want the edit and delete actions to be available on the
   detail screen after the tier loads so that I can manage the tier without
   navigating away.
7. As a developer, I want the deep-link URL for a tier detail to contain the
   numeric id (`tiers/:id`) so that bookmarked URLs remain stable across tier
   renames.

## Implementation Decisions

- **API client:** `getTier(@Path('id') int id)` — path param type changes from
  `String` to `int`, path template changes from `/tier/{name}` to `/tier/{id}`.
- **Port:** `GetTierPort.call(int id)` — signature changes from `String name`.
- **Use-case:** `GetTierUsecase.call(int id)` — passes `id` through to the
  port; permission check is unchanged.
- **Cubit:** `TierDetailsCubit.load(int id)` and `retry(int id)` — the cubit
  stores nothing; the caller is responsible for retaining the id.
- **Route params:** `TierDetailsPage` receives `@PathParam('id') int tierId`
  and `@QueryParam('name') String tierName`. The path in `app_router.dart`
  changes from `tiers/:name` to `tiers/:id`.
- **Screen:** `TierDetailsScreen` receives both `tierId` and `tierName`. AppBar
  title is driven by a `BlocBuilder<TierDetailsCubit>` that shows `tierName`
  in initial/loading states and `tier.name` once loaded.
- **Navigation from list:** `TierDetailsRoute(tierId: tier.id, tierName: tier.name)`.
- **Edit/delete buttons** in the detail screen read `tierId` and `tier.name`
  from local scope (both are available once loaded); the edit button passes
  both to `EditTierRoute`, the delete button passes both to `DeleteTierButton`.

## Testing Decisions

Good tests verify external behavior only — they do not assert on private
fields, internal method calls, or adapter implementation details.

- **Adapter unit test:** mock `TiersApiClient`; assert that `call(id)` returns
  `Right(TierDetail)` on 200, `Left(Failure.notFound())` on 404,
  `Left(Failure.unauthorized())` on 401, `Left(Failure.forbidden())` on 403,
  `Left(Failure.unknown())` on unexpected exception. Prior art:
  existing `GetTierAdapter` tests (if present) or `EditTierAdapter` tests.
- **Use-case unit test:** mock port and `PermissionCubit`; assert permission
  guard short-circuits with `Left(Failure.permissionDenied())` when
  `manageTiers` is absent; assert port is called with the given `id` otherwise.
- **Cubit test (`bloc_test`):** mock use-case; cover
  `initial → loading → loaded`, `initial → loading → error (notFound)`,
  `initial → loading → error (other)`, and `retry` re-entering the load flow.
- **Widget test:** mount `TierDetailsScreen` with a mocked cubit; assert AppBar
  shows `tierName` during loading, shows `tier.name` once loaded, shows
  error/retry widgets on failure.

## Out of Scope

- Changes to `edit_tier` or `delete_tier` slices (covered by PRDs 0046 and
  0047).
- Changing the list-tiers paginated endpoint or its response shape.
- Any changes to the `Tier` shared entity.

## Further Notes

- `auto_route` code-gen must be re-run after changing `@PathParam` and adding
  `@QueryParam` to `TierDetailsPage`.
- The `EditTierRoute` and `DeleteTierButton` call-sites inside
  `TierDetailsScreen` will be touched as part of this slice because they read
  `tierId` and `tier.name` from the already-loaded state, but the
  `EditTierPage` and `DeleteTierButton` widget signatures are owned by their
  respective slices.
