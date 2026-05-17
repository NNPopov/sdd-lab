# 0023 · erase_db_post — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Log in as a superuser. Open the Post Details screen for a post authored by a different user. | The `delete_forever` icon button is visible in the AppBar. |
| M2 | Log in as a superuser. Open the Post Details screen for one of your own posts. | The `delete_forever` icon is absent. The delete and edit icons are present. |
| M3 | Log in as a regular (non-superuser) user. Open any Post Details screen. | The `delete_forever` icon is absent from the AppBar. |
| M4 | As superuser on a foreign post, tap the `delete_forever` icon. | An `AlertDialog` appears with a title, body text, a Cancel button, and a destructive Erase button. |
| M5 | Read the body text of the confirmation dialog. | The body explicitly states the erasure is permanent and the action cannot be undone. |
| M6 | As superuser on a foreign post, open the confirmation dialog and tap Cancel. | The dialog closes. The Post Details screen is unchanged; the post is still visible. |
| M7 | As superuser on a foreign post, tap the erase icon and tap Erase to confirm. Observe the screen while the DELETE request is in flight. | A loading indicator (e.g., `CircularProgressIndicator`) is visible. |
| M8 | As superuser on a foreign post, confirm erasure and tap the Erase button rapidly a second time while the request is in flight. | The Erase button is visually disabled; the second tap has no effect. |
| M9 | As superuser on a foreign post, confirm erasure and the server responds `2xx`. | A success snackbar appears with the "Post erased" message. |
| M10 | As superuser on a foreign post, confirm erasure and the server responds `2xx`. | After the snackbar, the app navigates back to the previous screen automatically. |
| M11 | Navigate back to the posts list after a successful erasure. | The erased post is absent from the list. No loading spinner or network request is triggered; the removal is immediate. |
| M12 | As superuser on a foreign post, confirm erasure and the server returns a `5xx` error. | An error snackbar appears with failure text (e.g., "Failed to erase post. Please try again."). |
| M13 | After an erasure failure (M12), inspect the Post Details screen. | The screen remains open. The `delete_forever` icon is present and can be tapped again to retry. |
| M14 | As superuser on a foreign post, confirm erasure and the server returns `403 Forbidden`. | An error snackbar shows "You do not have permission to erase posts". The detail screen stays open. |
| M15 | Navigate to a foreign post's detail page via a deep link (not via the posts list). Log in as superuser. | The erase button is visible. The full flow (confirm → success → pop → post gone from list) completes correctly. |
| M16 | Log in as a superuser. Navigate via deep link to a Post Details screen for your own post. | The `delete_forever` icon is absent. Only the delete and edit buttons for your own post are shown. |

## Code review

- [ ] Slice folder exists at `lib/features/posts/erase_db_post/` with `domain/`, `data/`, `application/`, and `presentation/` sub-directories (F1, N1)
- [ ] `EraseDbPostState` is declared as `sealed class` with `@freezed` and contains exactly five variants: `initial`, `confirming`, `deleting`, `success`, `failure(Failure)` — grep: `sealed class EraseDbPostState` (N2)
- [ ] `EraseDbPostCubit` bears `@injectable` annotation; constructor accepts exactly `EraseDbPostUseCase`, `AuthCubit`, and `PostEventBus` — grep: `class EraseDbPostCubit` (N3)
- [ ] `EraseDbPostUseCase.call` signature includes `required bool isSuperuser` as a named parameter; the use-case class does NOT inject `AuthCubit` — grep: `required bool isSuperuser` (N4, F14)
- [ ] `EraseDbPostUseCase` returns `Left(Failure.permissionDenied())` when `isSuperuser` is `false` — grep: `permissionDenied` inside `erase_db_post_usecase.dart` (F14)
- [ ] All files under `domain/` import only `dartz`, `freezed`, or pure Dart — grep: `import 'package:flutter` and `import 'package:dio` yield zero hits in `erase_db_post/domain/` (N5)
- [ ] `EraseDbPostAdapter` bears `@LazySingleton(as: EraseDbPostPort)` — grep: `LazySingleton` in `erase_db_post_adapter.dart` (N6)
- [ ] Adapter contains an inner `on DioException` catch that maps 401→`unauthorized`, 403→`forbidden`, 404→`notFound`, 5xx→`serverError`, and an outer `catch (e, st)` that calls `AppLogger.error` and returns `Left(Failure.unknown())` (N6, N7)
- [ ] `confirmAndErase` in `EraseDbPostCubit` calls `_eventBus.publish(PostDeleted(id))` on the success branch — grep: `PostDeleted` in `erase_db_post_cubit.dart` (N8, F11)
- [ ] `PostEventBus` and `PostEvent` files are unmodified — `git diff` shows no changes to `_shared/application/post_event*.dart` (N8)
- [ ] `EraseDbPostButton` file contains `BlocProvider<EraseDbPostCubit>` — grep: `BlocProvider` in `erase_db_post_button.dart` (N9)
- [ ] `post_details_route.dart` does NOT contain a `BlocProvider` for `EraseDbPostCubit` — grep: `EraseDbPostCubit` in `post_details_route.dart` yields zero hits (N9)
- [ ] On success, the listener calls `context.router.pop()` — grep: `router.pop` in `erase_db_post_button.dart`; grep: `replaceAll` and `forceLogout` yield zero hits in the slice (N10, F10)
- [ ] No raw string literals in `presentation/` files — grep for `'[A-Z][a-z]` and `"[A-Z][a-z]` in `erase_db_post/presentation/` yields zero hits (N11)
- [ ] Both `en.json` and `ru.json` contain a `posts.eraseDbPost` object with all eight keys: `tooltip`, `confirmTitle`, `confirmMessage`, `confirmButton`, `cancelButton`, `success`, `errors.forbidden`, `errors.generic` (N12)
- [ ] No file under `erase_db_post/` imports another `posts` slice — grep: `import.*features/posts/` in `erase_db_post/` returns only `_shared/` paths (N13)
- [ ] No class in the slice is named `*Repository` — grep: `class.*Repository` in `erase_db_post/` yields zero hits (N14)
- [ ] `pubspec.yaml` is unchanged — `git diff pubspec.yaml` shows no additions (N15)
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
