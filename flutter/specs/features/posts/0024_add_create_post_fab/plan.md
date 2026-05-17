# Plan — 0024: Add Create Post FAB to User Posts Screen

## Task

Add a `FloatingActionButton` to `UserPostsScreen` that is visible only when the
authenticated user is viewing their own posts page. Tapping navigates to the existing
`CreatePostRoute`; on return the post list refreshes unconditionally. No new slices,
ports, adapters, cubits, or routes are created — this is a pure presentation-layer
change plus two i18n keys.

---

## Context

### Read

- `CLAUDE.md` — project rules
- `lib/features/posts/user_posts/presentation/user_posts_screen.dart` — file being modified
- `lib/core/auth/application/auth_cubit.dart` — `AuthCubit` to inject via `BlocBuilder`
- `lib/core/auth/application/auth_state.dart` — `AuthAuthenticated` and `AuthUnauthenticated`
- `lib/core/auth/domain/entities/current_user.dart` — `CurrentUser.username` used in guard
- `lib/core/routing/app_router.dart` — confirm `CreatePostRoute` is already registered
- `lib/features/posts/create_post/presentation/create_post_route.dart` — `CreatePostPage` takes `@PathParam('username')`
- `lib/core/i18n/i18n/en.json` — add `fabTooltip` key under `posts.createPost`
- `lib/core/i18n/i18n/ru.json` — add `fabTooltip` key under `posts.createPost`
- `lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart` — FAB prior art
- `test/features/posts/user_posts/presentation/user_posts_screen_test.dart` — file being extended

### Do not read

- `lib/features/posts/create_post/**` (except the route file above)
- `lib/features/posts/user_posts/application/**`
- `lib/features/posts/user_posts/data/**`
- Any other slice

---

## API

No new backend endpoint. This slice:

- Reads reactive `AuthCubit` state already provided by DI.
- Pushes `CreatePostRoute(username: widget.username)` — already registered in
  `app_router.dart`, already guarded by `authGuard`.
- Calls `UserPostsCubit.refresh(widget.username)` on return — method already exists.

---

## Target Structure

Only existing files are modified — no new files are created:

```
lib/
  core/
    i18n/i18n/
      en.json                          ← add posts.createPost.fabTooltip
      ru.json                          ← add posts.createPost.fabTooltip
  features/posts/user_posts/
    presentation/
      user_posts_screen.dart           ← add floatingActionButton

test/features/posts/user_posts/
  presentation/
    user_posts_screen_test.dart        ← extend with _MockAuthCubit, T-FAB-1, T-FAB-2;
                                         update T-04 and T-05
```

---

## What to Do

### 1. i18n keys

In `lib/core/i18n/i18n/en.json`, under `posts.createPost`, add after `publishButton`:

```json
"fabTooltip": "New post"
```

In `lib/core/i18n/i18n/ru.json`, under `posts.createPost`, add after `publishButton`:

```json
"fabTooltip": "Новый пост"
```

After saving both files, run:

```
dart run build_runner build --delete-conflicting-outputs
```

Commit the generated `translations.g.dart` alongside the JSON files.

### 2. Modify `user_posts_screen.dart`

Add two imports:

```dart
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
```

`CreatePostRoute` is already imported via `app_router.dart` — verify it is present;
if not, the generated `app_router.gr.dart` exposes it through the same import.

In `_UserPostsScreenState.build`, add `floatingActionButton` to the `Scaffold`:

```dart
floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
  builder: (context, authState) {
    final isOwner =
        authState is AuthAuthenticated &&
        authState.currentUser?.username == widget.username;
    if (!isOwner) return const SizedBox.shrink();
    return FloatingActionButton(
      tooltip: t.posts.createPost.fabTooltip,
      onPressed: () async {
        final cubit = context.read<UserPostsCubit>();
        await context.router.push(
          CreatePostRoute(username: widget.username),
        );
        if (!mounted) return;
        unawaited(cubit.refresh(widget.username));
      },
      child: const Icon(Icons.add),
    );
  },
),
```

Key points:
- `t` is already computed at the top of `build` — use it inside the builder.
- `context.read<UserPostsCubit>()` is captured before the `await` to avoid
  using a potentially-stale `BuildContext` after the async gap.
- `context.mounted` is checked via the `State.mounted` shorthand (`!mounted`)
  before calling `cubit.refresh`.
- Refresh is called **unconditionally** on return — the PRD does not require
  checking whether a post was actually created.
- The `floatingActionButton` is `null`-equivalent via `SizedBox.shrink()` when
  the user is not the owner; using a zero-sized widget keeps the `BlocBuilder`
  reactive without needing to unwrap to nullable.

### 3. Update `user_posts_screen_test.dart`

#### 3a. Add `_MockAuthCubit`

