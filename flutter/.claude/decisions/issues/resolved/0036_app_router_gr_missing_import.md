# Resolved: app_router.gr.dart references PendingPostItem without import (0036)

## Problem

Several widget tests that imported `app_router.dart` (via the router or shell)
failed to compile with:

```
lib/core/routing/app_router.gr.dart:360:14: Error: Type 'PendingPostItem' not found.
    required PendingPostItem post,
```

`app_router.gr.dart` is a `part of 'app_router.dart'` file, so it relies entirely
on the imports declared in `app_router.dart`. The generated route for
`ModeratePostPage` uses `PendingPostItem` as a constructor parameter type, but
`app_router.dart` never imported that type — causing a compile error for any test
that transitively depends on the router.

The issue was pre-existing (visible in git status as a modified but uncommitted
`app_router.dart`) and became visible during the `flutter test` run.

## Resolution

Added the missing import to `lib/core/routing/app_router.dart`:

```dart
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
```

## Rule

Whenever a `@RoutePage()` widget adds a new non-primitive parameter type, that
type **must** be imported in `app_router.dart` (not just in the route file), because
`app_router.gr.dart` is a part file and can only see what `app_router.dart` imports.
`auto_route_generator` does not add these imports automatically. After running
`build_runner`, always check the generated `.gr.dart` for any type references and
ensure they are covered by `app_router.dart` imports.
