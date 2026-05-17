import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/users/erase_db_user/application/erase_db_user_cubit.dart';
import 'package:flutter_application_1/features/users/erase_db_user/application/erase_db_user_state.dart';
import 'package:flutter_application_1/features/users/erase_db_user/presentation/widgets/erase_db_user_confirmation_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EraseDbUserButton extends StatelessWidget {
  const EraseDbUserButton({required this.username, super.key});

  final String username;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EraseDbUserCubit>(),
      child: _EraseDbUserButtonInner(username: username),
    );
  }
}

class _EraseDbUserButtonInner extends StatelessWidget {
  const _EraseDbUserButtonInner({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return BlocListener<EraseDbUserCubit, EraseDbUserState>(
      listener: (context, state) async {
        switch (state) {
          case EraseDbUserConfirming():
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => const EraseDbUserConfirmationDialog(),
            );
            if (!context.mounted) return;
            if (confirmed == true) {
              unawaited(
                context.read<EraseDbUserCubit>().confirmAndDelete(username),
              );
            } else {
              context.read<EraseDbUserCubit>().cancel();
            }
          case EraseDbUserSuccess():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.t.users.eraseDbUser.success)),
            );
            unawaited(context.router.replaceAll([const UsersRoute()]));
          case EraseDbUserFailure(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_failureMessage(failure, context))),
            );
          case EraseDbUserInitial() || EraseDbUserDeleting():
            break;
        }
      },
      child: BlocBuilder<EraseDbUserCubit, EraseDbUserState>(
        builder: (context, state) {
          final isDeleting = state is EraseDbUserDeleting;
          return IconButton(
            icon: isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error,
                  ),
            tooltip: context.t.users.eraseDbUser.tooltip,
            onPressed: isDeleting
                ? null
                : () => context.read<EraseDbUserCubit>().requestConfirmation(),
          );
        },
      ),
    );
  }

  String _failureMessage(Failure f, BuildContext context) {
    final t = context.t;
    return switch (f) {
      ForbiddenFailure() => t.users.eraseDbUser.errors.forbidden,
      UnauthorizedFailure() => t.users.eraseDbUser.errors.unauthorized,
      NotFoundFailure() => t.users.eraseDbUser.errors.notFound,
      _ => t.users.eraseDbUser.errors.generic,
    };
  }
}
