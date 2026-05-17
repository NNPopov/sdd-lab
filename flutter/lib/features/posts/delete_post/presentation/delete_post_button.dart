import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_cubit.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_state.dart';
import 'package:flutter_application_1/features/posts/delete_post/presentation/widgets/delete_post_confirmation_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeletePostButton extends StatelessWidget {
  const DeletePostButton({
    required this.username,
    required this.id,
    super.key,
  });

  final String username;
  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DeletePostCubit>(),
      child: _DeletePostButtonInner(username: username, id: id),
    );
  }
}

class _DeletePostButtonInner extends StatelessWidget {
  const _DeletePostButtonInner({required this.username, required this.id});

  final String username;
  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeletePostCubit, DeletePostState>(
      listener: (context, state) async {
        switch (state) {
          case DeletePostConfirming():
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => const DeletePostConfirmationDialog(),
            );
            if (!context.mounted) return;
            if (confirmed == true) {
              unawaited(
                context.read<DeletePostCubit>().confirmAndDelete(username, id),
              );
            } else {
              context.read<DeletePostCubit>().cancel();
            }
          case DeletePostSuccess():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.t.posts.deletePost.success)),
            );
            context.router.pop();
          case DeletePostFailure(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_failureMessage(failure, context.t)),
              ),
            );
          case DeletePostInitial() || DeletePostDeleting():
            break;
        }
      },
      child: BlocBuilder<DeletePostCubit, DeletePostState>(
        builder: (context, state) {
          final isDeleting = state is DeletePostDeleting;
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
            tooltip: context.t.posts.deletePost.tooltip,
            onPressed: isDeleting
                ? null
                : () => context.read<DeletePostCubit>().requestConfirmation(),
          );
        },
      ),
    );
  }

  String _failureMessage(Failure f, Translations t) => switch (f) {
    ForbiddenFailure() => t.posts.deletePost.errors.forbidden,
    _ => t.posts.deletePost.errors.generic,
  };
}
