# 0011 · edit_tier — Validation

## Implementation checklist

### Architecture
- [ ] The `edit_tier` slice does not import other tier slices (`list_tiers`, `create_tier`, `tier_details`)
- [ ] `domain/` does not import `package:flutter/*` or `package:dio/*`
- [ ] `EditTierAdapter` has double catch (inner `on DioException`, outer `catch (e, st)`)
- [ ] `EditTierUseCase` checks `isSuperuser` and returns `Left(PermissionDenied())` if false, without calling the port

### RBAC
- [ ] The `/tier/:name/edit` route is protected by `AuthGuard` + `PermissionGuard({Permission.manageTiers})`
- [ ] The edit button in `tier_details_screen.dart` is visible only when `currentUser?.isSuperuser == true`
- [ ] Use-case as the final line of defense: `isSuperuser: false` → `Left(PermissionDenied())`

### UX
- [ ] The "name" field is pre-populated with the current tier name
- [ ] The Save button is disabled in `EditTierSubmitting` state
- [ ] Success: snackbar + pop with `newName`
- [ ] `tier_details_screen.dart` after receiving `newName` does `router.replace(TierDetailsRoute(tierName: newName))`
- [ ] 404: snackbar with `t.tiers.editTier.errors.notFound`
- [ ] Generic error: snackbar with `t.tiers.editTier.errors.generic`

### Tests
- [ ] `edit_tier_usecase_test.dart`: isSuperuser=false → PermissionDenied, port NOT called
- [ ] `edit_tier_usecase_test.dart`: isSuperuser=true + success → Right(unit)
- [ ] `edit_tier_cubit_test.dart`: happy path → [Submitting, Success(newName)]
- [ ] `edit_tier_cubit_test.dart`: failure → [Submitting, Failure(failure)]
- [ ] `edit_tier_adapter_test.dart`: 200 → Right(unit)
- [ ] `edit_tier_adapter_test.dart`: 404 → Left(NotFoundFailure)
- [ ] `edit_tier_adapter_test.dart`: unexpected exception → Left(UnknownFailure), logger.error called

### Codegen
- [ ] `tiers_api_client.g.dart` regenerated (patchTier added)
- [ ] `edit_tier_request_dto.freezed.dart` and `*.g.dart` generated
- [ ] `edit_tier_state.freezed.dart` generated
- [ ] `app_router.gr.dart` updated (EditTierRoute added)
- [ ] `translations.g.dart` updated (tiers.editTier.* keys added)
- [ ] `injection.config.dart` updated (EditTierCubit, EditTierAdapter registered)
