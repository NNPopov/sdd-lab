# PRD — 0062 · core/routing · routing_user_id_path_segments

> **Status:** 📋 Planned
> **Feature:** core/routing
> **Slice:** routing_user_id_path_segments
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 and on the
> feature slices 0049–0061 (route pages live in feature folders).

## Problem Statement

In-app navigation still encodes the user as a `:username` string in route paths, and each
affected route page declares `@PathParam('username') String username`. With the API and
all ports/adapters migrated to `int userId`, the navigation layer is the last place that
still produces and consumes a username, so deep links and intra-app navigation no longer
line up with the data layer.

## Solution

Rename the user path segment from `:username` to `:user_id` across the router (9 segments)
and retype every affected route page's path parameter from
`@PathParam('username') String username` to `@PathParam('user_id') int userId`. Regenerate
the router with `build_runner` so `app_router.gr.dart` reflects the new typed parameters.
This makes navigation produce and consume the same integer identifier the data layer now
uses end-to-end.

## User Stories

1. As a user, I want to navigate to a user's detail screen by tapping it, so that I land on the right profile via its `user_id`.
2. As a user, I want to open a user's post list, a single post, create/edit post screens, and the edit-user screen, so that every user-scoped screen routes by `user_id`.
3. As a user following a deep link, I want `:user_id`-based URLs to resolve to the correct screen, so that deep links keep working under the new scheme.
4. As a developer, I want route pages to receive a typed `int userId`, so that no screen reconstructs a username to call its cubit/use-case.
5. As a developer, I want `build_runner` to regenerate `app_router.gr.dart`, so that generated navigation code matches the new parameter types.
6. As a maintainer, I want all nine segments migrated together, so that the app never mixes `:username` and `:user_id` routes.

## Implementation Decisions

- **Modules modified:**
  - The app router (`app_router`): 9 path segments `:username` → `:user_id`.
  - Six route pages: `user_details`, `edit_user`, `user_posts`, `create_post`, `post_details`, `edit_post` — each `@PathParam('username') String username` → `@PathParam('user_id') int userId`.
- **`build_runner`** (`dart run build_runner build --delete-conflicting-outputs`) is run after the edits to regenerate `app_router.gr.dart`; this is part of the slice's definition of done.
- Callers that push these routes now pass an `int` id (sourced from `User.id` / `CurrentUser.id`) instead of a username string.
- This slice lands after the feature slices because it depends on their route-page param types and on the data layer already accepting `int userId`.

## Testing Decisions

- **Good test = observable routing behavior:** navigating with a `user_id` resolves to the
  expected screen with the expected typed argument; a malformed/missing `user_id` is handled
  per the router's existing conventions.
- **Modules tested:**
  - **Routing/navigation** — widget/integration-style tests that push each migrated route with an `int userId` and assert the correct page is shown with the parsed id. Prior art: existing routing slice tests (e.g. 0025–0027) and navigation slices (0017–0019).
  - Route-page param parsing — that a path `user_id` string is received as `int userId`.
- No new adapter/network surface is introduced here.

## Out of Scope

- Port/adapter/API-client signature changes — slices 0049–0061.
- `CurrentUser.id` / `isMe` foundation — slice 0048.
- Any visual/UX redesign of the affected screens.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decision 6, implementation order steps
10–12). After this slice the migration is complete; run `dart format .`, `dart analyze`,
`build_runner`, and `flutter test`, then `/verify` per the handoff checklist.
