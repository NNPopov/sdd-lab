import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/presentation/widgets/update_user_tier_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdateUserTierButton extends StatelessWidget {
  const UpdateUserTierButton({required this.username, super.key});

  final String username;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return IconButton(
      icon: const Icon(Icons.manage_accounts),
      tooltip: t.users.updateTier.tooltip,
      onPressed: () async {
        unawaited(context.read<UpdateUserTierCubit>().loadTiers());
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => BlocProvider.value(
            value: context.read<UpdateUserTierCubit>(),
            child: UpdateUserTierSheet(username: username),
          ),
        );
        if (context.mounted) {
          context.read<UpdateUserTierCubit>().reset();
        }
      },
    );
  }
}
