# Requirements — 0008 get_user_tier

## Business requirement

On the user details screen (`user_details_screen`), instead of the raw `tier_id`,
a human-readable tier name (`tier_name`) and the tier assignment date
(`tier_created_at`) in the format `2026-04-25 15:55` must be displayed. The tier loads
**lazily** — independently of the main user request, it is triggered after the user
loads successfully.

## Functional requirements

1. When `UserDetailsCubit` transitions to the `UserDetailsLoaded` state, the screen
   automatically triggers tier loading via `GetUserTierCubit.load(username)`.
2. While the tier is loading, the Tier row shows a loading indicator
   (or a string with `common.loading`).
3. After a successful load, two rows are displayed:
   - **Tier**: `tier_name` (e.g., `"Free"`)
   - **Tier since**: `tier_created_at` in format `yyyy-MM-dd HH:mm` (e.g.,
     `"2026-04-25 15:55"`), in the device's local time.
     If `tier_created_at` is absent from the response — the "Tier since"
     row is not displayed, the "Tier" row remains.
4. If tier loading fails or the user has no tier
   (`tierId == null`) — the Tier block is completely hidden (silent failure, no
   error state on screen).
5. The old display of `tier_id` as a number — is removed.

## Non-functional requirements

- Tier loading does not block or slow down the display of the main user data.
- Absence of a tier does not break the screen.
- Adapter is covered with double catch + AppLogger per CLAUDE.md §8.4.
