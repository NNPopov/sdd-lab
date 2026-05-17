# Validation 0019 — user_posts: navigation to post details

## Automated Tests

### PostTile — Widget Tests

| # | Scenario | Expected result |
|---|---|---|
| T-01 | Render — "Open" button | `Icons.open_in_new` + label "Open" are present |
| T-02 | Tap on the "Open" button | `onOpenTap` called exactly 1 time |
| T-03 | Tap on the card body (title/text/date) | `onOpenTap` NOT called |

### UserPostsScreen — Widget Tests (with mocked UserPostsCubit)

| # | Scenario | Expected result |
|---|---|---|
| T-04 | Tap "Open" on a post | Router receives `PostDetailsRoute(username: username, id: post.id)` |
| T-05 | After returning from `PostDetailsRoute` | `UserPostsCubit.refresh()` NOT called |

---

## Manual QA Checklist

### Appearance

- [ ] Each post card shows a button with the `open_in_new` icon and the label "Open" (EN)
- [ ] When the language is switched to RU, the label shows "Открыть"
- [ ] The button is aligned to the right of the card
- [ ] The card body (title, preview, date) does not respond to a tap

### Navigation

- [ ] Tap "Open" → the post details screen opens (correct post)
- [ ] The URL on the details screen contains the correct `username` and post `id`
- [ ] Return from the details screen → the post list does not reload
  (spinner does not appear, scroll position is preserved)

### Regression

- [ ] Pull-to-refresh on the post list screen works as before
- [ ] Pagination (loading when scrolling down) works as before
- [ ] The Retry button on load error works as before
- [ ] Empty screen ("No posts yet") when there are no posts — displays correctly
- [ ] Multiple posts displayed: the "Open" button is present on each card

---

## Definition of Done

- [ ] `PostTile` accepts `onOpenTap: VoidCallback` as a required parameter
- [ ] `PostTile` does not import `auto_route` / `app_router`
- [ ] `TextButton.icon` with `Icons.open_in_new` is added to `PostTile`, aligned to the right
- [ ] The `PostTile` body is not tappable (no `GestureDetector`/`InkWell` around Card)
- [ ] `UserPostsScreen` passes `onOpenTap` with `context.router.push(PostDetailsRoute(...))`
- [ ] Navigation is fire-and-forget (without `await`)
- [ ] `UserPostsCubit.refresh()` is not called after returning from the post details
- [ ] Key `posts.userPosts.openPost` is added to `en.json` and `ru.json`
- [ ] `dart run slang` is executed after changing the JSON
- [ ] `dart analyze` with no new warnings
- [ ] `flutter test` — all tests green (old + new)
- [ ] domain/, data/, application/ of the user_posts slice are not modified
- [ ] Other slices are not affected
- [ ] `_shared/` is not modified
- [ ] `core/routing/` is not modified
- [ ] `roadmap.md` updated to status ✅
