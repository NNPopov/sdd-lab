import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_cubit.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_state.dart';
import 'package:flutter_application_1/features/users/delete_user/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({required this.userId, super.key});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DeleteUserCubit>(),
      child: _DeleteAccountButtonInner(userId: userId),
    );
  }
}

class _DeleteAccountButtonInner extends StatelessWidget {
  const _DeleteAccountButtonInner({required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeleteUserCubit, DeleteUserState>(
      listener: (context, state) async {
        switch (state) {
          case DeleteUserConfirming():
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => const DeleteConfirmationDialog(),
            );
            if (!context.mounted) return;
            if (confirmed == true) {
              unawaited(
                context.read<DeleteUserCubit>().confirmAndDelete(userId),
              );
            } else {
              context.read<DeleteUserCubit>().cancel();
            }
          case DeleteUserSuccess():
            // Show the snackbar on the root messenger before navigating so
            // the context is still valid. The root ScaffoldMessenger (from
            // MaterialApp) persists across the replaceAll navigation.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.t.users.delete.success)),
            );
            unawaited(context.router.replaceAll([const UsersRoute()]));
          case DeleteUserFailure(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_failureMessage(failure, context))),
            );
          case DeleteUserInitial() || DeleteUserDeleting():
            break;
        }
      },
      child: BlocBuilder<DeleteUserCubit, DeleteUserState>(
        builder: (context, state) {
          final isDeleting = state is DeleteUserDeleting;
          return IconButton(
            icon: isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
            tooltip: context.t.users.delete.tooltip,
            onPressed: isDeleting
                ? null
                : () => context.read<DeleteUserCubit>().requestConfirmation(),
          );
        },
      ),
    );
  }

  String _failureMessage(Failure f, BuildContext context) {
    final t = context.t;
    return switch (f) {
      ForbiddenFailure() => t.users.delete.errors.forbidden,
      UnauthorizedFailure() => t.users.delete.errors.unauthorized,
      NotFoundFailure() => t.users.delete.errors.notFound,
      _ => t.users.delete.errors.generic,
    };
  }
}
