# Resolved: stream.listen + await cancel() misses the last state in outside-in tests (0039)

## Problem

An outside-in test collected cubit states with a manual listener:

```dart
final emitted = <PendingPostsState>[];
final sub = cubit.stream.listen(emitted.add);
await cubit.load();
await sub.cancel();
expect(emitted.length, 2); // fails: Actual <1>
```

Both test scenarios always captured only one state instead of two. The second
scenario (server 403) had nothing to do with the deserialization fix and also
failed, confirming the issue was in the collection pattern, not the
implementation.

## Root cause

`bloc` 9's `BlocBase._stateController` is a `StreamController.broadcast()` (async,
`sync: false`). Each `emit()` call schedules the listener notification via
`scheduleMicrotask`. After `await cubit.load()` returns, the last state's
notification microtask is still pending. `await sub.cancel()` cancels the
subscription before that microtask fires, so the last state is never delivered
to `emitted`.

## Resolution

Use `expectLater`/`emitsInOrder` set up **before** the action, then `await` the
expectation after the action. For individual field assertions, read from
`cubit.state` after `await expectation`:

```dart
final expectation = expectLater(
  cubit.stream,
  emitsInOrder([
    const PendingPostsState.loading(),
    isA<PendingPostsLoaded>(),
  ]),
);

await cubit.load();
await expectation;

final loaded = cubit.state as PendingPostsLoaded;
expect(loaded.items.length, 1);
// ... further assertions on loaded
```

## Rule

**Never** collect cubit states into a list via `stream.listen` + `await cancel()`.
Always use `expectLater(cubit.stream, emitsInOrder([...]))` set up before calling
the action. This is the pattern used in all other outside-in tests in this project
(0034, 0035, etc.).
