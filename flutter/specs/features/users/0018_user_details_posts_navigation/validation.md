# Validation 0018 — user_details: navigation to user posts

## Automated Tests

### UserDetailsView — Widget Tests

| # | Scenario | Expected result |
|---|---|---|
| T-01 | Render — "Posts" button | `Icons.article_outlined` + label "Posts" is present |
| T-02 | Tap "Posts" button | `onPostsTap` called exactly 1 time |
| T-03 | Render — divider | `Divider` is present between info rows and "Posts" button |

### UserDetailsScreen — Widget Tests (with mocked UserDetailsCubit)

| # | Scenario | Expected result |
|---|---|---|
| T-04 | Tap "Posts" | Router receives `UserPostsRoute(username: username)` |
| T-05 | After returning from `UserPostsRoute` | `UserDetailsCubit.load()` NOT called again |

---

## Manual QA Checklist

### Visual appearance

- [ ] On the user details screen, below the info rows a horizontal divider is visible
- [ ] Below the divider — a button with `article_outlined` icon and "Posts" label (EN)
- [ ] When switching language to RU the label shows "Статьи"
- [ ] Button is left-aligned
- [ ] Button is visible for any role (guest, user, manager, admin)

### Navigation

- [ ] Tap "Posts" → the posts screen for this user opens
- [ ] Return from the posts screen → data on the details screen is not reloaded
  (no spinner appears, data remains as before)

### Regression

- [ ] "Edit" and "Delete" buttons (in AppBar) work as before
- [ ] "Delete" button (if isMe) works as before
- [ ] Tier information is displayed correctly
- [ ] Details load error → Retry button works
- [ ] Details screen renders correctly for users without a tier

---

## Definition of Done

- [ ] `UserDetailsView` accepts `onPostsTap: VoidCallback` as a required parameter
- [ ] `UserDetailsView` does not import `auto_route` / `app_router`
- [ ] `Divider` is shown between the last info row and the "Posts" button
- [ ] `TextButton.icon` with `Icons.article_outlined` is added to `UserDetailsView`
- [ ] `UserDetailsScreen` passes `onPostsTap` with `context.router.push(UserPostsRoute(...))`
- [ ] Navigation is fire-and-forget (without `await`)
- [ ] `UserDetailsCubit.load()` is not called after returning from posts
- [ ] Button is shown for all roles without permission checks
- [ ] `dart analyze` without new warnings
- [ ] `flutter test` — all tests green (old + new)
- [ ] domain/, data/, application/ of the user_details slice are not modified
- [ ] Other slices are not affected
- [ ] `_shared/` is not modified
- [ ] `core/` is not modified
- [ ] `roadmap.md` updated to ✅ status
