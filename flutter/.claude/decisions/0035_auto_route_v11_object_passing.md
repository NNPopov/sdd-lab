# ADR-0035: Passing domain objects to routes in auto_route v11

## Context

Slice 0035 (moderate_post) required navigating from `PendingPostsScreen` to
`ModeratePostScreen` and carrying a full `PendingPostItem` object. The original
plan assumed `context.routeData.extra<PendingPostItem>()` — a pattern common in
go_router — would work in auto_route v11.

`RouteData` in auto_route 11.x has no `extra<T>()` method. The type does not
exist in the generated or hand-written API surface.

## Decision

Pass complex objects as explicit constructor parameters on the `@RoutePage()`
widget. auto_route generates a `<PageName>RouteArgs` class that carries those
fields and feeds them through its own navigation infrastructure.

```dart
// The page widget
@RoutePage()
class ModeratePostPage extends StatelessWidget {
  const ModeratePostPage({
    @PathParam('post_uuid') required this.postUuid,
    required this.post,         // ← typed object, NOT extra
    super.key,
  });
  final String postUuid;
  final PendingPostItem post;
  ...
}

// Navigation call-site
context.router.push(
  ModeratePostRoute(postUuid: item.postUuid, post: item),
);
```

When a required parameter cannot be parsed from the path, auto_route emits:
> WARNING => Because [ModeratePostPage] has required parameters (post) that
> cannot be parsed from path, @PathParam() annotations will be ignored.

This warning is expected and harmless when navigation is always programmatic
(no deep links into this route). Suppress it mentally; do not work around it by
removing the typed parameter.

## Consequences

**Easier:** type-safe navigation with zero boilerplate beyond the constructor;
no `Object?` casts at the destination; works fully with auto_route's generated
code.

**Harder:** routes that carry objects cannot be deep-linked without a separate
resolver (the object is not serialisable from a URL). Acceptable for in-app
moderation screens and similar.

**Rule for future slices:** when a route needs a domain object, always add it as
a required constructor parameter. Never use `extra`, `queryParam` hacks, or a
global state workaround.

## Status

Accepted (2026-05-16)
