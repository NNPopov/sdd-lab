# Resolved: PostDetailsState.error() requires `failure` — widget test compile error (0037)

## Problem

When writing widget test case 7 (PostDetailsError state — no chip shown), the test
failed to compile with:

```
Error: Required named parameter 'failure' must be provided.
    postState: const PostDetailsState.error(),
                                           ^
lib/features/posts/post_details/application/post_details_state.dart:13:17:
  const factory PostDetailsState.error({required Failure failure}) = PostDetailsError;
```

The assumption was that `PostDetailsState.error()` could be constructed without
arguments (treating it as a sentinel "any error" value). In reality the freezed
state carries a required `Failure failure` field that must always be provided.

## Resolution

Import `Failure` in the test file and supply a concrete fallback value:

```dart
import 'package:flutter_application_1/core/errors/failure.dart';

// in the test:
postState: const PostDetailsState.error(
  failure: Failure.unknown(),
),
```

`Failure.unknown()` is the correct sentinel for "some error occurred" when the
specific failure type is irrelevant to the assertion being made.

## Rule

Before writing `SomeState.error()` with no arguments in a test, check the freezed
state definition. If `error` carries a `required Failure failure` field, always
provide `Failure.unknown()` (or a more specific failure if the test asserts on it).
Add the `failure.dart` import at the same time.
