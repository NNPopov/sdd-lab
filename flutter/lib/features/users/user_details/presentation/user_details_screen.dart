import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/delete_user/presentation/delete_account_button.dart';
import 'package:flutter_application_1/features/users/erase_db_user/presentation/erase_db_user_button.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_state.dart';
import 'package:flutter_application_1/features/users/moderator_contract/presentation/widgets/assign_moderator_button.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_state.dart';
import 'package:flutter_application_1/features/users/update_user_tier/presentation/update_user_tier_button.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_cubit.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_state.dart';
import 'package:flutter_application_1/features/users/user_details/presentation/user_action_visibility.dart';
import 'package:flutter_application_1/features/users/user_details/presentation/widgets/user_details_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({required this.userId, super.key});

  final int userId;

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<UserDetailsCubit>().load(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    // The screen receives only the integer identity; the handle to show in the
    // title comes from the loaded user (empty while loading).
    final username = context.select<UserDetailsCubit, String?>((c) {
      final s = c.state;
      return s is UserDetailsLoaded ? s.user.username : null;
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(username ?? ''),
        actions: [_UserDetailsAppBarActions(userId: widget.userId)],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<UserDetailsCubit, UserDetailsState>(
            listener: (context, state) {
              if (state is UserDetailsLoaded) {
                // getUserTier still keys by the handle (not migrated).
                unawaited(
                  context.read<GetUserTierCubit>().load(state.user.username),
                );
              }
            },
          ),
          BlocListener<UpdateUserTierCubit, UpdateUserTierState>(
            listener: (context, state) {
              if (state is UpdateUserTierSuccess) {
                final detailsState = context.read<UserDetailsCubit>().state;
                if (detailsState is UserDetailsLoaded) {
                  unawaited(
                    context.read<GetUserTierCubit>().load(
                      detailsState.user.username,
                    ),
                  );
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.t.users.updateTier.success),
                  ),
                );
              }
              if (state is UpdateUserTierError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _updateTierErrorMessage(state.failure, context.t),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<UserDetailsCubit, UserDetailsState>(
          builder: (context, state) => switch (state) {
            UserDetailsInitial() => const SizedBox.shrink(),
            UserDetailsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            UserDetailsLoaded(:final user) =>
              BlocBuilder<GetUserTierCubit, GetUserTierState>(
                builder: (context, tierState) => UserDetailsView(
                  user: user,
                  tierName: tierState is GetUserTierLoaded
                      ? tierState.tier.tierName
                      : null,
                  tierCreatedAt: tierState is GetUserTierLoaded
                      ? tierState.tier.tierCreatedAt
                      : null,
                  tierLoading: tierState is GetUserTierLoading,
                  onPostsTap: () => context.router.push(
                    // Posts routes are not migrated — bridge via the handle.
                    UserPostsRoute(username: user.username),
                  ),
                ),
              ),
            UserDetailsError(:final failure) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_errorMessage(failure, t)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => unawaited(
                      context.read<UserDetailsCubit>().retry(widget.userId),
                    ),
                    child: Text(t.common.retry),
                  ),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }

  String _errorMessage(Failure failure, Translations t) {
    if (failure is NotFoundFailure) return t.users.details.notFound;
    return t.users.details.loadError;
  }

  String _updateTierErrorMessage(Failure failure, Translations t) {
    return switch (failure) {
      PermissionDenied() => t.users.updateTier.errors.permissionDenied,
      NotFoundFailure() => t.users.updateTier.errors.notFound,
      ForbiddenFailure() => t.users.updateTier.errors.forbidden,
      UnauthorizedFailure() => t.users.updateTier.errors.unauthorized,
      _ => t.users.updateTier.errors.generic,
    };
  }
}

class _UserDetailsAppBarActions extends StatelessWidget {
  const _UserDetailsAppBarActions({required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    final permissions = context.select<PermissionCubit, Set<Permission>>(
      (c) => c.state,
    );
    final authState = context.select<AuthCubit, AuthState>(
      (c) => c.state,
    );
    final visibility = UserActionVisibility.from(
      permissions,
      authState,
      userId,
    );
    if (!visibility.showAny) return const SizedBox.shrink();

    final bool? isModerator = context.select<UserDetailsCubit, bool?>(
      (c) {
        final s = c.state;
        return s is UserDetailsLoaded ? s.user.isModerator : null;
      },
    );

    // The sibling actions still key by the handle (not migrated); source it
    // from the loaded user. Null while loading — those buttons stay hidden.
    final String? username = context.select<UserDetailsCubit, String?>(
      (c) {
        final s = c.state;
        return s is UserDetailsLoaded ? s.user.username : null;
      },
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (visibility.canManageModerators &&
            isModerator != null &&
            username != null)
          AssignModeratorButton(
            username: username,
            isModerator: isModerator,
            onToggled: (val) =>
                context.read<UserDetailsCubit>().updateIsModerator(val),
          ),
        if (visibility.canEditTier && username != null)
          UpdateUserTierButton(username: username),
        if (visibility.showEdit)
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: context.t.users.edit.title,
            onPressed: () async {
              final cubit = context.read<UserDetailsCubit>();
              final router = context.router;
              await router.push<User>(EditUserRoute(userId: userId));
              unawaited(cubit.load(userId));
            },
          ),
        if (visibility.showDelete) DeleteAccountButton(userId: userId),
        if (visibility.showErase && username != null)
          EraseDbUserButton(username: username),
      ],
    );
  }
}
