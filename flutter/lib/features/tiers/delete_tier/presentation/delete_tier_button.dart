import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_state.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/presentation/widgets/delete_tier_confirmation_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteTierButton extends StatelessWidget {
  const DeleteTierButton({
    required this.tierId,
    required this.tierName,
    super.key,
  });

  final int tierId;
  final String tierName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DeleteTierCubit>(),
      child: _DeleteTierButtonInner(tierId: tierId, tierName: tierName),
    );
  }
}

class _DeleteTierButtonInner extends StatelessWidget {
  const _DeleteTierButtonInner({required this.tierId, required this.tierName});

  final int tierId;
  final String tierName;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeleteTierCubit, DeleteTierState>(
      listener: (context, state) async {
        switch (state) {
          case DeleteTierConfirming():
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => DeleteTierConfirmationDialog(tierName: tierName),
            );
            if (!context.mounted) return;
            if (confirmed == true) {
              unawaited(
                context.read<DeleteTierCubit>().confirmAndDelete(tierId),
              );
            } else {
              context.read<DeleteTierCubit>().cancel();
            }
          case DeleteTierSuccess():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.t.tiers.deleteTier.success)),
            );
            context.router.pop();
          case DeleteTierNotFound():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.t.tiers.deleteTier.errors.notFound),
              ),
            );
            context.router.pop();
          case DeleteTierFailure(:final failure):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_failureMessage(failure, context)),
              ),
            );
          case DeleteTierInitial() || DeleteTierDeleting():
            break;
        }
      },
      child: BlocBuilder<DeleteTierCubit, DeleteTierState>(
        builder: (context, state) {
          final isDeleting = state is DeleteTierDeleting;
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
            tooltip: context.t.tiers.deleteTier.tooltip,
            onPressed: isDeleting
                ? null
                : () => context.read<DeleteTierCubit>().requestConfirmation(),
          );
        },
      ),
    );
  }

  String _failureMessage(Failure f, BuildContext context) {
    final t = context.t;
    return switch (f) {
      ForbiddenFailure() => t.tiers.deleteTier.errors.forbidden,
      UnauthorizedFailure() => t.tiers.deleteTier.errors.unauthorized,
      _ => t.tiers.deleteTier.errors.generic,
    };
  }
}
