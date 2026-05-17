# 0013 · posts / list_posts — Validation Checklist

## Manual Testing

- [ ] Launched the app — the Posts tab is visible in the menu (unauthenticated user)
- [ ] Tapped Posts — a screen with the title "Posts" opened, body is empty
- [ ] The Posts tab is located between Users and Tiers
- [ ] Logged in as a superuser — the Tiers tab appeared to the right of Posts
- [ ] Navigated to Tiers, tapped Logout — the app switched to Users (index 0)
- [ ] The Posts tab is active when navigating to `/posts`

## Code

- [ ] No hardcoded strings — only `context.t.nav.posts`
- [ ] `ListPostsRoute.page` is registered in AppShellRoute without guards
- [ ] `AutoTabsRouter.routes` contains `[UsersRoute(), ListPostsRoute(), ListTiersRoute()]`
- [ ] In `app_shell_screen.dart` the Tiers index is updated from 1 to 2 (three places)
- [ ] `posts_feature_module.dart` is annotated with `@module`
- [ ] Codegen `dart run slang` completed without errors
- [ ] Codegen `dart run build_runner build` completed without errors
- [ ] `flutter analyze` with no new errors
