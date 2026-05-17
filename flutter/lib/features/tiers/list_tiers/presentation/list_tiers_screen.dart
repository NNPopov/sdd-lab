import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/tiers/_shared/domain/entities/tier.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/application/list_tiers_cubit.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/application/list_tiers_state.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/presentation/widgets/load_more_error.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/presentation/widgets/load_more_indicator.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/presentation/widgets/tier_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListTiersScreen extends StatefulWidget {
  const ListTiersScreen({super.key});

  @override
  State<ListTiersScreen> createState() => _ListTiersScreenState();
}

class _ListTiersScreenState extends State<ListTiersScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      unawaited(context.read<ListTiersCubit>().loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final canManageTiers = context.read<PermissionCubit>().has(
      Permission.manageTiers,
    );
    return Scaffold(
      floatingActionButton: canManageTiers
          ? FloatingActionButton(
              tooltip: t.tiers.createTier.fabTooltip,
              onPressed: () async {
                final tier = await context.router.push<Tier>(
                  const CreateTierRoute(),
                );
                if (tier != null && context.mounted) {
                  unawaited(context.read<ListTiersCubit>().refresh());
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: BlocBuilder<ListTiersCubit, ListTiersState>(
        builder: (context, state) => switch (state) {
          ListTiersInitial() => const SizedBox.shrink(),
          ListTiersLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ListTiersLoaded(:final tiers, :final loadMoreStatus) =>
            tiers.isEmpty
                ? Center(child: Text(t.tiers.listTiers.empty))
                : RefreshIndicator(
                    onRefresh: () => context.read<ListTiersCubit>().refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: tiers.length + _trailingCount(loadMoreStatus),
                      itemBuilder: (context, index) {
                        if (index < tiers.length) {
                          return TierTile(
                            tier: tiers[index],
                            onTap: () async {
                              await context.router.push(
                                TierDetailsRoute(tierName: tiers[index].name),
                              );
                              if (context.mounted) {
                                unawaited(
                                  context.read<ListTiersCubit>().refresh(),
                                );
                              }
                            },
                          );
                        }
                        return switch (loadMoreStatus) {
                          LoadMoreStatus.loading =>
                            const TiersLoadMoreIndicator(),
                          LoadMoreStatus.error => TiersLoadMoreError(
                            onRetry: () => unawaited(
                              context.read<ListTiersCubit>().retryLoadMore(),
                            ),
                          ),
                          LoadMoreStatus.idle => const SizedBox.shrink(),
                        };
                      },
                    ),
                  ),
          ListTiersError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.tiers.listTiers.loadError),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () =>
                      unawaited(context.read<ListTiersCubit>().load()),
                  child: Text(t.common.retry),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }

  int _trailingCount(LoadMoreStatus status) {
    return switch (status) {
      LoadMoreStatus.loading || LoadMoreStatus.error => 1,
      LoadMoreStatus.idle => 0,
    };
  }
}
