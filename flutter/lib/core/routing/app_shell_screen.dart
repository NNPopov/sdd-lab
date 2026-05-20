import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/core/widgets/locale_selector_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppShellScreen extends StatelessWidget {
  const AppShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        UsersTabRoute(),
        PostsTabRoute(),
        TiersTabRoute(),
        PendingTabRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) =>
              curr is AuthUnauthenticated &&
              (tabsRouter.activeIndex == 2 || tabsRouter.activeIndex == 3),
          listener: (context, _) => tabsRouter.setActiveIndex(0),
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(context.t.app.title),
              bottom: _AppNavBar(tabsRouter: tabsRouter),
              actions: const [LocaleSelectorButton(), _AuthAppBarAction()],
            ),
            body: child,
          ),
        );
      },
    );
  }
}

class _AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppNavBar({required this.tabsRouter});

  final TabsRouter tabsRouter;

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionCubit, Set<Permission>>(
      builder: (context, permissions) {
        final canModerate = permissions.contains(Permission.moderatePosts);
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isSuperuser =
                state is AuthAuthenticated &&
                (state.currentUser?.isSuperuser ?? false);

            return Row(
              children: [
                _NavTab(
                  label: context.t.nav.users,
                  isSelected: tabsRouter.activeIndex == 0,
                  onTap: () => _resetAndSwitch(
                    tabsRouter,
                    0,
                    UsersTabRoute.name,
                    const UsersRoute(),
                  ),
                ),
                _NavTab(
                  label: context.t.nav.posts,
                  isSelected: tabsRouter.activeIndex == 1,
                  onTap: () => _resetAndSwitch(
                    tabsRouter,
                    1,
                    PostsTabRoute.name,
                    const ListPostsRoute(),
                  ),
                ),
                if (isSuperuser)
                  _NavTab(
                    label: context.t.nav.tiers,
                    isSelected: tabsRouter.activeIndex == 2,
                    onTap: () => _resetAndSwitch(
                      tabsRouter,
                      2,
                      TiersTabRoute.name,
                      const ListTiersRoute(),
                    ),
                  ),
                if (canModerate)
                  _NavTab(
                    label: context.t.nav.pending,
                    isSelected: tabsRouter.activeIndex == 3,
                    onTap: () => _resetAndSwitch(
                      tabsRouter,
                      3,
                      PendingTabRoute.name,
                      const PendingPostsRoute(),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _resetAndSwitch(
    TabsRouter tabsRouter,
    int index,
    String tabName,
    PageRouteInfo root,
  ) {
    tabsRouter.innerRouterOf<StackRouter>(tabName)?.replaceAll([root]);
    tabsRouter.setActiveIndex(index);
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

enum _UserMenuAction { myProfile, myPosts, signOut }

class _AuthAppBarAction extends StatelessWidget {
  const _AuthAppBarAction();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) => switch (state) {
        AuthAuthenticated(:final currentUser) when currentUser != null =>
          PopupMenuButton<_UserMenuAction>(
            onSelected: (action) =>
                _onMenuAction(context, action, currentUser.username),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _UserMenuAction.myProfile,
                child: Text(context.t.userMenu.myProfile),
              ),
              PopupMenuItem(
                value: _UserMenuAction.myPosts,
                child: Text(context.t.userMenu.myPosts),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _UserMenuAction.signOut,
                child: Text(context.t.auth.logout.confirm),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(currentUser.username),
            ),
          ),
        AuthAuthenticated() => const SizedBox.shrink(),
        AuthUnauthenticated() || AuthError() => TextButton(
          onPressed: () => unawaited(context.router.push(LoginRoute())),
          child: Text(context.t.auth.login.signInButton),
        ),
        AuthAuthenticating() => const Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        AuthUnknown() => const SizedBox.shrink(),
      },
    );
  }

  void _onMenuAction(
    BuildContext context,
    _UserMenuAction action,
    String username,
  ) {
    switch (action) {
      case _UserMenuAction.myProfile:
        unawaited(context.router.push(UserDetailsRoute(username: username)));
      case _UserMenuAction.myPosts:
        unawaited(context.router.push(UserPostsRoute(username: username)));
      case _UserMenuAction.signOut:
        _confirmLogout(context);
    }
  }

  void _confirmLogout(BuildContext context) {
    final t = context.t;
    final cubit = context.read<AuthCubit>();
    unawaited(
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.auth.logout.confirmTitle),
          content: Text(t.auth.logout.confirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(t.auth.logout.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(t.auth.logout.confirm),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true) unawaited(cubit.logout());
      }),
    );
  }
}
