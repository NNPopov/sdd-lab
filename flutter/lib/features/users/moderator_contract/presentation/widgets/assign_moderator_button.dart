import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/moderator_contract/application/assign_moderator_cubit.dart';
import 'package:flutter_application_1/features/users/moderator_contract/application/assign_moderator_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AssignModeratorButton extends StatelessWidget {
  const AssignModeratorButton({
    required this.userId,
    required this.isModerator,
    required this.onToggled,
    super.key,
  });

  final int userId;
  final bool isModerator;
  final void Function(bool isModerator) onToggled;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AssignModeratorCubit>(),
      child: _AssignModeratorButtonInner(
        userId: userId,
        isModerator: isModerator,
        onToggled: onToggled,
      ),
    );
  }
}

class _AssignModeratorButtonInner extends StatelessWidget {
  const _AssignModeratorButtonInner({
    required this.userId,
    required this.isModerator,
    required this.onToggled,
  });

  final int userId;
  final bool isModerator;
  final void Function(bool isModerator) onToggled;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocListener<AssignModeratorCubit, AssignModeratorState>(
      listener: (context, state) {
        if (state is AssignModeratorSuccess) {
          onToggled(state.isModerator);
        }
        if (state is AssignModeratorError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage(state.failure, t))),
          );
        }
      },
      child: BlocBuilder<AssignModeratorCubit, AssignModeratorState>(
        builder: (context, state) {
          if (state is AssignModeratorLoading) {
            return const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final label = isModerator
              ? t.users.moderator.revoke
              : t.users.moderator.assign;
          return TextButton(
            onPressed: () {
              final cubit = context.read<AssignModeratorCubit>();
              if (isModerator) {
                unawaited(cubit.revoke(userId));
              } else {
                unawaited(cubit.assign(userId));
              }
            },
            child: Text(label),
          );
        },
      ),
    );
  }

  String _errorMessage(Failure failure, Translations t) {
    return switch (failure) {
      ConflictFailure() => t.users.moderator.errors.conflict,
      ForbiddenFailure() => t.users.moderator.errors.forbidden,
      _ => t.users.moderator.errors.generic,
    };
  }
}
