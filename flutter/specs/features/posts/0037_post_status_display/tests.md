# 0037 · post_status_display — Outside-in test spec

## Goal

Prove that `PostDetailsScreen` renders the `PostStatusChip` with the correct label
for each `PostStatus` when the viewer is the author, and renders no chip when the
viewer is not the author or is unauthenticated.

## Entry point

This slice has no new Cubit method — the entire change is in the presentation layer.
The test entry point is:

```
tester.pumpWidget(
  MultiBlocProvider(
    providers: [
      BlocProvider<PostDetailsCubit>.value(value: mockPostDetailsCubit),
      BlocProvider<AuthCubit>.value(value: mockAuthCubit),
    ],
    child: MaterialApp(
      home: PostDetailsScreen(username: 'alice', id: 42),
    ),
  ),
);
```

## Wired real (production code in the test)

- `PostDetailsScreen` (the widget under test — contains the chip injection logic)
- `PostStatusChip` (the new chip widget — rendered as real code)

## Mocked (system boundaries only)

- **PostDetailsCubit**: emits `PostDetailsLoaded(post: fakePost)` where `fakePost`
  is a `Post` fixture with `username: 'alice'` and a configurable `status`.
- **AuthCubit**: emits `AuthAuthenticated(currentUser: fakeUser)` where
  `fakeUser.username` is either `'alice'` (author) or `'bob'` (non-author),
  or emits `AuthUnauthenticated()`.

## Post fixture

All scenarios use this base fixture, varying only `status`:

- `id: 42`
- `title: 'Test Post'`
- `text: 'x' * 100` (minimal valid markdown body)
- `createdAt: DateTime(2024, 1, 15)`
- `createdByUserId: 1`
- `postUuid: 'uuid-001'`
- `username: 'alice'`
- `mediaUrl: null`

## Test scenarios

### Scenario 1: Author views a post — chip label matches the post status

**Setup:**
- `AuthCubit` emits `AuthAuthenticated(currentUser: CurrentUser(username: 'alice', …))`
- `PostDetailsCubit` emits `PostDetailsLoaded(post: fakePost.copyWith(status: PostStatus.pendingReview))`
- Pump the widget

**Act:**
- Pump frame (one `pump()` call — no `pumpAndSettle`)

**Expect:**
- A widget with text `"Pending Review"` is found in the widget tree
- A widget with text `"Approved"` is **not** found in the widget tree

**Then repeat with `status: PostStatus.approved`:**
- A widget with text `"Approved"` is found
- A widget with text `"Pending Review"` is not found

**Then repeat with `status: PostStatus.changesRequested`:**
- A widget with text `"Changes Requested"` is found
- A widget with text `"Pending Review"` is not found

### Scenario 2: Non-author and unauthenticated viewer — no chip rendered

**Setup A — authenticated non-author:**
- `AuthCubit` emits `AuthAuthenticated(currentUser: CurrentUser(username: 'bob', …))`
- `PostDetailsCubit` emits `PostDetailsLoaded(post: fakePost)` (post.username = 'alice')

**Act:** Pump frame

**Expect:**
- No widget with text `"Pending Review"`, `"Approved"`, or `"Changes Requested"`
  is found in the widget tree
- A `PostStatusChip` widget is **not** found in the widget tree

**Setup B — unauthenticated:**
- `AuthCubit` emits `AuthUnauthenticated()`
- `PostDetailsCubit` emits `PostDetailsLoaded(post: fakePost)` (same fixture)

**Act:** Pump frame

**Expect:**
- Same: no chip widget found

## Out of scope for this test

- Widget rendering details (chip colour, chip shape) — colour comes from Theme and
  is not asserted.
- `PostDetailsLoading` / `PostDetailsError` states — covered by existing
  `post_details` widget tests or unit tests.
- Chip update after returning from the edit screen (F12) — the reload is a property
  of the existing `PostDetailsCubit.load()` call wired in the AppBar; it is covered
  by the existing cubit unit test.
- Route navigation (edit button tap) — covered by existing `post_details` widget tests.
- Adapter, use-case, and cubit layers — unchanged by this slice; no new tests added
  for those layers.
