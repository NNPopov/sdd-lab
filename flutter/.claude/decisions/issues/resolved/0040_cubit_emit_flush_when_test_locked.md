# Resolved: cubit.stream emits[] when test uses stream.listen + cancel() and test is locked (0040)

## Problem

Outside-in test collected states via `stream.listen` + `await cancel()` and the
test file could not be modified (spec contract):

```dart
final sub1 = cubit1.stream.listen(emitted1.add);
await cubit1.setLocale(AppLocale.esEs);
await sub1.cancel();
expect(emitted1, [AppLocale.esEs]); // FAILS: actual []
```

`cubit1.state` was correctly `esEs` after `setLocale`, but `emitted1` was empty.

## Root cause

Same as [0039](0039_outside_in_stream_listen_race.md): `BlocBase._stateController`
is `StreamController.broadcast(sync: false)`. `emit()` schedules the listener
notification via `scheduleMicrotask`. After `await cubit.setLocale()` returns,
the scheduled microtask is still pending. `await sub1.cancel()` removes the
listener from the controller before that microtask fires, so the event is never
delivered.

## Resolution

When the test cannot be modified, fix it in the **implementation**: add
`await Future<void>.delayed(Duration.zero)` at the end of the async method that
calls `emit`. This yields to the event loop so all pending stream-delivery
microtasks fire before the method returns.

```dart
// LocaleCubit.setLocale — before
Future<void> setLocale(AppLocale locale) async {
  final applied = await LocaleSettings.setLocale(locale);
  await _storage.saveLocale(applied);
  emit(applied);
}

// LocaleCubit.setLocale — after
Future<void> setLocale(AppLocale locale) async {
  final applied = await LocaleSettings.setLocale(locale);
  await _storage.saveLocale(applied);
  emit(applied);
  await Future<void>.delayed(Duration.zero); // flush event loop
}
```

`blocTest` uses the same pattern internally (`await Future<void>.delayed(Duration.zero)`
after `act`), so the fix is consistent with bloc's own test runner.

## Rule

If an outside-in test uses `stream.listen` + `await cancel()` and the test is
**locked** (spec contract, cannot be changed), add
`await Future<void>.delayed(Duration.zero)` after `emit` in the cubit method under
test. This makes the stream delivery happen before the method's Future resolves,
so callers that `await` the method see the emission already delivered.

If the test is **not locked**, prefer the pattern from
[0039](0039_outside_in_stream_listen_race.md): rewrite the test to use
`expectLater`/`emitsInOrder` instead.
