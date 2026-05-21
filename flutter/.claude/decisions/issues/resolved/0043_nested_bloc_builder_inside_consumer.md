# Resolved: nested BlocBuilder inside BlocConsumer.builder doesn't reliably rebuild (0043)

## Problem

`CreateUserScreen` had a nested `BlocBuilder` with `buildWhen` inside the
`BlocConsumer`'s builder to show/hide a validation error text:

```dart
BlocConsumer<CreateUserCubit, CreateUserState>(
  listener: ...,
  builder: (context, state) {
    return Scaffold(
      body: Form(
        child: ListView(
          children: [
            ...fields,
            BlocBuilder<CreateUserCubit, CreateUserState>(
              buildWhen: (_, s) =>
                  s is CreateUserValidationError || s is CreateUserIdle,
              builder: (context, state) {
                if (state is CreateUserValidationError) {
                  return Padding(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  },
)
```

Widget test for the `validationError → idle` transition failed:

```dart
controller.add(const CreateUserState.validationError(message: 'Username taken'));
await tester.pump();
expect(find.text('Username taken'), findsOneWidget); // OK

controller.add(const CreateUserState.idle());
await tester.pump();
expect(find.text('Username taken'), findsNothing); // FAILS: still finds 1
```

## Root cause

In `flutter_bloc` 9.x, `BlocBuilderBase.build()` wraps the child in a
`BlocListener` (from the `nested` package's `SingleChildStatefulWidget`).
When the outer `BlocConsumer` rebuilds, the nested `BlocBuilder` is recreated
as a widget, but its internal `_BlocBuilderBaseState` may not immediately
rebuild its subtree. For transitions that **remove** a widget from the tree
(e.g., returning `SizedBox.shrink()` where `Text()` was), an extra frame is
required beyond what the outer consumer already provides. The `buildWhen`
filter on the inner builder adds another indirection that compounds the issue.

## Resolution

Remove the nested `BlocBuilder`. Use the outer `BlocConsumer`'s `state`
directly in the builder via a local variable:

```dart
builder: (context, state) {
  final isSubmitting = state is CreateUserSubmitting;
  final validationMessage =
      state is CreateUserValidationError ? state.message : null;
  return Scaffold(
    body: Form(
      child: ListView(
        children: [
          ...fields,
          if (validationMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                validationMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    ),
  );
},
```

In the corresponding widget test, the `validationError → idle` transition
(the one that **removes** a widget) still needs one extra `pump()` due to
`BlocConsumer`'s internal `BlocListener` frame propagation:

```dart
controller.add(const CreateUserState.idle());
await tester.pump();
await tester.pump(); // extra pump: BlocListener delivers removal in next frame
expect(find.text('Username taken'), findsNothing); // passes
```

This asymmetry is expected: adding a widget (`idle → validationError`) takes
1 pump; removing a widget (`validationError → idle`) takes 2 pumps.

## Rule

Do **not** nest a `BlocBuilder` (or another `BlocConsumer`) inside an outer
`BlocConsumer.builder`. The outer builder already receives the current state
as a parameter — use it directly with local variables and conditional
expressions (`if`, `?:`, `switch`). A nested `BlocBuilder` adds a frame
boundary and `buildWhen` logic that can cause visible-but-not-rebuilding bugs
that are hard to diagnose in tests.
