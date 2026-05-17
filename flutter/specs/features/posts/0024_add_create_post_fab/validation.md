# 0024 · add_create_post_fab — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Sign in as alice. Navigate to `/user/alice/posts`. | A FloatingActionButton with a plus icon is visible in the bottom-right corner of the screen. |
| M2 | While signed in as alice, navigate to `/user/bob/posts`. | No FloatingActionButton is rendered on the screen. |
| M3 | Sign out. Navigate to `/user/alice/posts`. | No FloatingActionButton is rendered on the screen. |
| M4 | Sign in as a superuser. Navigate to `/user/alice/posts` (a different user). | No FloatingActionButton is rendered — superusers cannot create posts on behalf of others. |
| M5 | Sign in as alice. Navigate to `/user/alice/posts`. Tap the FAB. | The Create Post screen opens with alice's username already bound to the form context (title bar or route parameter reflects `alice`). |
| M6 | On the Create Post screen, fill in the form and publish a new post. Navigate back (system back or back button). | The User Posts screen is displayed and the newly published post appears in the list without requiring a manual pull-to-refresh. |
| M7 | On the Create Post screen, tap the back button without filling in or publishing anything. | The User Posts screen is displayed. The list refreshes (spinner appears briefly) and returns to its previous content — no crash, no error snackbar. |
| M8 | Sign in as alice. Navigate to `/user/alice/posts`. Long-press the FAB (or hover on desktop). Locale is English. | Tooltip reads "New post". |
| M9 | Switch the device/app locale to Russian. Navigate to `/user/alice/posts` while signed in as alice. Long-press the FAB. | Tooltip reads "Новый пост". |
| M10 | Sign in as alice. Navigate to `/user/alice/posts` (FAB is visible). From a different screen, sign out (e.g. use the app-level logout). Return to the user posts screen without relaunching. | The FAB disappears without navigating away from the screen. |

## Code review

- [ ] `user_posts_screen.dart` `Scaffold` has a `floatingActionButton` property wrapping a `BlocBuilder<AuthCubit, AuthState>`.
- [ ] Inside the builder, visibility guard is `authState is AuthAuthenticated && authState.currentUser?.username == widget.username` — no other auth-state subtype shows the FAB.
- [ ] When the guard is false the builder returns `const SizedBox.shrink()`, not `null` (BlocBuilder must return a Widget).
- [ ] No `context.read<AuthCubit>()` or `context.watch<AuthCubit>()` call is present in `build` outside the BlocBuilder — all auth reads are inside the builder callback.
- [ ] FAB `tooltip` is `t.posts.createPost.fabTooltip` — no hardcoded string literal.
- [ ] FAB `onPressed` body captures `context.read<UserPostsCubit>()` into a local variable **before** the `await context.router.push(...)` call.
- [ ] `if (!mounted) return;` appears immediately after the `await` and before `cubit.refresh(...)`.
- [ ] `refresh` is called unconditionally — there is no check on the return value of `push`.
- [ ] `en.json` contains `"fabTooltip": "New post"` under `posts.createPost`.
- [ ] `ru.json` contains `"fabTooltip": "Новый пост"` under `posts.createPost`.
- [ ] `translations.g.dart` is updated (commit includes the generated file alongside the JSON files).
- [ ] The PR diff touches exactly four files: `user_posts_screen.dart`, `en.json`, `ru.json`, `user_posts_screen_test.dart` (plus the generated `translations.g.dart`). No other files are modified.
- [ ] Widget test declares `_MockAuthCubit extends MockCubit<AuthState> implements AuthCubit`.
- [ ] `_wrapWithRouter` uses `MultiBlocProvider` with both `UserPostsCubit` and `AuthCubit` providers; it accepts `AuthCubit authCubit` as a parameter.
- [ ] T-FAB-1 asserts `find.byType(FloatingActionButton)` finds exactly one widget when `AuthAuthenticated(currentUser: alice)` and `username == 'alice'`.
- [ ] T-FAB-2 asserts `find.byType(FloatingActionButton)` finds nothing when `AuthAuthenticated(currentUser: bob)` and `username == 'alice'`.
- [ ] T-04 and T-05 supply a non-owner `AuthCubit` state (e.g. `AuthUnauthenticated`) so the FAB is hidden and does not interfere with their navigation assertions.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