```dart
class _MockAuthCubit extends MockCubit<AuthState>
    implements AuthCubit {}
```

#### 3b. Update `_wrapWithRouter`

Add an `AuthCubit authCubit` parameter and wrap with a second `BlocProvider`:

```dart
Widget _wrapWithRouter(
  Widget child,
  UserPostsCubit cubit,
  StackRouter router,
  AuthCubit authCubit,   // new
) => TranslationProvider(
  child: StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<UserPostsCubit>.value(value: cubit),
          BlocProvider<AuthCubit>.value(value: authCubit),
        ],
        child: child,
      ),
    ),
  ),
);
```

#### 3c. Add `_MockAuthCubit` helpers and fixtures

```dart
const _aliceUser = CurrentUser(
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
);

const _bobUser = CurrentUser(
  username: 'bob',
  email: 'bob@example.com',
  name: 'Bob',
  isSuperuser: false,
);
```

#### 3d. Add T-FAB-1 and T-FAB-2 in a new group

```dart
group('UserPostsScreen FAB visibility', () {
  late _MockUserPostsCubit cubit;
  late _MockStackRouter mockRouter;
  late _MockAuthCubit authCubit;

  setUp(() {
    cubit = _MockUserPostsCubit();
    mockRouter = _MockStackRouter();
    authCubit = _MockAuthCubit();
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.load(any())).thenAnswer((_) async {});
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.state).thenReturn(
      UserPostsState.loaded(posts: _posts, page: 1, hasMore: false),
    );
  });

  tearDown(() async {
    await cubit.close();
    await authCubit.close();
  });

  testWidgets(
    'T-FAB-1: FAB is visible when authenticated user is the owner',
    (tester) async {
      when(() => authCubit.state).thenReturn(
        const AuthState.authenticated(currentUser: _aliceUser),
      );

      await tester.pumpWidget(
        _wrapWithRouter(
          const UserPostsScreen(username: _username),
          cubit,
          mockRouter,
          authCubit,
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    },
  );

  testWidgets(
    'T-FAB-2: FAB is hidden when authenticated user is not the owner',
    (tester) async {
      when(() => authCubit.state).thenReturn(
        const AuthState.authenticated(currentUser: _bobUser),
      );

      await tester.pumpWidget(
        _wrapWithRouter(
          const UserPostsScreen(username: _username),
          cubit,
          mockRouter,
          authCubit,
        ),
      );

      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );
});
```

#### 3e. Update T-04 and T-05 (existing navigation group)

Add `authCubit` to the group setup and pass it to `_wrapWithRouter`:

```dart
group('UserPostsScreen navigation', () {
  late _MockUserPostsCubit cubit;
  late _MockStackRouter mockRouter;
  late _MockAuthCubit authCubit;   // new

  setUp(() {
    cubit = _MockUserPostsCubit();
    mockRouter = _MockStackRouter();
    authCubit = _MockAuthCubit();   // new
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.load(any())).thenAnswer((_) async {});
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
    // Non-owner auth state keeps FAB hidden so it does not interfere
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
  });

  tearDown(() async {
    await cubit.close();
    await authCubit.close();   // new
  });

  // T-04 and T-05: add `authCubit` as fourth arg to _wrapWithRouter
  ...
});
```

---

## What Not to Do

- Do not create a new slice, cubit, port, adapter, or route for this feature.
- Do not add a `createPost` permission to the `Permission` enum — ownership is
  enforced by `CreatePostUseCase`, not by RBAC.
- Do not use `context.read<AuthCubit>()` inside `build` directly — use
  `BlocBuilder` so the FAB reacts to auth state changes.
- Do not guard with `authCubit.currentUser` directly — use the `AuthState` type;
  `AuthAuthenticated.currentUser` may be null if `/me` failed after login, which
  the `?.username` null-safe check already handles (FAB stays hidden).
- Do not call `refresh` only when a post was created — refresh unconditionally.
- Do not show the FAB for `AuthUnknown` or `AuthAuthenticating` states.
- Do not modify any file outside `user_posts/presentation/`, the two i18n JSON
  files, and the widget test file without stopping to ask first.

---

## Report

When done, confirm:

- [ ] `en.json` and `ru.json` each have `posts.createPost.fabTooltip`
- [ ] Slang codegen ran; `translations.g.dart` updated
- [ ] `user_posts_screen.dart` has `BlocBuilder<AuthCubit, AuthState>` FAB
- [ ] Widget test has `_MockAuthCubit`, updated `_wrapWithRouter`, T-FAB-1,
      T-FAB-2, and updated T-04/T-05
- [ ] `dart format .` — no diff
- [ ] `dart analyze` — no warnings
- [ ] `flutter test test/features/posts/user_posts/` — all green
- [ ] No other slice or file was modified
