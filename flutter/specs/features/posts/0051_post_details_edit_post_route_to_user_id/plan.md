# Feature Spec — 0051 post_details_edit_post_route_to_user_id

> Implementation prompt for migrating the **post-details (read)** and **edit-post (update)**
> verticals from a `{username}`-keyed API + deep-link surface to an integer **`{user_id}`**
> one. Sources: `prd.md`, `CONTEXT.md`, `docs/adr/0002-posts-route-migration-fine-grained-slices.md`,
> ADR-0001, and the current slice code. Read this top-to-bottom before touching code.

---

## 1. HEADER

Migrate the `post_details` (GET) and `edit_post` (PATCH) verticals so the identity that
selects *which* post to read/update moves from the author's **handle string** to the
author's integer **`user_id`** — end to end, with **no user-visible behavior change**. This
is the first of three posts route slices (ADR-0002); `delete_post`/`erase_db_post` (0052)
and `user_posts`/`create_post` (0053) follow.

This slice also owns one `_shared` contract fix: `created_by_user_id` is tightened from a
nullable DTO field with a `?? 0` fallback to a **required `int`**, because the feed and the
author's-posts list start navigating into the detail screen *by this id*, and a missing
value must fail loudly at deserialization rather than route to user 0.

**Governing rule (CONTEXT.md):** migrate `username` → `int userId` **only** where it
identifies the *target* of a request (URL path segment, port/adapter lookup parameter,
ownership/`isMe` comparisons). **Never** touch `username` where it is a stored or displayed
**handle** (`Post.username`, `PostItemDto.username`, `CurrentUser.username`, the PATCH body,
`@username` labels). Classify every occurrence as *identity* or *handle* before editing. A
blind find-and-replace is forbidden.

**Accepted intermediate state (decided for this slice):** the detail screen's action row is
**mixed by design** after 0051 — the **Edit** button addresses the post by `id`, while
**Delete/Erase** stay handle-keyed (0052 migrates them). Because `getPost`/`PostDto` carry
**no handle** (see §3), the loaded `Post.username` is `null`, so the Delete/Erase bridge
renders **hidden** until 0052. This is the explicitly accepted intermediate state for this
slice — **do not** add a `username` field to `PostDto` to keep them visible.

---

## 2. CONTEXT

### READ
- `@CLAUDE.md` — fully (hard rules, layering, verification).
- `@CONTEXT.md` — the identity-vs-handle glossary; the decision rule for every edit.
- `@docs/adr/0002-posts-route-migration-fine-grained-slices.md` — why posts is split into
  three slices and why the mixed-key surface is accepted.
- `@specs/features/posts/0051_post_details_edit_post_route_to_user_id/prd.md`.
- The two verticals being migrated (read in full):
  - `@lib/features/posts/post_details/**`
  - `@lib/features/posts/edit_post/**`
- Shared + core touch-points:
  - `@lib/features/posts/_shared/data/posts_api_client.dart` — `getPost`/`patchPost`.
  - `@lib/features/posts/_shared/data/dto/post_dto.dart` — `created_by_user_id` → required.
  - `@lib/features/posts/_shared/data/dto/post_item_dto.dart` — `created_by_user_id` → required.
  - `@lib/features/posts/_shared/domain/entities/post.dart` — has `int createdByUserId` already.
  - `@lib/core/auth/domain/entities/current_user.dart` — has `int id` already (slice 0048).
  - `@lib/core/routing/app_router.dart` — the four posts path strings to change.
