# Plan: post_status_display (0037)

## Summary

Extend the existing `post_details` slice to show the post's moderation status as a
coloured chip to the author. No new layers (no port, adapter, use-case, cubit) are
introduced. All changes are confined to `post_details/presentation/` and the shared
localisation JSON files.

---

## Files to create

```
lib/features/posts/post_details/presentation/widgets/
└── post_status_chip.dart   # stateless widget — takes PostStatus, renders Chip
```

## Files to modify

```
lib/features/posts/post_details/presentation/post_details_screen.dart
lib/core/i18n/i18n/en.json
lib/core/i18n/i18n/ru.json
# (generated after slang run):
lib/core/i18n/translations.g.dart
lib/core/i18n/translations_en.g.dart
lib/core/i18n/translations_ru.g.dart
```

No other files are touched.

---

## Step-by-step implementation

### 1. Localisation — add three keys

In `lib/core/i18n/i18n/en.json`, under the `posts` namespace, add:

```json
"postStatus": {
  "pendingReview": "Pending Review",
  "approved": "Approved",
  "changesRequested": "Changes Requested"
}
```

Add the same keys in `lib/core/i18n/i18n/ru.json`:

```json
"postStatus": {
  "pendingReview": "На проверке",
  "approved": "Одобрено",
  "changesRequested": "Требуются изменения"
}
```

Run `dart run build_runner build --delete-conflicting-outputs` (or the slang runner)
to regenerate the translation files.

### 2. PostStatusChip widget

Create `lib/features/posts/post_details/presentation/widgets/post_status_chip.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';

class PostStatusChip extends StatelessWidget {
  const PostStatusChip({required this.status, super.key});

  final PostStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colorScheme = Theme.of(context).colorScheme;

    final (label, bg, fg) = switch (status) {
      PostStatus.pendingReview => (
          t.posts.postStatus.pendingReview,
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
      PostStatus.approved => (
          t.posts.postStatus.approved,
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      PostStatus.changesRequested => (
          t.posts.postStatus.changesRequested,
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
    };

    return Chip(
      label: Text(label, style: TextStyle(color: fg)),
      backgroundColor: bg,
      side: BorderSide.none,
    );
  }
}
```

### 3. PostDetailsScreen — inject the chip

In `post_details_screen.dart`, in the body's `PostDetailsLoaded` branch, wrap the
`SingleChildScrollView` content so that `AuthCubit` state is available:

Replace the existing `PostDetailsLoaded` body case:

```dart
PostDetailsLoaded(:final post) => BlocBuilder<AuthCubit, AuthState>(
  builder: (context, authState) {
    final currentUser = authState is AuthAuthenticated
        ? authState.currentUser
        : null;
    final isAuthor =
        post.username != null &&
        currentUser?.username == post.username;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (isAuthor) ...[
            const SizedBox(height: 8),
            PostStatusChip(status: post.status),
          ],
          if (post.mediaUrl != null) ...[
            const SizedBox(height: 12),
            Image.network(
              post.mediaUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 48),
            ),
          ],
          const SizedBox(height: 12),
          MarkdownBody(data: post.text),
          const SizedBox(height: 12),
          Text(
            DateFormat('dd MMM yyyy, HH:mm').format(post.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  },
),
```

Add the `PostStatusChip` import at the top of `post_details_screen.dart`.

**Note on `isAuthor` logic:** the existing AppBar computes `isAuthor` using
`currentUser?.username == widget.username` (the route param). The body uses
`post.username` (the entity field) per the PRD, which is nullable. Treat a null
`post.username` as non-author — the guard `post.username != null &&` achieves this.

---

## What NOT to do

- Do **not** add a new port, adapter, use-case, or cubit — none are needed.
- Do **not** modify `PostDetailsCubit` or `PostDetailsState` — the loaded state
  already carries `Post.status`.
- Do **not** make an extra network call — `Post.status` is already in the loaded
  state.
- Do **not** add the chip for states other than `PostDetailsLoaded`.
- Do **not** show the chip to non-authors or unauthenticated viewers.
- Do **not** assert chip colours in tests — colour is a Theme detail; assert on
  label text only.
- Do **not** touch other slices (`edit_post`, `user_posts`, etc.).
- Do **not** change `app_router.dart` — no new route is added.

---

## Tests

Only widget tests for `PostDetailsScreen` are added. No adapter/use-case/cubit tests
are needed because those layers are unchanged.

**Location:** `test/features/posts/0037_post_status_display/presentation/`
(or inside the existing `test/features/posts/post_details/presentation/` folder if
a widget test file exists there — create if absent).

**Cases to cover:**

| # | Setup | Expected |
|---|---|---|
| 1 | Author authenticated, `pendingReview` | Chip with "Pending Review" visible |
| 2 | Author authenticated, `approved` | Chip with "Approved" visible |
| 3 | Author authenticated, `changesRequested` | Chip with "Changes Requested" visible |
| 4 | Non-author authenticated (different username) | No chip |
| 5 | Unauthenticated user | No chip |
| 6 | `PostDetailsLoading` state | No chip (loading indicator shown) |
| 7 | `PostDetailsError` state | No chip (error/retry shown) |

**Mocks needed:**
- `MockPostDetailsCubit` (mock of `PostDetailsCubit`) — emit states via stream
- `MockAuthCubit` (mock of `AuthCubit`) — emit `AuthAuthenticated` / `AuthUnauthenticated`

Pattern: wrap the widget under test in `MultiBlocProvider` supplying mocked cubits;
use `pump()` instead of `pumpAndSettle()` (avoids timeouts on `CircularProgressIndicator`).

---

## Codegen checklist

After all edits:

1. `dart run build_runner build --delete-conflicting-outputs` (slang + freezed)
2. `dart format .`
3. `dart analyze` — zero warnings
4. `flutter test test/features/posts/` — all green
