# Requirements 0019 — user_posts: navigation to post details

## Scope

Extension of the `user_posts` slice — presentation layer only.
No new slice, domain, data, or application layer is created.

---

## Functional Requirements

### FR-01 — "Open" button in PostTile

`PostTile` displays an "Open" button in the lower-right area of the card:

| Element | Value |
|---|---|
| Icon | `Icons.open_in_new` |
| Label EN | "Open" (`context.t.posts.userPosts.openPost`) |
| Label RU | "Открыть" (`context.t.posts.userPosts.openPost`) |
| Type | `TextButton.icon` (`icon` first), aligned to the right |

### FR-02 — Card body is not tappable

`PostTile.Card` is not wrapped in a `GestureDetector` or `InkWell`.
A tap on the title, text, or date does not invoke any callback.

### FR-03 — The onOpenTap callback is required

`PostTile` accepts `onOpenTap: VoidCallback` as a required parameter.
The widget does not know about routes and does not import `auto_route` / `app_router`.

### FR-04 — Navigation from UserPostsScreen

`UserPostsScreen` passes `onOpenTap` to each `PostTile`:
```dart
onOpenTap: () => context.router.push(
  PostDetailsRoute(username: widget.username, id: posts[index].id),
),
```
The call is fire-and-forget (without `await`). After returning from `PostDetailsRoute`
`UserPostsCubit.refresh()` is **not called**.

### FR-05 — New i18n key

One new key is added under `posts.userPosts`:
- `en.json`: `"openPost": "Open"`
- `ru.json`: `"openPost": "Открыть"`

After adding, `dart run slang` is executed.

---

## Non-Functional Requirements

### NFR-01 — Scope limited to presentation layer

The domain/, data/, application/ layers of the `user_posts` slice are not modified.

### NFR-02 — Slice isolation

Other slices (list_posts, create_post, post_details, users)
are not affected. `_shared/` is not modified.

### NFR-03 — core/ minimally affected

Only `core/i18n/i18n/en.json` and `core/i18n/i18n/ru.json` are modified.
The router (`core/routing/`) is not modified.

### NFR-04 — Compatibility with auto_route

`PostDetailsRoute(username: String, id: int)` is already registered in `AppRouter`.
No router changes are required.

### NFR-05 — Tests

New widget tests for `PostTile` and `UserPostsScreen`.
All existing tests remain green.

---

## Constraints

- Packages: only those already in `pubspec.yaml`. No new dependencies are added.
- Codegen: `dart run slang` is run after changing the JSON.
- Lint: `dart analyze` with no new warnings.
- Test framework: `flutter_test` + `bloc_test` + `mocktail`.
