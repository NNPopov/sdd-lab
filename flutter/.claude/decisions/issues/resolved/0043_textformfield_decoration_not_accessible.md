# Resolved: TextFormField does not expose `decoration` getter in widget tests (0043)

## Problem

A widget test tried to assert that no form field shows an inline error text
(`errorText`) after a server-side validation error:

```dart
// compile error: The getter 'decoration' isn't defined for the type 'TextFormField'
final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
for (final field in fields) {
  expect(field.decoration?.errorText, isNull); // compile error
}
```

## Root cause

`TextFormField` is a `StatefulWidget` that internally creates a `TextField`
in its `State`. `TextFormField` itself only exposes high-level parameters
(e.g., `validator`, `controller`, `onChanged`) — it does **not** have a
public `decoration` getter. The `InputDecoration` is managed inside the
private `_TextFormFieldState` and forwarded to the underlying `TextField`.

`TextField`, on the other hand, is a `StatelessWidget` (after the state is
resolved) and has a public `final InputDecoration? decoration` field.

## Resolution

Find `TextField` (the underlying widget) instead of `TextFormField`:

```dart
// CORRECT
final fields = tester.widgetList<TextField>(find.byType(TextField));
for (final field in fields) {
  expect(field.decoration?.errorText, isNull);
}
```

`find.byType(TextField)` matches all `TextField` instances in the tree,
including those created internally by `TextFormField`. Since `TextField` is
not a generic widget, `find.byType` is safe here (unlike `PopupMenuButton`,
see `0041_find_by_type_generic_widget.md`).

## Rule

When asserting `decoration.errorText` (or any `InputDecoration` property)
in a widget test, always find `TextField`, not `TextFormField`. The form
widget does not expose its `decoration` publicly.
