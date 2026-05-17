# Requirements: list_tiers — full implementation

## Context

Extension of the skeleton slice `list_tiers` into a full implementation with data.
The skeleton (route + guard + placeholder screen) is already implemented and deployed.
This document describes the requirements for adding domain/data/application layers.

## User story

> As a superuser (`isSuperuser == true`), I want to see on the `/tiers` page
> a list of all tiers (with pagination), so that I understand which tiers exist in the system.

## Functional requirements

| # | Requirement |
|---|---|
| F-01 | When navigating to `/tiers`, a list of tiers loaded from `GET /api/v1/tiers?page=1&items_per_page=10` is displayed |
| F-02 | The list supports pull-to-refresh — reloading from page=1 |
| F-03 | Scrolling to the bottom loads the next page (load-more) |
| F-04 | While data is loading — a `CircularProgressIndicator` is displayed |
| F-05 | On load error — error text + Retry button |
| F-06 | On load-more error — error message below the last element |
| F-07 | The use-case checks `Permission.manageTiers` and returns `Left(PermissionDenied)` when the permission is absent |
| F-08 | Each tier is displayed in a ListTile: id and name are visible to the user |

## Non-functional requirements

| # | Requirement |
|---|---|
| NF-01 | `TiersApiClient` is registered in DI via `TiersFeatureModule` |
| NF-02 | `ListTiersAdapter` implements double-catch (§8.4 CLAUDE.md) |
| NF-03 | All fields of `TierDto` except `id` are defensively nullable or `@Default(...)` (§8.2 CLAUDE.md) |
| NF-04 | `ListTiersCubit` is annotated with `@injectable` (factory, not singleton) |
| NF-05 | All UI strings via slang (`context.t.tiers.listTiers.*`) |
| NF-06 | `tiers/_shared/` is NOT created — there is only one slice, no real sharing |

## Out of scope

- CRUD operations on tiers (create, edit, delete) — separate slices
- Detailed view screen for a single tier (tier_details)
- Search / filtering by tiers
- Navigation button / menu item for navigating to `/tiers` (already implemented earlier? — confirm)
