import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/auth/infrastructure/auth_guard.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/routing/app_shell_route.dart';
import 'package:flutter_application_1/core/routing/guards/permission_guard.dart';
import 'package:flutter_application_1/core/routing/tabs/pending_tab_route.dart';
import 'package:flutter_application_1/core/routing/tabs/posts_tab_route.dart';
import 'package:flutter_application_1/core/routing/tabs/tiers_tab_route.dart';
import 'package:flutter_application_1/core/routing/tabs/users_tab_route.dart';
import 'package:flutter_application_1/features/auth/login/presentation/login_route.dart';
import 'package:flutter_application_1/features/posts/create_post/presentation/create_post_route.dart';
import 'package:flutter_application_1/features/posts/edit_post/presentation/edit_post_route.dart';
import 'package:flutter_application_1/features/posts/list_posts/presentation/list_posts_route.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/moderate_post_route.dart';
import 'package:flutter_application_1/features/posts/pending_posts/presentation/pending_posts_route.dart';
import 'package:flutter_application_1/features/posts/post_details/presentation/post_details_route.dart';
import 'package:flutter_application_1/features/posts/user_posts/presentation/user_posts_route.dart';
import 'package:flutter_application_1/features/tiers/create_tier/presentation/create_tier_route.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/presentation/edit_tier_route.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/presentation/list_tiers_route.dart';
import 'package:flutter_application_1/features/tiers/tier_details/presentation/tier_details_route.dart';
import 'package:flutter_application_1/features/users/create_user/presentation/create_user_route.dart';
import 'package:flutter_application_1/features/users/edit_user/presentation/edit_user_route.dart';
import 'package:flutter_application_1/features/users/list_users/presentation/users_route.dart';
import 'package:flutter_application_1/features/users/user_details/presentation/user_details_route.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter({required this.authGuard, required this.permissionCubit});

  final AuthGuard authGuard;
  final PermissionCubit permissionCubit;

  late final List<AutoRoute> _routeTree = [
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(
      page: AppShellRoute.page,
      path: '/',
      initial: true,
      children: [
        // ── Users tab ──────────────────────────────────────────────
        AutoRoute(
          page: UsersTabRoute.page,
          path: '',
          initial: true,
          children: [
            AutoRoute(page: UsersRoute.page, initial: true, path: ''),
            AutoRoute(page: CreateUserRoute.page, path: 'users/new'),
            AutoRoute(
              page: UserDetailsRoute.page,
              path: 'user/:username',
            ),
            AutoRoute(
              page: EditUserRoute.page,
              path: 'user/:username/edit',
              guards: [authGuard],
            ),
            AutoRoute(
              page: UserPostsRoute.page,
              path: 'user/:username/posts',
            ),
            AutoRoute(
              page: CreatePostRoute.page,
              path: 'user/:username/posts/create',
              guards: [authGuard],
            ),
            AutoRoute(
              page: PostDetailsRoute.page,
              path: 'user/:username/posts/:id',
            ),
            AutoRoute(
              page: EditPostRoute.page,
              path: 'user/:username/posts/:id/edit',
              guards: [authGuard],
            ),
          ],
        ),

        // ── Posts tab ──────────────────────────────────────────────
        AutoRoute(
          page: PostsTabRoute.page,
          path: 'posts',
          children: [
            AutoRoute(page: ListPostsRoute.page, initial: true, path: ''),
            AutoRoute(
              page: PostDetailsRoute.page,
              path: ':username/posts/:id',
            ),
            AutoRoute(
              page: EditPostRoute.page,
              path: ':username/posts/:id/edit',
              guards: [authGuard],
            ),
            AutoRoute(
              page: CreatePostRoute.page,
              path: ':username/posts/create',
              guards: [authGuard],
            ),
          ],
        ),

        // ── Tiers tab ──────────────────────────────────────────────
        AutoRoute(
          page: TiersTabRoute.page,
          path: 'tiers',
          guards: [
            authGuard,
            PermissionGuard({Permission.manageTiers}, permissionCubit),
          ],
          children: [
            AutoRoute(page: ListTiersRoute.page, initial: true, path: ''),
            AutoRoute(
              page: TierDetailsRoute.page,
              path: ':id',
              guards: [
                authGuard,
                PermissionGuard({Permission.manageTiers}, permissionCubit),
              ],
            ),
            AutoRoute(
              page: CreateTierRoute.page,
              path: 'new',
              guards: [
                authGuard,
                PermissionGuard({Permission.manageTiers}, permissionCubit),
              ],
            ),
            AutoRoute(
              page: EditTierRoute.page,
              path: ':id/edit',
              guards: [
                authGuard,
                PermissionGuard({Permission.manageTiers}, permissionCubit),
              ],
            ),
          ],
        ),

        // ── Pending tab ────────────────────────────────────────────
        AutoRoute(
          page: PendingTabRoute.page,
          path: 'pending',
          guards: [
            authGuard,
            PermissionGuard({Permission.moderatePosts}, permissionCubit),
          ],
          children: [
            AutoRoute(page: PendingPostsRoute.page, initial: true, path: ''),
            AutoRoute(
              page: ModeratePostRoute.page,
              path: ':post_uuid/moderate',
              guards: [
                authGuard,
                PermissionGuard({Permission.moderatePosts}, permissionCubit),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  List<AutoRoute> get routes => _routeTree;
}
