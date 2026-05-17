# Plan 0019 — user_posts: navigation to post details

Task: extend the `user_posts` slice — presentation layer only.
Add an "Open" button to each `PostTile` on the right side of the card.
Navigation to `PostDetailsRoute` — fire-and-forget, without reloading
`UserPostsCubit` on return. One new i18n key, codegen is needed.

---

====== CONTEXT ======

READ:
- `@CLAUDE.md` in full
- `@lib/features/posts/user_posts/presentation/widgets/post_tile.dart` — being modified
- `@lib/features/posts/user_posts/presentation/user_posts_screen.dart` — being modified
- `@lib/features/posts/post_details/presentation/post_details_route.dart` — confirm signature
- `@lib/core/routing/app_router.dart` — confirm that `PostDetailsRoute` is registered
- `@lib/core/i18n/i18n/en.json` — adding key `posts.userPosts.openPost`
- `@lib/core/i18n/i18n/ru.json` — adding key `posts.userPosts.openPost`
- `@.claude/skills/bloc/SKILL.md`

DO NOT READ:
- `@lib/features/posts/user_posts/domain/**`
- `@lib/features/posts/user_posts/data/**`
- `@lib/features/posts/user_posts/application/**`
- `@lib/features/posts/list_posts/**`
- `@lib/features/posts/create_post/**`
- `@lib/features/posts/post_details/**` (except the route file)
- `@lib/features/users/**`

---

====== API ======

The change is purely frontend. The backend is not affected.
The route is already registered in `AppRouter`:
- `PostDetailsRoute(username: String, id: int)` → `/user/:username/posts/:id`

New i18n key: `posts.userPosts.openPost`
- EN: `"Open"`
- RU: `"Открыть"`

After adding the keys, it is mandatory to run: `dart run slang`

---

====== Target Structure ======

No new files are created. Existing files are modified:

```
lib/features/posts/user_posts/presentation/
├── user_posts_screen.dart              ← MODIFY: pass onOpenTap to each PostTile
└── widgets/
    └── post_tile.dart                  ← MODIFY: add onOpenTap + TextButton.icon

lib/core/i18n/i18n/
├── en.json                             ← MODIFY: add posts.userPosts.openPost
└── ru.json                             ← MODIFY: add posts.userPosts.openPost
```

---

====== WHAT TO DO ======

### 1) LOCALISATION — i18n JSON

File: `lib/core/i18n/i18n/en.json`

Add to the `posts.userPosts` section:
```json
"openPost": "Open"
```

Final section:
```json
"userPosts": {
  "title": "$username's posts",
  "empty": "No posts yet",
  "loadError": "Failed to load posts",
  "openPost": "Open"
}
```

File: `lib/core/i18n/i18n/ru.json`

Add to the same section:
```json
"openPost": "Открыть"
```

After changing both JSONs, run: `dart run slang`

---

### 2) PRESENTATION — PostTile

File: `lib/features/posts/user_posts/presentation/widgets/post_tile.dart`

Add a required parameter:
```dart
final VoidCallback onOpenTap;
```

In the constructor:
```dart
const PostTile({
  required this.post,
  required this.onOpenTap,   // ← new
  super.key,
});
```

In `build()`, after the date line in `Column.children`, add:
```dart
Align(
  alignment: Alignment.centerRight,
  child: TextButton.icon(
    icon: const Icon(Icons.open_in_new),
    label: Text(context.t.posts.userPosts.openPost),
    onPressed: onOpenTap,
  ),
),
```

IMPORTANT: `PostTile` does not know about navigation — it only calls the callback.
Do not add an import for `auto_route` or `app_router` to this file.
Do not wrap the card body (Card) in a `GestureDetector` or `InkWell`.

---

### 3) PRESENTATION — UserPostsScreen

File: `lib/features/posts/user_posts/presentation/user_posts_screen.dart`

In `itemBuilder`, in the branch `if (index < posts.length)`, update the `PostTile` creation:

```dart
return PostTile(
  post: posts[index],
  onOpenTap: () => context.router.push(           // ← new
    PostDetailsRoute(
      username: widget.username,
      id: posts[index].id,
    ),
  ),
);
```

Add import for `PostDetailsRoute`:
```dart
import 'package:flutter_application_1/core/routing/app_router.dart';
```

IMPORTANT: Navigation is fire-and-forget (`context.router.push` without `await`).
After returning from `PostDetailsRoute`, `UserPostsCubit.refresh()` is NOT called.
Viewing a post does not change the user's post list.

---

====== TESTS ======

### test/features/posts/user_posts/presentation/widgets/post_tile_test.dart

Create the file. Test `PostTile` in isolation (without a router):

a) "Open" button is present: `Icons.open_in_new` + label "Open"
b) Tap on the "Open" button → `onOpenTap` called exactly 1 time
c) Tap on the card body (outside the button, e.g. on the title) → `onOpenTap` NOT called

Use a call counter or `bool` flag instead of a mock for `onOpenTap`.

### test/features/posts/user_posts/presentation/user_posts_screen_test.dart

Create or extend the existing file. Test `UserPostsScreen`
with a mocked `UserPostsCubit`:

a) Tap "Open" on a post → router receives `PostDetailsRoute(username: username, id: post.id)`
b) After returning from `PostDetailsRoute` → `UserPostsCubit.refresh()` is NOT called

Pattern: `MockUserPostsCubit extends MockCubit<UserPostsState>` (mocktail).
See analogue in `test/features/users/list_users/presentation/` (slice 0017).

---

====== REPORT ======

On completion, provide:
- List of modified files (no new ones)
- Confirmation that domain/, data/, application/ of the user_posts slice are not touched
- Confirmation that other slices are not affected
- Confirmation that `core/routing/` is not modified
- Result of `dart analyze` (no new warnings)
- Tests: number of new tests, all green

---

====== WHAT NOT TO DO ======

- DO NOT create a new slice — this is an extension of the existing `user_posts`
- DO NOT touch domain/, data/, application/ of the user_posts slice
- DO NOT add navigation logic inside `PostTile` — only a callback
- DO NOT add `await` before `context.router.push(PostDetailsRoute(...))` — fire-and-forget
- DO NOT call `cubit.refresh()` after returning — reload is not needed
- DO NOT wrap the card body in `GestureDetector`/`InkWell` — the body is not tappable
- DO NOT modify `PostDetailsRoute`, `AppRouter`, `_shared/`, `core/routing/`
- DO NOT touch other slices: list_posts, create_post, post_details, users
- DO NOT forget to run `dart run slang` after changing the JSON
