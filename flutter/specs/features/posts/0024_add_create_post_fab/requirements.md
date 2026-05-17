# 0024 · add_create_post_fab — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | When the authenticated user's username matches the screen's `username` route parameter, a FloatingActionButton is rendered on the User Posts screen. |
| F2 | When the authenticated user's username does not match the screen's `username` route parameter, no FloatingActionButton is rendered. |
| F3 | When the user is not authenticated (unauthenticated, unknown, or authenticating state), no FloatingActionButton is rendered on the User Posts screen. |
| F4 | Tapping the FloatingActionButton pushes the Create Post screen, passing the screen's `username` as a path parameter. |
| F5 | On return from the Create Post screen, the post list refreshes unconditionally, regardless of whether a post was published. |
| F6 | The FloatingActionButton carries a tooltip that reads "New post" in the English locale and "Новый пост" in the Russian locale. |
| F7 | The FloatingActionButton renders a plus icon. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | All UI strings are supplied through slang; no string literals appear in widget code. |
| N2 | FAB visibility is derived reactively from `AuthCubit` state via `BlocBuilder<AuthCubit, AuthState>`; `context.read<AuthCubit>()` is not used for visibility decisions inside `build`. |
| N3 | The key `posts.createPost.fabTooltip` is added to both `en.json` and `ru.json`; slang codegen is re-run and the generated `translations.g.dart` is committed alongside the JSON files. |
| N4 | The `UserPostsCubit` reference is captured before the `await` on the navigation call; `State.mounted` is verified before invoking `refresh` after the async gap. |
| N5 | No new Dart files are created; only `user_posts_screen.dart`, the two locale JSON files, and the widget test file are modified. |
| N6 | Widget tests include a FAB-presence case for the post owner (T-FAB-1) and a FAB-absence case for a non-owner (T-FAB-2); existing navigation tests T-04 and T-05 supply a non-owner `AuthCubit` mock so the harness compiles and the FAB does not interfere with their assertions. |
| N7 | `dart format .` produces no diff, `dart analyze` produces no warnings, and `flutter test test/features/posts/user_posts/` passes in full after all changes. |

## Out of scope

- Creating a new `CreatePostUseCase`, adapter, cubit, or port — all already exist in the `create_post` slice.
- Adding a "create post" entry point from the global Posts tab or from a user profile detail screen.
- Adding a `createPost` RBAC permission to the `Permission` enum.
- Any changes to the Create Post screen itself (form fields, validation, success flow).
- Push notification or deep-link entry point for post creation.