- Navigation call sites (one tile each — surgical, source the author id from the tile's post):
  - `@lib/features/posts/list_posts/presentation/list_posts_screen.dart`
  - `@lib/features/posts/user_posts/presentation/user_posts_screen.dart`
- The two sibling adapters that map `created_by_user_id` with `?? 0` (one-line cleanup only):
  - `@lib/features/posts/list_posts/data/list_posts_adapter.dart`
  - `@lib/features/posts/user_posts/data/user_posts_adapter.dart`
- Analogs (lean on, do **NOT** copy):
  - `@specs/features/users/0050_user_details_edit_user_route_to_user_id/**` — the users
    route-migration analog (identity-vs-handle, loaded-entity sourcing, mixed-key row).
  - `@test/features/tiers/0047_delete_tier_id_contract/**` — pattern for the contract
    outside-in test (real adapters + use-cases + cubits, mocked API client + `AuthCubit`,
    `verify` the integer id reaches the client).

### DO NOT READ
- Other posts slices: `delete_post/`, `erase_db_post/` (0052), `create_post/`,
  `moderate_post/`, `pending_posts/` — out of scope; their routes/methods stay.
- The `user_posts` internals beyond its one navigation tile (it stays username-keyed → 0053).
- Any `users/`, `tiers/`, `auth/` slice internals beyond the core touch-points above.
- Generated files except to regenerate them (`*.gr.dart`, `*.g.dart`, `*.freezed.dart`).

---

## 3. API

Two methods on the shared `PostsApiClient`. Both move the **path identity** to an integer;
nothing else about the contract changes. The other six methods on the client
(`getPosts`, `getUserPosts`, `createPost`, `deletePost`, `eraseDbPost`, `getPendingPosts`,
`moderatePost`, `revisePost`, `getModerationLog`) are **NOT** touched.

```
GET   /{user_id}/post/{id}   → PostDto        (was /{username}/post/{id})
PATCH /{user_id}/post/{id}   → 200, no body   (was /{username}/post/{id})
        Body: UpdatePostRequestDto { title, text, mediaUrl? }
        ↑ body is UNCHANGED — it never carried identity.
```

Header: `Authorization: Bearer <token>` (via interceptor, unchanged).

**`getPost` failure mapping (preserve exactly — `GetPostAdapter._mapHttp`):**
- 404 → `NotFoundFailure`
- ≥500 → `ServerFailure(statusCode)`
- default → `NetworkFailure(message)`
- catch-all `on Object` → `UnknownFailure`, `logger.error('GetPostAdapter.call failed', …)`.

**`patchPost` failure mapping (preserve exactly — `EditPostAdapter._mapHttp`):**
- 401 → `UnauthorizedFailure`
- 403 → `ForbiddenFailure`
- 422 → `MessageValidationFailure`
- connection error → `NetworkFailure`; else → `ServerFailure(statusCode)`
- catch-all `on Object` → `UnknownFailure`, `logger.error('EditPostAdapter.call failed …', …)`.

**Response shape note (important — drives the accepted intermediate state):** `PostDto`
(the single-post GET response) has **no `username` field** — only `PostItemDto` (the list
response) does. `GetPostAdapter` therefore builds `Post` **without** `username`, so the
detail screen's loaded `Post.username` is always `null`. This is **unchanged** by this
slice (we are not adding `username` to `PostDto`). `created_by_user_id` **is** present on
both DTOs and becomes the load-bearing identity.

---

## 4. STRUCTURE — files touched (migration, not new tree)

No new files. Edits grouped by layer. `(BR)` = requires
`dart run build_runner build --delete-conflicting-outputs`.

```
_shared
├── data/posts_api_client.dart  (BR — retrofit posts_api_client.g.dart)
│     getPost(@Path('username') String username, @Path('id') int id)
│        → getPost(@Path('user_id') int userId, @Path('id') int id)        // GET /{user_id}/post/{id}
│     patchPost(@Path('username') String username, @Path('id') int id, body)
│        → patchPost(@Path('user_id') int userId, @Path('id') int id, body) // PATCH /{user_id}/post/{id}; body untouched
├── data/dto/post_dto.dart       (BR — freezed/json post_dto.freezed.dart + .g.dart)
│     @JsonKey(name:'created_by_user_id') int? createdByUserId
│        → @JsonKey(name:'created_by_user_id') required int createdByUserId
└── data/dto/post_item_dto.dart  (BR — freezed/json post_item_dto.freezed.dart + .g.dart)
      @JsonKey(name:'created_by_user_id') int? createdByUserId
         → @JsonKey(name:'created_by_user_id') required int createdByUserId

core/routing  (BR — app_router.gr.dart)
└── app_router.dart   (four posts path strings; siblings NOT touched)
      Users tab:  'user/:username/posts/:id'       → 'user/:user_id/posts/:id'        (PostDetailsRoute)
                  'user/:username/posts/:id/edit'   → 'user/:user_id/posts/:id/edit'   (EditPostRoute)
      Posts tab:  ':username/posts/:id'             → ':user_id/posts/:id'             (PostDetailsRoute)
                  ':username/posts/:id/edit'        → ':user_id/posts/:id/edit'        (EditPostRoute)
      ↑ 'user/:username/posts', '.../posts/create', ':username/posts/create' NOT touched (0053).

post_details vertical
├── domain/ports/post_details_port.dart   call(String username, int id) → call(int userId, int id)
├── domain/usecases/get_post_usecase.dart call(String, int) → call(int userId, int id) => _port(userId, id)
├── data/get_post_adapter.dart            call(int userId, int id) → _api.getPost(userId, id);
│                                          createdByUserId: dto.createdByUserId  (drop `?? 0`)
│                                          failure mapping + catch-all logger.error UNCHANGED
├── application/post_details_cubit.dart   load(String username, int id) → load(int userId, int id)
├── application/post_details_state.dart   UNCHANGED (carries Post)
├── presentation/post_details_route.dart  (PostDetailsPage)
│     @PathParam('username') String username → @PathParam('user_id') int userId
│     field username:String → userId:int; cubit.load(userId, id); PostDetailsScreen(userId:, id:)
└── presentation/post_details_screen.dart
      widget field username:String → userId:int
      _PostDetailsActions(username:) → (userId:)
        author check (route param):  currentUser?.username == username → currentUser?.id == userId
        Edit button: EditPostRoute(post: postState.post, username:) → EditPostRoute(post: postState.post)
                     after pop: cubit.load(username, id) → cubit.load(userId, id)
        Delete/Erase bridge: source handle from loaded post.username, null-guarded
                     (post.username is null from getPost → buttons hidden until 0052)
      _PostDetailsBody author check (loaded post):
        post.username != null && currentUser?.username == post.username
           → currentUser?.id == post.createdByUserId          // drop the username!=null guard

edit_post vertical
├── domain/entities/updated_post_data.dart  final String username → final int userId  (ctor param too)
├── domain/usecases/edit_post_usecase.dart  ownership check (identity):
│     currentUser.username != data.username → currentUser.id != data.userId
│     (signature call(UpdatedPostData) unchanged; revise branch + validation unchanged)
├── domain/ports/edit_post_port.dart        UNCHANGED (call(UpdatedPostData))
├── data/edit_post_adapter.dart             _api.patchPost(data.username, …) → _api.patchPost(data.userId, …)
│                                            body + failure mapping + catch-all logger.error UNCHANGED
├── data/revise_post_adapter.dart           UNCHANGED (uses data.postUuid / revisionMessage only)
├── domain/ports/i_revise_post_port.dart    UNCHANGED
├── application/edit_post_cubit.dart         UNCHANGED (submit(UpdatedPostData))
├── presentation/edit_post_route.dart        (EditPostPage)
│     DROP the `username` arg (page has NO @PathParam — it was a plain object arg).
│     EditPostPage({required this.post}); pass EditPostScreen(post: post).
└── presentation/edit_post_screen.dart
      DROP the `username` field; UpdatedPostData(username: widget.username, …)
         → UpdatedPostData(userId: widget.post.createdByUserId, …)   // identity from loaded Post
      moderation-log panel, revision-message field, approved lock, PostRevisedEvent UNCHANGED

navigation call sites (surgical — source the author id from the tile's post)
├── list_posts/presentation/list_posts_screen.dart
│     PostDetailsRoute(username: posts[index].username!, id: …) → (userId: posts[index].createdByUserId, id: …)
├── list_posts/data/list_posts_adapter.dart   createdByUserId: p.createdByUserId  (drop `?? 0`)
├── user_posts/presentation/user_posts_screen.dart
│     PostDetailsRoute(username: widget.username, id: …) → (userId: posts[index].createdByUserId, id: …)
└── user_posts/data/user_posts_adapter.dart   createdByUserId: p.createdByUserId  (drop `?? 0`)
```

> **Corrections vs prd.md** (the code is authoritative): (a) `EditPostPage` has **no
> `@PathParam`** — `username`/`post` are plain push-by-object args, so the edit page gets
> **no** `userId` param; it sources identity from `post.createdByUserId`. (b) Adding a
> `userId` arg to the edit page/screen would be an **unused field** (fails
> `very_good_analysis`) since the screen reads `post.createdByUserId`; hence the edit-route
> `username` arg is **dropped, not renamed**. (c) The edit-route path-string change is
> **cosmetic** (EditPostRoute binds no path params), kept only for route-tree consistency.

---

## 5. WHAT TO DO — step by step

Work bottom-up so each layer compiles against the one below before the screen is touched.
Run `build_runner` once after the `_shared` + routing edits.

**1) `_shared` API client.** In `posts_api_client.dart`, change `getPost` and `patchPost`
path params to `@Path('user_id') int userId` and the path templates to `/{user_id}/post/{id}`.
Leave `patchPost`'s `@Body()` and the other six methods exactly as-is. This breaks
`get_post_adapter` and `edit_post_adapter` (intended — that is the coupling).

