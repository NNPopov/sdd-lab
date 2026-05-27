import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_state.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/entities/tier_option.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdateUserTierSheet extends StatelessWidget {
  const UpdateUserTierSheet({required this.userId, super.key});

  final int userId;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocListener<UpdateUserTierCubit, UpdateUserTierState>(
      listener: (context, state) {
        if (state is UpdateUserTierSuccess) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: BlocBuilder<UpdateUserTierCubit, UpdateUserTierState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.users.updateTier.sheetTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                switch (state) {
                  UpdateUserTierInitial() || UpdateUserTierLoadingTiers() =>
                    const Center(child: CircularProgressIndicator()),
                  UpdateUserTierError(:final failure) => _ErrorBody(
                    failure: failure,
                    onRetry: () => unawaited(
                      context.read<UpdateUserTierCubit>().loadTiers(),
                    ),
                  ),
                  UpdateUserTierTiersLoaded() ||
                  UpdateUserTierSubmitting() ||
                  UpdateUserTierSuccess() => _TiersBody(
                    userId: userId,
                    state: state,
                  ),
                },
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.failure, required this.onRetry});

  final Object failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.common.error),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: Text(t.common.retry)),
      ],
    );
  }
}

class _TiersBody extends StatelessWidget {
  const _TiersBody({required this.userId, required this.state});

  final int userId;
  final UpdateUserTierState state;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    final tiers = switch (state) {
      UpdateUserTierTiersLoaded(:final tiers) => tiers,
      UpdateUserTierSubmitting(:final tiers) => tiers,
      _ => <TierOption>[],
    };

    final selectedTierId = switch (state) {
      UpdateUserTierTiersLoaded(:final selectedTierId) => selectedTierId,
      UpdateUserTierSubmitting(:final selectedTierId) => selectedTierId,
      _ => null,
    };

    final isSubmitting = state is UpdateUserTierSubmitting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: selectedTierId,
          hint: Text(t.users.updateTier.selectTier),
          items: tiers
              .map(
                (tier) => DropdownMenuItem<int>(
                  value: tier.id,
                  child: Text(tier.name),
                ),
              )
              .toList(),
          onChanged: isSubmitting
              ? null
              : (value) {
                  if (value != null) {
                    context.read<UpdateUserTierCubit>().selectTier(value);
                  }
                },
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: (selectedTierId == null || isSubmitting)
              ? null
              : () => unawaited(
                  context.read<UpdateUserTierCubit>().submit(userId),
                ),
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.users.updateTier.confirm),
        ),
      ],
    );
  }
}
