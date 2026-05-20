# Resolved: find.byType does not match generic widget instantiations (0041)

## Problem

In widget tests for slice 0041 (user_header_menu), assertions like:

```dart
expect(find.byType(PopupMenuButton), findsOneWidget); // FAILS
expect(find.byType(PopupMenuButton), findsNothing);   // trivially passes, useless
```

silently did the wrong thing. The widget in the tree was
`PopupMenuButton<_UserMenuAction>`, but neither assertion behaved correctly.

## Root cause

Flutter's `find.byType(T)` compares `widget.runtimeType == type` using Dart `Type`
object identity. The type literal `PopupMenuButton` without a type argument evaluates
to `PopupMenuButton<dynamic>` at runtime. The actual widget has
`runtimeType == PopupMenuButton<_UserMenuAction>`. These two `Type` objects are not
equal, so `byType` never matches the widget.

The problem is invisible when asserting `findsNothing` (the assertion trivially
passes, giving false confidence), and actively wrong when asserting `findsOneWidget`
(the assertion fails even when the widget is present).

The situation is compounded when the generic type argument is **private** to another
file (e.g., `_UserMenuAction`) — `find.byType(PopupMenuButton<_UserMenuAction>)` is
a compile error in the test file.

## Resolution

Use `find.byWidgetPredicate` with an `is` check instead of `find.byType`:

```dart
// WRONG — silent false result when T is generic
find.byType(PopupMenuButton)

// CORRECT — uses subtype check, matches any PopupMenuButton<T>
find.byWidgetPredicate((w) => w is PopupMenuButton)
```

Dart's `is` operator uses subtype checking: `PopupMenuButton<X> is PopupMenuButton`
evaluates to `true` for any `X`, because `PopupMenuButton<X>` is a subtype of
`PopupMenuButton<dynamic>`. This works even when `X` is a private type from another
library.

## Rule

When writing a widget test that asserts presence or absence of a **generic widget**
(`PopupMenuButton<T>`, `BlocBuilder<C, S>`, etc.), always use:

```dart
find.byWidgetPredicate((w) => w is SomeGenericWidget)
```

Never use `find.byType(SomeGenericWidget)` for generic widgets — the result is
either a false negative (widget present but not found) or a trivially true negative
(widget absent and findsNothing passes for the wrong reason).

`find.byType` is safe only for non-generic widgets (e.g., `BackButton`,
`AlertDialog`, `CircularProgressIndicator`).
