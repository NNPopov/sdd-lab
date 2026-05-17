import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/edit_user/application/edit_user_cubit.dart';
import 'package:flutter_application_1/features/users/edit_user/application/edit_user_state.dart';
import 'package:flutter_application_1/features/users/edit_user/presentation/widgets/edit_user_form.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({required this.username, super.key});

  final String username;

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<EditUserCubit>().loadInitial(widget.username));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocConsumer<EditUserCubit, EditUserState>(
      listener: (context, state) {
        switch (state) {
          case EditUserSuccess(:final user):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.users.edit.success)),
            );
            unawaited(context.router.maybePop<User>(user));
          case EditUserSubmitError(:final failure):
            switch (failure) {
              case ValidationFailure() || ConflictFailure():
                // Shown inline via serverErrors — no snackbar needed.
                break;
              case UnauthorizedFailure():
                // Interceptor handles logout; SessionExpiredListener
                // shows the global snackbar — don't double-show here.
                break;
              case ForbiddenFailure():
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.users.edit.errors.forbidden)),
                );
              case NotFoundFailure():
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.users.edit.errors.notFound)),
                );
              default:
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.users.edit.errors.generic)),
                );
            }
          default:
            break;
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(t.users.edit.title)),
          body: switch (state) {
            EditUserInitial() || EditUserLoadingInitialData() => const Center(
              child: CircularProgressIndicator(),
            ),
            EditUserLoadError(:final failure) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadErrorMessage(failure, t)),
                  const SizedBox(height: 8),
                  if (failure is ForbiddenFailure)
                    FilledButton(
                      onPressed: () => unawaited(context.router.maybePop()),
                      child: Text(t.common.back),
                    )
                  else
                    FilledButton(
                      onPressed: () => unawaited(
                        context.read<EditUserCubit>().loadInitial(
                          widget.username,
                        ),
                      ),
                      child: Text(t.common.retry),
                    ),
                ],
              ),
            ),
            EditUserLoaded(:final original) => EditUserForm(
              original: original,
              submitting: false,
              serverErrors: const {},
              onSubmit: (u) =>
                  unawaited(context.read<EditUserCubit>().submit(u)),
            ),
            EditUserSubmitting(:final original) => EditUserForm(
              original: original,
              submitting: true,
              serverErrors: const {},
              onSubmit: (_) {},
            ),
            EditUserSubmitError(:final original, :final failure) =>
              EditUserForm(
                original: original,
                submitting: false,
                serverErrors: _extractServerErrors(failure),
                onSubmit: (u) =>
                    unawaited(context.read<EditUserCubit>().submit(u)),
              ),
            EditUserSuccess() => const Center(
              child: CircularProgressIndicator(),
            ),
          },
        );
      },
    );
  }

  Map<String, String> _extractServerErrors(Failure failure) =>
      switch (failure) {
        ValidationFailure(:final fieldErrors) => fieldErrors,
        ConflictFailure(:final message) => {'username': message},
        _ => const {},
      };

  String _loadErrorMessage(Failure failure, Translations t) {
    if (failure is ForbiddenFailure) return t.users.edit.errors.forbidden;
    if (failure is NotFoundFailure) return t.users.edit.errors.notFound;
    return t.users.edit.errors.generic;
  }
}