**2) `_shared` DTOs.** In `post_dto.dart` and `post_item_dto.dart`, change
`@JsonKey(name: 'created_by_user_id') int? createdByUserId` →
`@JsonKey(name: 'created_by_user_id') required int createdByUserId`. No other field changes.
This makes the three `?? 0` fallbacks dead code (step 3 + step 7).

**3) post_details domain → data → application.**
- `PostDetailsPort.call(int userId, int id)`.
- `GetPostUseCase.call(int userId, int id) => _port(userId, id)`.
- `GetPostAdapter.call(int userId, int id)` → `_api.getPost(userId, id)`; map
  `createdByUserId: dto.createdByUserId` (drop `?? 0`). Failure mapping (404 / ≥500 /
  network), `_parseStatus`, and the catch-all `logger.error` stay byte-for-byte.
- `PostDetailsCubit.load(int userId, int id)`; body otherwise unchanged.

**4) edit_post domain → data → application.**
- `UpdatedPostData`: `final int userId` (was `String username`); update the constructor param.
- `EditPostUseCase`: change the ownership guard from
  `currentUser.username != data.username` to `currentUser.id != data.userId`. Keep the
  `currentUser == null` short-circuit, the `changesRequested` revision-message validation,
  and the `_revisePort(data)` / `_editPort(data)` branching exactly as they are.
