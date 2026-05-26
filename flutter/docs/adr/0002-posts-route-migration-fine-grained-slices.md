---
status: accepted
---

# Migrate the posts `{username}` → `{user_id}` surface as three fine-grained slices

The posts route migration (the backend is already on `user_id`, on a separate
unmerged branch) is split into three slices rather than one combined change:
**0051** read/edit (`get_post`, `update_post` → screens `post_details`, `edit_post`),
**0052** delete (`delete_post`, `erase_db_post`), **0053** by-author
(`get_user_posts`, `create_post` → screens `user_posts`, `create_post`). Unlike the
*users* migration — where `user_details` and `edit_user` were **combined** because
they shared one `getUser` method (see `ADR-0001`) — no two posts verticals share an
API method, so they can be split freely. We split them deliberately small to keep
each slice's context narrow and reduce LLM implementation error, accepting that the
intermediate states leave a temporary mixed `username`/`id` surface.

A related decision for `user_posts`: the route is keyed by `user_id` (identity), and
the author's `username` (the displayed handle) is carried as a **separate, non-path
route argument**, never embedded in the URL — so the AppBar title keeps working for
in-app navigation without putting a handle in the URL, per `CONTEXT.md`.

## Considered options

- **One combined posts slice (rejected).** Fewer commits and a single acceptance
  gate, but a large multi-file change is exactly the broad-context situation where an
  LLM implementer drops or mismatches edits.
- **Two grouped slices — single-post vs by-author (rejected).** Better, but the
  single-post group was still large; splitting read/edit apart from delete/erase
  shrinks each unit further.
- **Three fine-grained slices (accepted).** Each slice is one or two verticals with a
  narrow blast radius and its own green gate.
- **`user_posts` title from loaded posts (rejected).** Mirrors slice 0050's "source
  the handle from the loaded entity", but an author with zero posts yields no handle;
  carrying it as a route arg preserves the title for all in-app navigation.

## Consequences

- Three commits / three acceptance gates instead of one.
- **Temporary mixed-key surfaces between slices, by design.** After 0051 the
  `post_details` actions row has **Edit by `id`** but **Delete/Erase still by the
  handle** (sourced from the loaded `post.username`); 0052 finishes the row. Precedent:
  users slice 0049's mixed-key actions row.
- The DTO tightening (`created_by_user_id` → `required int`, drop the `?? 0`
  fallbacks) lands in **0051**, because `post_details` is the navigation hub that the
  feed and the author's-posts list start routing into by `id`.
- The Flutter changes must be merged **with or after** the backend posts migration;
  merging earlier breaks posts against the current `dev`, where posts are still
  `{username}`.
