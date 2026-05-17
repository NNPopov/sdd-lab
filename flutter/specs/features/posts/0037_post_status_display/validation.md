# 0037 · post_status_display — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Log in as post author. Navigate to one of your posts whose status is `pendingReview`. | A chip labelled **"Pending Review"** appears below the post title and above the content (media or markdown body). No extra loading indicator. |
| M2 | While logged in as author, open one of your posts whose status is `approved`. | A chip labelled **"Approved"** appears below the title. |
| M3 | While logged in as author, open one of your posts whose status is `changesRequested`. | A chip labelled **"Changes Requested"** appears below the title. |
| M4 | While logged in as a different user (not the author), open the same post. | No status chip is rendered anywhere on the screen. |
| M5 | Log out completely. Navigate to the same post (unauthenticated). | No status chip is rendered anywhere on the screen. |
| M6 | As author, open a `pendingReview` post that has a media image attached. | Chip appears below the title and **above** the media image, not below it. |
| M7 | As author, open a `pendingReview` post that has no media image. | Chip appears below the title and **above** the markdown body text. |
| M8 | As author, verify chip colours differ visually across statuses (open all three status variants). | `pendingReview` chip colour differs from `approved` chip colour, which differs from `changesRequested` chip colour. All three use the active theme colours (not hardcoded). |
| M9 | As author, open the edit screen of a `pendingReview` post, save a minor change, and return to the post details screen. | The screen reloads. The chip still shows **"Pending Review"** (status unchanged). No stale or missing chip. |
| M10 | As author, open a `changesRequested` post, tap edit, submit a revision (revision message required), and return to the post details screen. | The screen reloads. The chip now shows **"Pending Review"** (status updated after revision). |
| M11 | As author, open a `pendingReview` post. Check the AppBar. | The edit button (pencil icon) is visible. |
| M12 | As author, open an `approved` post. Check the AppBar. | The edit button (pencil icon) is visible. |
| M13 | As author, open a `changesRequested` post. Check the AppBar. | The edit button (pencil icon) is visible. |
| M14 | Log in as a superuser (not the author), open another user's post. | No status chip rendered. The screen shows the post content normally without any author-specific UI. |
| M15 | Disable network access, open any post as its author. | Error message and Retry button shown. No status chip rendered in the error state. |

## Code review

- [ ] `PostStatusChip` is located at `lib/features/posts/post_details/presentation/widgets/post_status_chip.dart` and nowhere else.
- [ ] No hardcoded UI strings in `PostStatusChip` — all three labels come from `context.t.posts.postStatus.pendingReview`, `.approved`, `.changesRequested`.
- [ ] Translation keys `posts.postStatus.pendingReview`, `posts.postStatus.approved`, `posts.postStatus.changesRequested` are present in both `lib/core/i18n/i18n/en.json` and `lib/core/i18n/i18n/ru.json`.
- [ ] No new port, adapter, use-case, or cubit file exists in the `post_details` or any other slice folder — diff shows only `post_details_screen.dart`, `post_status_chip.dart`, and i18n JSON files changed.
- [ ] `PostDetailsCubit` and `PostDetailsState` source files are **unmodified** (verify in diff).
- [ ] `post_details_screen.dart` imports only `package:flutter_application_1/features/posts/_shared/…` and `package:flutter_application_1/features/posts/post_details/…` — no import from another slice.
- [ ] `PostStatusChip` does **not** import `package:flutter_bloc` — it receives `PostStatus` as a constructor parameter only.
- [ ] Chip colours in `PostStatusChip` are sourced from `Theme.of(context).colorScheme` (`tertiaryContainer`, `primaryContainer`, `errorContainer`) — no `Color(0x…)` or named colour literals.
- [ ] `isAuthor` in the body branch of `PostDetailsScreen` is computed as `post.username != null && currentUser?.username == post.username` — uses `post.username`, not `widget.username`.
- [ ] `setState` does not appear anywhere in `PostDetailsScreen` — all state reads go through `BlocBuilder`.
- [ ] Widget test file uses `pump()` (not `pumpAndSettle()`) when asserting loading or error states.
- [ ] Widget tests supply mocked `PostDetailsCubit` and `AuthCubit` via `MultiBlocProvider`; no real cubits or DI are involved.
- [ ] No adapter, use-case, or cubit test file is added for this slice (those layers are unchanged).
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
