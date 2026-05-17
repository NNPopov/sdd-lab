# Resolved: PostEventBus uses publish(), not add() (0035)

## Problem

The plan for slice 0035 instructed emitting events via `_eventBus.add(event)`,
following the standard `StreamController` API. Calling `add()` on `PostEventBus`
produces a compile error: the method does not exist on that type.

## Resolution

`PostEventBus` wraps its internal `StreamController` and exposes a single
domain-named method:

```dart
_eventBus.publish(PostModeratedEvent(postUuid));
```

Reading `lib/features/posts/_shared/application/post_event_bus.dart` before
writing any Cubit that fires an event is the surest way to avoid this.

## File reference

`lib/features/posts/_shared/application/post_event_bus.dart` — `publish()` is
the only emission API; `add()` is not forwarded.
