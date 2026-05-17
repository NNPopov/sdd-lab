# Validation 0017 — list_users: explicit navigation to user details and user posts

## Automated Tests

### UserTile — Widget Tests

| # | Scenario | Expected result |
|---|---|---|
| T-01 | Tap "Details" button | `onDetailsTap` called 1 time, `onPostsTap` — 0 times |
| T-02 | Tap "Posts" button | `onPostsTap` called 1 time, `onDetailsTap` — 0 times |
| T-03 | Tap on tile body (outside buttons) | Neither callback is called |
| T-04 | Render — "Details" button | `Icons.person_outline` + label "Details" is present |
| T-05 | Render — "Posts" button | `Icons.article_outlined` + label "Posts" is present |

### UsersScreen — Widget Tests (with mocked UsersListCubit)

| # | Scenario | Expected result |
|---|---|---|
| T-06 | Tap "Details" → return from route | `UsersListCubit.refresh()` called |
| T-07 | Tap "Posts" → return from route | `UsersListCubit.refresh()` NOT called |

---

## Manual QA Checklist

### Visual appearance

- [ ] Each tile shows two buttons: icon + label side by side
- [ ] "Details": person/profile icon (`person_outline`)
- [ ] "Posts": article/document icon (`article_outlined`)
- [ ] When switching language to RU, buttons show "Детали" / "Статьи"
- [ ] Tile body (name, avatar, username) does not appear tappable

### Navigation — Details

- [ ] Tap "Details" → the correct user's details screen opens
- [ ] Return from Details → the user list has been refreshed (visible via pull-to-refresh or changed data)

### Navigation — Posts

- [ ] Tap "Posts" → the correct user's posts screen opens
- [ ] Return from Posts → the user list does NOT reload (no spinner appears)

### Tile body

- [ ] Tap on username → nothing happens
- [ ] Tap on avatar → nothing happens
- [ ] Tap on username → nothing happens

### Regression

- [ ] Creating a new user (FAB) → list refreshes as before
- [ ] Pull-to-refresh → list refreshes as before
- [ ] Pagination (scroll down) → next users are loaded
- [ ] Load error → Retry button works

---

## Definition of Done

- [ ] Both callbacks `onDetailsTap` and `onPostsTap` are declared as required in `UserTile`
- [ ] `ListTile.onTap` is set to `null`
- [ ] Fallback `onTap ?? router.push(...)` is completely removed from `UserTile`
- [ ] `UserTile` does not import `auto_route` / `app_router`
- [ ] Keys `users.list.userDetails` and `users.list.userPosts` added to en.json and ru.json
- [ ] `dart run slang` executed without errors
- [ ] `dart analyze` without new warnings
- [ ] `flutter test` — all tests green (old + new)
- [ ] domain/, data/, application/ of the list_users slice are not modified
- [ ] Other slices are not affected
- [ ] `_shared/` is not modified
- [ ] `core/` is not modified (except i18n JSON)
- [ ] `roadmap.md` updated to ✅ status
