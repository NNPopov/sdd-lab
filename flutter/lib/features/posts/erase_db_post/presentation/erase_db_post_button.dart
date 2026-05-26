import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_cubit.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_state.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/presentation/widgets/erase_db_post_confirmation_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EraseDbPostButton extends StatelessWidget {
  const EraseDbPostButton({
    required this.userId,
    required this.id,
    super.key,
  });

  final int userId;
  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EraseDbPostCubit>(),
      child: _EraseDbPostButtonInner(userId: userId, id: id),
    );
  }
}

class _EraseDbPostButtonInner extends StatelessWidget {
  const _EraseDbPostButtonInner({required this.userId, required this.id});

  final int userId;
  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocListener<EraseDbPostCubit, EraseDbPostState>(
      listener: (context, state) async {
        switch (state) {
          case EraseDbPostConfirming():
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => const EraseDbPostConfirmationDialog(),
            );
            if (!context.mounted) return;
            if (confirmed == true) {
              unawaited(
                context.read<EraseDbPostCubit>().confirmAndErase(userId, id),
              );
            } else {
              context.read<EraseDbPostCubit>().cancel();
            }
          case EraseDbPostSuccess():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.t.posts.eraseDbPost.success),
              ),
            );
            context.router.pop();
          case EraseDbPostFailure(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_failureMessage(failure, context.t)),
              ),
            );
          case EraseDbPostInitial() || EraseDbPostDeleting():
            break;
        }
      },
      child: BlocBuilder<EraseDbPostCubit, EraseDbPostState>(
        builder: (context, state) {
          final isDeleting = state is EraseDbPostDeleting;
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
            tooltip: context.t.posts.eraseDbPost.tooltip,
            onPressed: isDeleting
                ? null
                : () => context.read<EraseDbPostCubit>().requestConfirmation(),
          );
        },
      ),
    );
  }

  String _failureMessage(Failure f, Translations t) => switch (f) {
    ForbiddenFailure() => t.posts.eraseDbPost.errors.forbidden,
    _ => t.posts.eraseDbPost.errors.generic,
  };
}
