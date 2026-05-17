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
    required this.username,
    required this.isModerator,
    super.key,
  });

  final String username;
  final bool isModerator;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AssignModeratorCubit>(),
      child: _AssignModeratorButtonInner(
        username: username,
        isModerator: isModerator,
      ),
    );
  }
}

class _AssignModeratorButtonInner extends StatefulWidget {
  const _AssignModeratorButtonInner({
    required this.username,
    required this.isModerator,
  });

  final String username;
  final bool isModerator;

  @override
  State<_AssignModeratorButtonInner> createState() =>
      _AssignModeratorButtonInnerState();
}

class _AssignModeratorButtonInnerState
    extends State<_AssignModeratorButtonInner> {
  late bool _isModerator;

  @override
  void initState() {
    super.initState();
    _isModerator = widget.isModerator;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocListener<AssignModeratorCubit, AssignModeratorState>(
      listener: (context, state) {
        if (state is AssignModeratorSuccess) {
          setState(() => _isModerator = state.isModerator);
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
          final label = _isModerator
              ? t.users.moderator.revoke
              : t.users.moderator.assign;
          return TextButton(
            onPressed: () {
              final cubit = context.read<AssignModeratorCubit>();
              if (_isModerator) {
                unawaited(cubit.revoke(widget.username));
              } else {
                unawaited(cubit.assign(widget.username));
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