- `EditPostAdapter.call`: `_api.patchPost(data.userId, data.id, UpdatePostRequestDto(...))`.
  Body and the 401/403/422 + network/server mapping + catch-all `logger.error` unchanged.
- `RevisePostAdapter`, `IRevisePostPort`, `EditPostPort`, `EditPostCubit`: no change.

**5) Routing paths + page params.**
- `app_router.dart`: change exactly the four `PostDetails`/`EditPost` path strings
  (`:username` → `:user_id`). Leave the `user/:username/posts`, `.../posts/create`, and
  `:username/posts/create` declarations and the `EditPostRoute` `authGuard` alone.
- `PostDetailsPage`: `@PathParam('user_id') required this.userId` (`final int userId`),
  `cubit.load(userId, id)`, `PostDetailsScreen(userId: userId, id: id)`.
- `EditPostPage`: **drop** `username`; `EditPostPage({required this.post})`,
  `EditPostScreen(post: post)`.

**6) Screens.**
- `PostDetailsScreen`: field `final int userId` (was `username`). Title is a static
  localized string — unchanged. Pass `userId` into `_PostDetailsActions` and `_PostDetailsBody`.
  - `_PostDetailsActions`: `isAuthor = currentUser?.id == userId` (route param). Source the
    bridge handle `final handle = postState.post.username;` (null from `getPost`). Render
    `DeletePostButton(username: handle, id: id)` only `if (isAuthor && handle != null)`;
    `EraseDbPostButton(username: handle, id: id)` only `if (showErase && handle != null)`.
    The **Edit** `IconButton` always shows when `isAuthor`; it pushes
    `EditPostRoute(post: postState.post)` and on return calls `cubit.load(userId, id)`.
  - `_PostDetailsBody`: `isAuthor = currentUser?.id == post.createdByUserId` (drop the
    `post.username != null` guard). The status chip / layout are otherwise unchanged.
- `EditPostScreen`: drop the `username` field; in `_onSubmit` build
  `UpdatedPostData(userId: widget.post.createdByUserId, id: widget.post.id, postUuid: …, …)`.
  Everything else (controllers, validators, moderation log, approved lock, `BlocConsumer`
  success → `PostRevisedEvent` + `maybePop`) is unchanged.

**7) Navigation call sites + sibling adapter cleanups.**
- `list_posts_screen.dart` tile: `PostDetailsRoute(userId: posts[index].createdByUserId, id: posts[index].id)`.
- `user_posts_screen.dart` tile: `PostDetailsRoute(userId: posts[index].createdByUserId, id: posts[index].id)`
  (source the **author id of that post**, not `widget.username`).
- `list_posts_adapter.dart` and `user_posts_adapter.dart`: change
  `createdByUserId: p.createdByUserId ?? 0` → `createdByUserId: p.createdByUserId` (forced
  by the now-required field; no other change to these adapters).

**8) build_runner + verify.** Run
`dart run build_runner build --delete-conflicting-outputs` (regenerates the retrofit client,
the two DTO `*.g.dart`/`*.freezed.dart`, and `app_router.gr.dart`). Then `dart format .`,
`dart analyze` (must be clean — watch for now-unused fields/imports), and the test suite.

