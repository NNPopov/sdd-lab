import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/presentation/delete_tier_button.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_cubit.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_state.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/entities/tier_detail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TierDetailsScreen extends StatefulWidget {
  const TierDetailsScreen({
    required this.tierId,
    required this.tierName,
    super.key,
  });

  final int tierId;
  final String tierName;

  @override
  State<TierDetailsScreen> createState() => _TierDetailsScreenState();
}

class _TierDetailsScreenState extends State<TierDetailsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<TierDetailsCubit>().load(widget.tierId));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<TierDetailsCubit, TierDetailsState>(
          builder: (context, state) => switch (state) {
            TierDetailsLoaded(:final tier) => Text(tier.name),
            _ => Text(widget.tierName),
          },
        ),
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final isSuperuser = switch (authState) {
                AuthAuthenticated(:final currentUser) =>
                  currentUser?.isSuperuser ?? false,
                _ => false,
              };
              if (!isSuperuser) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DeleteTierButton(
                    tierId: widget.tierId,
                    tierName: widget.tierName,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final newName = await context.router.push<String>(
                        EditTierRoute(
                          tierId: widget.tierId,
                          tierName: widget.tierName,
                        ),
                      );
                      if (!context.mounted || newName == null) return;
                      unawaited(
                        context.router.replace(
                          TierDetailsRoute(
                            tierId: widget.tierId,
                            tierName: newName,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TierDetailsCubit, TierDetailsState>(
        builder: (context, state) => switch (state) {
          TierDetailsInitial() || TierDetailsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          TierDetailsLoaded(:final tier) => _TierDetailsCard(tier: tier),
          TierDetailsError(:final failure) => switch (failure) {
            NotFoundFailure() => Center(
              child: Text(t.tiers.tierDetails.notFound),
            ),
            PermissionDenied() => Center(
              child: Text(t.tiers.tierDetails.permissionDenied),
            ),
            _ => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.tiers.tierDetails.loadError),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () =>
                        context.read<TierDetailsCubit>().retry(widget.tierId),
                    child: Text(t.common.retry),
                  ),
                ],
              ),
            ),
          },
        },
      ),
    );
  }
}

class _TierDetailsCard extends StatelessWidget {
  const _TierDetailsCard({required this.tier});

  final TierDetail tier;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final createdAt = tier.createdAt.toLocal().toString().split('.').first;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tier.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('${t.tiers.tierDetails.id}: ${tier.id}'),
              const SizedBox(height: 4),
              Text('${t.tiers.tierDetails.createdAt}: $createdAt'),
            ],
          ),
        ),
      ),
    );
  }
}
