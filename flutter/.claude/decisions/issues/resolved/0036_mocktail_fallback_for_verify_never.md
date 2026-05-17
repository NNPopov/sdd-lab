# Resolved: mocktail requires registerFallbackValue for every type used in verifyNever (0036)

## Problem

The outside-in test for `revise_post` failed on the second scenario with:

```
Bad state: A test tried to use `any` or `captureAny` on a parameter of type
`UpdatePostRequestDto`, but registerFallbackValue was not previously called.
```

The test called `verifyNever(() => api.patchPost(any(), any(), any()))` to assert
that the regular edit endpoint was not invoked. The third `any()` matcher maps to
the `UpdatePostRequestDto` parameter of `patchPost`. mocktail requires a registered
fallback for **every concrete type** that `any()` will be matched against — even
in `verifyNever` calls where the method is asserted to have never been called.

The `setUpAll` block only registered `RevisePostRequestDto` and `UpdatedPostData`,
but not `UpdatePostRequestDto`.

## Resolution

Added the missing fallback registration in `setUpAll`:

```dart
registerFallbackValue(
  const UpdatePostRequestDto(title: '', text: ''),
);
```

And added the corresponding import:

```dart
import 'package:flutter_application_1/features/posts/_shared/data/dto/update_post_request_dto.dart';
```

## Rule

In any test that uses `any()` inside a `when()`, `verify()`, or `verifyNever()`
call, **every distinct parameter type** that will be matched by `any()` must have
a fallback registered in `setUpAll`. This applies even if the method is only
referenced to assert it was never called. When writing `verifyNever` assertions
over methods whose parameter types are different from those used in `when()` stubs,
always add the missing `registerFallbackValue` calls up front.