No new localization keys. No `pubspec.yaml` changes.

---

## 6. TESTS

Acceptance gate first, then the per-layer re-green (detailed in `tests.md`; this block
states the contract the implementation must satisfy). Default four-layer coverage applies.

- **Slice contract outside-in (acceptance gate)** — mirroring
  `test/features/tiers/0047_delete_tier_id_contract/`: wire the **real** `get_post` and
  `edit_post` adapter + use-case + cubit, mock `PostsApiClient` and `AuthCubit`, and
  `verify(() => api.getPost(<int userId>, id))` and
  `verify(() => api.patchPost(<int userId>, id, <unchanged body>))`. No live backend.
- **Adapters (unit):** `GetPostAdapter` success calls `getPost(<int>, id)` and maps a
  required `createdByUserId` (no `?? 0`); failure mapping (404 / ≥500 / network) + catch-all
  `logger.error` preserved. `EditPostAdapter` success calls `patchPost(<int>, id, body)` with
  the unchanged body; failure mapping (401/403/422 + network/server) + catch-all preserved.
- **Use-cases (unit):** `GetPostUseCase` delegates to the port with the integer id;
  `EditPostUseCase` allows the author when `currentUser.id == data.userId`, returns
  `ForbiddenFailure` otherwise, and still short-circuits the `changesRequested` empty-message
  branch to the revise port.
- **DTO mapping (unit):** `PostDto`/`PostItemDto` deserialize a **required**
  `created_by_user_id`; the adapters surface it without a default.
- **Cubits (`bloc_test`):** `PostDetailsCubit.load(<int>, id)` → loading → loaded/error;
  `EditPostCubit.submit` → loading → success/error.
- **Widgets:** the detail screen renders by id; the **Edit** action shows for the author
  (`currentUser.id == userId`) and the body status chip shows when
  `currentUser.id == post.createdByUserId`; Delete/Erase stay hidden (loaded `post.username`
  is null — accepted intermediate state). The edit screen submits an `UpdatedPostData` whose
  `userId` is `post.createdByUserId`.
- **Downstream re-green:** existing `post_details`/`edit_post` cubit/adapter/screen tests
  migrated username→id; routing/navigation tests that construct `PostDetailsRoute`/
  `EditPostRoute` (and the `list_posts`/`user_posts` screen tests whose tiles build them);
  and **every** `PostDto`/`PostItemDto` construction across the suite updated to supply
  `created_by_user_id` now that it is required.

---

## 7. REPORT (what the implementing agent returns)

- List of files changed (none created), grouped by vertical / `_shared` / routing / nav.
- Confirmation that **no out-of-scope slice** was touched (delete/erase, create, moderate,
  pending, user_posts internals beyond its one tile) and that no **handle** was migrated to id.
- Confirmation that `build_runner` was run and `posts_api_client.g.dart`, the two DTO
  `*.g.dart`/`*.freezed.dart`, and `app_router.gr.dart` were regenerated.
- The slice contract outside-in test: red-before / green-after evidence.
- `dart format` clean, `dart analyze` clean, full `flutter test` green — with an explicit
  count of downstream tests re-greened (incl. the DTO-construction fan-out).

---

## 8. WHAT NOT TO DO

- ❌ Do **not** add a `username` field to `PostDto` (or otherwise populate `Post.username`
  from `getPost`) to keep Delete/Erase visible — their hidden state is the accepted
  intermediate state for this slice (→ 0052).
- ❌ Do **not** migrate any **handle**: `Post.username`, `PostItemDto.username`,
  `CurrentUser.username`, the `UpdatePostRequestDto` body, or `@username` labels.
- ❌ Do **not** touch the sibling routes/paths (`user/:username/posts`, `.../posts/create`,
  `:username/posts/create`) or the other six `PostsApiClient` methods.
- ❌ Do **not** add a `userId` arg/`@PathParam` to `EditPostPage`/`EditPostScreen` — source
  identity from `post.createdByUserId`.
- ❌ Do **not** change `patchPost`'s request body, the revise/moderation-log flows, or any
  failure mapping (`getPost` 404/≥500/network; `patchPost` 401/403/422/network/server).
- ❌ Do **not** drop any `on Object catch (e, st)` + `logger.error` catch-all in an adapter.
- ❌ Do **not** add a dependency, a new route, a new localization key, or change `CurrentUser`
  / `AuthSession`.
