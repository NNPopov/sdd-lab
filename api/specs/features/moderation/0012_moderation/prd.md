# PRD — Post Moderation System (parent PRD, slices 0013–0022)

## Problem Statement

Posts created by users are immediately visible to everyone. There is no review
gate between content submission and public visibility. The platform needs a
moderation workflow so that published content has been approved by at least one
designated moderator before it reaches the audience. Additionally, moderators
need a structured way to communicate required changes back to authors, and
authors need to be able to revise their posts and respond to moderator remarks —
creating a lightweight editorial dialogue.

On the user management side, there is no moderator role. The only privilege
distinction is `is_superuser`, which has platform-wide administrative power.
A separate `is_moderator` role is needed that grants moderation rights without
full administrative access. Superusers must be able to assign and revoke this
role, with a clear audit trail of who granted it.

## Solution

Introduce a post lifecycle state machine (`pending_review` → `approved` /
`changes_requested`) enforced at the API layer. Every newly created post starts
in `pending_review`. A post becomes publicly visible only after a moderator
(who is not the post's author) marks it `approved`. If a moderator requests
changes, the post enters `changes_requested` and the author can revise and
resubmit, returning the post to `pending_review`.

A `PostModerationLog` table records the full chronological history of all
moderation events (moderator decisions with optional remarks) and author
revision events (with optional messages), giving both parties a complete
dialogue trail.

A new `is_moderator` field is added to `User` (nullable audit FK
`moderator_granted_by_user_id` tracks who granted it). Moderator status is
exposed via the `get_user_by_username` and `get_me` endpoints so that frontends
can render role badges and enable/disable moderation UI.

## User Stories

### Moderator Role Management

1. As a superuser, I want to assign the moderator role to a user, so that they
   can review and approve posts.
2. As a superuser, I want to revoke the moderator role from a user, so that
   they can no longer approve posts.
3. As a superuser, I want the system to record which superuser granted moderator
   status to each user, so that there is an audit trail of role assignments.
4. As a superuser, I want to receive HTTP 404 when I try to assign or revoke
   moderator status for a username that does not exist, so that I get clear
   feedback on invalid requests.
5. As a superuser, I want to receive HTTP 409 when I try to assign moderator
   status to a user who is already a moderator, so that duplicate assignments
   are prevented.
6. As a superuser, I want to receive HTTP 409 when I try to revoke moderator
   status from a user who is not a moderator, so that invalid revocations are
   prevented.
7. As an authenticated user, I want to receive HTTP 403 when I try to assign or
   revoke moderator status (without superuser privileges), so that role
   management is restricted.

### Moderator Role Visibility

8. As a frontend developer, I want the `GET /users/{username}` response to
   include the `is_moderator` flag, so that the profile page can display a
   moderator badge.
9. As an authenticated user, I want the `GET /users/me` response to include the
   `is_moderator` flag, so that the frontend knows whether to render moderation
   UI for the current user.

### Post Creation

10. As an authenticated author, I want my newly created post to enter a
    `pending_review` state automatically, so that it waits for moderator
    approval before becoming publicly visible.
11. As an authenticated author, I want the create-post response to include the
    post's initial status, so that I know my post is awaiting moderation.

### Moderation Queue

12. As a moderator, I want to view a paginated list of posts awaiting review
    (status `pending_review` or `changes_requested`), so that I can work
    through the moderation queue efficiently.
13. As a superuser, I want to access the same moderation queue as moderators,
    so that I can step in when needed.
14. As a non-moderator user, I want to receive HTTP 403 when I try to access
    the moderation queue, so that the queue is restricted to authorised
    reviewers.
15. As a moderator reviewing the queue, I want to see the post author's username
    alongside each queued post, so that I can identify who submitted it.
16. As a moderator reviewing the queue, I want to see the current moderation
    log (previous remarks and author replies) for each post, so that I have
    context for re-reviews.

### Moderating a Post

17. As a moderator, I want to approve a post, so that it becomes publicly
    visible to all users.
18. As a moderator, I want to request changes on a post and leave a remark
    explaining what needs to be fixed, so that the author knows what to revise.
19. As a moderator, I want to be prevented from approving or requesting changes
    on my own posts, so that self-approval is not possible.
20. As a moderator, I want to receive HTTP 404 when I try to moderate a post
    that does not exist, so that I get clear feedback.
21. As a moderator, I want to receive HTTP 409 when I try to moderate a post
    that is not in a reviewable state (e.g. already `approved`), so that
    duplicate reviews are prevented.
22. As a moderator, I want the remark field to be optional when approving a
    post, so that I do not need to write a comment for straightforward
    approvals.
23. As a moderator, I want the remark field to be required when requesting
    changes, so that the author always receives actionable feedback.
24. As a non-moderator user, I want to receive HTTP 403 when I try to submit a
    moderation decision, so that only authorised reviewers can approve posts.

### Author Revisions

25. As an author, I want to update the title and/or body of a post that has had
    changes requested, so that I can address the moderator's feedback.
26. As an author, I want to leave a message when submitting a revision, so that
    I can explain what I changed in response to the moderator's remark.
27. As an author, I want my revised post to automatically return to
    `pending_review` after submission, so that it re-enters the moderation
    queue.
28. As an author, I want to receive HTTP 403 when I try to revise a post that
    is not in `changes_requested` state, so that revisions are only accepted
    when they are needed.
29. As an author, I want to receive HTTP 403 when I try to revise a post that
    is not mine, so that other users' posts are protected.
30. As an author, I want to receive HTTP 404 when I try to revise a post that
    does not exist, so that I get clear feedback.

### Post Visibility

31. As a regular authenticated user, I want to see only `approved` posts when
    browsing another user's profile (`GET /users/{username}/posts`), so that
    unapproved content is hidden from the public feed.
32. As an author, I want to see all of my own posts (any status) when viewing
    my own profile feed, so that I can track the moderation status of my
    submissions.
33. As a regular user, I want to see only `approved` posts in the global feed
    (`GET /posts`), so that the public feed is free of unapproved content.
34. As a moderator or superuser, I want to see all posts in the global feed
    regardless of status, so that I have full visibility when needed.
35. As an unauthenticated user, I want to see only `approved` posts in any
    public listing endpoint, so that unapproved content is never exposed
    publicly.

### Moderation History

36. As an author, I want to see the full history of moderation remarks and my
    own revision messages on a post, so that I have context for subsequent
    revisions.
37. As a moderator, I want to see the full dialogue history (all prior remarks
    and author replies) when reviewing a re-submitted post, so that I have
    full context.

## Implementation Decisions

### Planned slices (in execution order)

| Slice # | Resource | Name | Endpoint(s) |
|---|---|---|---|
| 0013 | infra | `moderation_db_foundation` | — (DB only) |
| 0014 | users | `expose_moderator_flag` | `GET /users/{username}`, `GET /users/me` |
| 0015 | users | `assign_moderator` | `PATCH /users/{username}/assign-moderator` |
| 0016 | users | `revoke_moderator` | `PATCH /users/{username}/revoke-moderator` |
| 0017 | posts | `moderate_post` | `POST /posts/{post_uuid}/moderate` |
| 0018 | posts | `revise_post` | `PATCH /posts/{post_uuid}/revise` |
| 0019 | posts | `list_pending_posts` | `GET /posts/pending` |
| 0020 | posts | `create_post_status` | modifies existing `create_post` slice |
| 0021 | posts | `list_posts_visibility` | modifies existing `list_posts` slice |
| 0022 | posts | `list_all_posts_visibility` | modifies existing `list_all_posts` slice |

Each slice 0014–0022 has its own spec folder and five spec files (prd, plan,
requirements, validation, tests). Slice 0013 is a DB-only task — it gets a spec
folder but no outside-in test.

### Schema changes (slice 0013)

**`User` ORM model** — add two fields:
- `is_moderator: bool` — defaults to `False`; indexed for fast permission checks
- `moderator_granted_by_user_id: int | None` — nullable FK to `user.id`;
  set when moderator is assigned, cleared when revoked

**`Post` ORM model** — add one field:
- `status: str` — values: `pending_review`, `approved`, `changes_requested`;
  indexed; default `pending_review`

**New ORM model `PostModerationLog`** — columns:
- `id: int` — auto-increment PK
- `post_id: int` — FK to `post.id`, indexed
- `user_id: int` — FK to `user.id`; the acting user (moderator or author)
- `event_type: str` — `moderator_review` | `author_revision`
- `action: str | None` — `approved` | `changes_requested`; only when
  `event_type = moderator_review`
- `message: str | None` — moderator remark or author reply; optional for
  `approved`, required for `changes_requested` and `author_revision`
- `created_at: datetime`

One Alembic migration covers all three changes.

### Expose moderator flag (slice 0014)

- `GetUserByUsernameResponse` gains `is_moderator: bool`
- `UserMeRead` schema gains `is_moderator: bool`
- The `get_user_by_username` adapter query already fetches the full `User` row;
  the field only needs to be mapped in the entity and response schema
- `list_users` response does **not** expose `is_moderator`

### Assign moderator (slice 0015)

- `PATCH /users/{username}/assign-moderator`
- Requester must be `is_superuser`; HTTP 403 otherwise
- Use-case raises `NotFoundDomainError` if user not found
- Use-case raises `DuplicateValueDomainError` if user is already a moderator
- Sets `is_moderator = True` and `moderator_granted_by_user_id = requester.id`
- Response: updated user profile (same shape as `GetUserByUsernameResponse`)

### Revoke moderator (slice 0016)

- `PATCH /users/{username}/revoke-moderator`
- Requester must be `is_superuser`; HTTP 403 otherwise
- Use-case raises `NotFoundDomainError` if user not found
- Use-case raises `DomainError` (409) if user is not currently a moderator
- Sets `is_moderator = False` and `moderator_granted_by_user_id = None`
- Response: updated user profile

### Moderate post (slice 0017)

- `POST /posts/{post_uuid}/moderate`
- Requester must be `is_moderator` or `is_superuser`; HTTP 403 otherwise
- Use-case raises `NotFoundDomainError` if post not found
- Use-case raises `ForbiddenDomainError` if requester is the post author
- Use-case raises `DomainError` (409) if post status is already `approved`
- Request body: `{ action: "approved" | "changes_requested", message: str | None }`
- `message` is required when `action = changes_requested`; optional for
  `approved`
- Side effects:
  - Post `status` updated to match `action`
  - New `PostModerationLog` row inserted (`event_type = moderator_review`)
- Response: post UUID, new status, and the log entry just created

### Revise post (slice 0018)

- `PATCH /posts/{post_uuid}/revise`
- Requester must be the post author; HTTP 403 otherwise
- Use-case raises `NotFoundDomainError` if post not found
- Use-case raises `ForbiddenDomainError` if post status is not `changes_requested`
- Request body: `{ title: str | None, text: str | None, message: str | None }`
  (all fields optional; at least one of `title`/`text` must be present)
- Side effects:
  - Post `title` and/or `text` updated (only fields provided)
  - Post `updated_at` refreshed
  - Post `status` reset to `pending_review`
  - New `PostModerationLog` row inserted (`event_type = author_revision`,
    `action = None`, `message = message`)
- Response: updated post fields plus new status

### List pending posts (slice 0019)

- `GET /posts/pending?page=1&items_per_page=10`
- Requester must be `is_moderator` or `is_superuser`; HTTP 403 otherwise
- Returns posts with status `pending_review` OR `changes_requested`
- Each item includes: `post_uuid`, `title`, `text`, `media_url`, `status`,
  `created_at`, `updated_at`, `author_username`, `moderation_log` (ordered
  chronologically, includes all events)
- Paginated

### Create post with status (slice 0020)

- Modifies the existing `create_post` slice
- `CreatePostAdapter.create()` sets `status = pending_review` on insert
- `CreatePostResponse` gains a `status: str` field
- No changes to routing or DI wiring; port interface gains `status` on
  the returned `CreatedPost` entity

### List posts visibility (slice 0021)

- Modifies the existing `list_posts` slice (`GET /users/{username}/posts`)
- `ListPostsQuery` gains `requester_username: str | None`
- Use-case logic:
  - If `requester_username == target_username`: no status filter (author sees all)
  - Otherwise: filter to `status = approved` only
- The router extracts `requester_username` from an optional auth dependency
  (`get_optional_user`) and passes it into the command
- Adapter query adds the conditional `WHERE status = 'approved'` clause

### List all posts visibility (slice 0022)

- Modifies the existing `list_all_posts` slice (`GET /posts`)
- `ListAllPostsQuery` gains `requester_is_privileged: bool`
- Use-case logic:
  - If `requester_is_privileged` (moderator or superuser): no status filter
  - Otherwise: filter to `status = approved` only
- The router resolves the optional current user and sets
  `requester_is_privileged = user["is_moderator"] or user["is_superuser"]`
- Adapter query adds the conditional `WHERE status = 'approved'` clause

### Authentication dependency additions

- A new `get_current_moderator` dependency (analogous to `get_current_superuser`)
  raises `ForbiddenException` if the current user has neither `is_moderator` nor
  `is_superuser`. Used by `moderate_post` and `list_pending_posts`.

### State machine summary

```
create_post  →  pending_review
moderate_post (approved)           pending_review  →  approved
moderate_post (changes_requested)  pending_review  →  changes_requested
revise_post                        changes_requested  →  pending_review
```

`approved` is a terminal state — no further moderation actions are accepted.

## Testing Decisions

Good tests verify observable behaviour through the public interface. They do
not assert which internal methods were called unless the call itself is the
observable behaviour.

### Unit tests (use-case layer)

Each use-case is unit-tested with a mocked port:

- `assign_moderator`: assert superuser check, not-found, duplicate-moderator,
  happy path (correct fields passed to port)
- `revoke_moderator`: assert superuser check, not-found, not-a-moderator,
  happy path
- `moderate_post`: assert moderator check, not-found, self-review guard,
  already-approved guard, required-message guard for `changes_requested`,
  happy path for both actions
- `revise_post`: assert author check, not-found, wrong-status guard, happy path
- `list_pending_posts`: assert moderator check, paginated result passthrough

Prior art: `tests/features/users/0007_delete_user/` use-case unit test.

### Unit tests (adapter layer)

Adapter tests use a real async session against the test Postgres database.
They validate that:

- Business-meaningful infrastructure exceptions (e.g. FK violation on
  `PostModerationLog.post_id`) translate into the correct `DomainError`
- Happy-path DB operations return correctly mapped entities
- The conditional status filter in `list_posts` and `list_all_posts` adapters
  produces the correct SQL (`WHERE status = 'approved'` vs no filter)

Prior art: `tests/features/users/0001_create_user/` adapter unit test.

### Integration tests (endpoint layer)

`httpx.AsyncClient` against the running app with test Postgres. Every endpoint
is covered for:

- Happy path (correct status code + response shape)
- Auth failure (401, 403)
- Domain error cases (404, 409, 422)

Prior art: `tests/features/posts/0011_create_post/` integration test.

### Outside-in tests (acceptance gate)

Each slice from 0014 to 0022 has one outside-in test that covers the primary
happy path end-to-end. Slice 0013 (DB only) has no outside-in test. The slice
is not done until its outside-in test is green.

## Out of Scope

- Email or in-app notifications to authors when a post is approved or has
  changes requested.
- A dedicated "rejected" status — the current design allows indefinite
  revision cycles; hard rejection may be added in a future slice.
- Multiple required approvals before a post is published — the current design
  requires exactly one approval; the `PostModerationLog` table is designed to
  support an N-approvals rule without schema changes.
- Moderator self-service: moderators cannot assign or revoke their own role.
- Admin UI (CRUDAdmin) wiring for `PostModerationLog`.
- Rate limiting on moderation or revision endpoints.
- Media upload handling — `media_url` remains a plain string field.
- Pagination or filtering on the per-post moderation log returned in responses.

## Further Notes

- The `PostModerationLog` table is intentionally append-only. Events are never
  updated or deleted, preserving the full audit trail.
- `moderator_granted_by_user_id` stores only the last grantor. If full grant
  history is needed in the future, a separate `ModeratorAssignmentLog` table
  should be introduced.
- Slices 0020–0022 modify existing slices. The outside-in tests for the
  original slices (0009, 0010, 0011) must remain green throughout. If a
  modification breaks an existing outside-in test, the modification is a
  behaviour change and must update that test first.
- The `get_current_moderator` dependency should be added to
  `features/users/dependencies.py` alongside `get_current_superuser`.
- `PostModerationLog.message` enforcement (required for `changes_requested`,
  optional for `approved`) is a use-case responsibility, not a DB constraint.

## Sub tasks

| 0013 | infra | moderation_db_foundation | Complete | `specs/features/moderation/0013_moderation_db_foundation/` |
| 0014 | users | expose_moderator_flag | Complete | `specs/features/users/0014_expose_moderator_flag/` |
| 0015 | users | assign_moderator | Complete | `specs/features/users/0015_assign_moderator/` |
| 0016 | users | revoke_moderator | Complete | `specs/features/users/0016_revoke_moderator/` |
| 0017 | posts | moderate_post | Complete  | `specs/features/posts/0017_moderate_post/` |
| 0018 | posts | revise_post | Complete | `specs/features/posts/0018_revise_post/` |
| 0019 | posts | list_pending_posts | Complete | `specs/features/posts/0019_list_pending_posts/` |
| 0020 | posts | create_post_status | Complete | `specs/features/posts/0020_create_post_status/` |
| 0021 | posts | list_posts_visibility | Complete | `specs/features/posts/0021_list_posts_visibility/` |
| 0022 | posts | list_all_posts_visibility | Complete | `specs/features/posts/0022_list_all_posts_visibility/` |
