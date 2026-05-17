# PRD: Owner-only Edit Button on User Details

## Context
Current behavior allows the edit button to appear on another user's profile when the signed-in user has the `editUsers` permission. The actual profile edit flow should remain owner-only: only the profile owner can edit their own details.

## Problem
- The UI is showing an edit action for non-owner profiles in some permission configurations.
- This creates a mismatch between visible affordances and the authorization model.
- It is confusing for users and risks exposing an action that should not be available.

## Goal
Ensure the user details screen only shows the edit button when the signed-in user is viewing their own profile.

## User stories
- As an authenticated user, I want to see the Edit button only on my own profile, so I do not expect to edit other users' information.
- As a user with broad editing permissions, I want the application to still enforce owner-only profile editing on the user details screen.

## Acceptance criteria
- The edit button is visible only when the current user's username matches the profile username.
- The edit button is hidden for any other profile, regardless of the current user's permissions.
- The current save/edit authorization logic must remain owner-only and consistent with the UI.
- Existing user details navigation and permissions for deleting or erasing accounts remain unchanged unless already subject to different business rules.

## Success metrics
- No user can see the edit action on another user's profile.
- UI behavior aligns with backend/user-cubit authorization checks.
- Regression tests cover both owner and non-owner scenarios.
