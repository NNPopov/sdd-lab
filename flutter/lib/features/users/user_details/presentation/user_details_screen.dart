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
import 'package:flutter_application_1/features/users/user_details/presentation/widgets/user_details_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({required this.username, super.key});

  final String username;

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<UserDetailsCubit>().load(widget.username));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        actions: [
          BlocBuilder<PermissionCubit, Set<Permission>>(
            builder: (context, permissions) {
              return BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final isMe =
                      authState is AuthAuthenticated &&
                      authState.currentUser?.username == widget.username;
                  final canErase = permissions.contains(Permission.eraseUsers);
                  final canEditTier = permissions.contains(
                    Permission.editUserTier,
                  );
                  final canManageModerators = permissions.contains(
                    Permission.manageModerators,
                  );

                  final showEdit = isMe;
                  final showDelete = isMe;
                  final showErase = canErase;

                  if (!showEdit &&
                      !showDelete &&
                      !showErase &&
                      !canEditTier &&
                      !canManageModerators) {
                    return const SizedBox.shrink();
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canManageModerators)
                        BlocBuilder<UserDetailsCubit, UserDetailsState>(
                          builder: (context, userState) {
                            if (userState is UserDetailsLoaded) {
                              return AssignModeratorButton(
                                username: widget.username,
                                isModerator: userState.user.isModerator,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      if (canEditTier)
                        UpdateUserTierButton(username: widget.username),
                      if (showEdit)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: t.users.edit.title,
                          onPressed: () async {
                            final cubit = context.read<UserDetailsCubit>();
                            final updated = await context.router.push<User>(
                              EditUserRoute(username: widget.username),
                            );
                            if (!mounted) return;
                            unawaited(
                              cubit.load(
                                updated?.username ?? widget.username,
                              ),
                            );
                          },
                        ),
                      if (showDelete)
                        DeleteAccountButton(username: widget.username),
                      if (showErase)
                        EraseDbUserButton(username: widget.username),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<UserDetailsCubit, UserDetailsState>(
            listener: (context, state) {
              if (state is UserDetailsLoaded) {
                unawaited(
                  context.read<GetUserTierCubit>().load(widget.username),
                );
              }
            },
          ),
          BlocListener<UpdateUserTierCubit, UpdateUserTierState>(
            listener: (context, state) {
              if (state is UpdateUserTierSuccess) {
                unawaited(
                  context.read<GetUserTierCubit>().load(widget.username),
                );
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
                    UserPostsRoute(username: widget.username),
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
                      context.read<UserDetailsCubit>().retry(widget.username),
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
