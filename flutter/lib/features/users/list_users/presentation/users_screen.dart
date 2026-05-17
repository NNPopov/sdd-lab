import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_cubit.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_state.dart';
import 'package:flutter_application_1/features/users/list_users/presentation/widgets/load_more_error.dart';
import 'package:flutter_application_1/features/users/list_users/presentation/widgets/load_more_indicator.dart';
import 'package:flutter_application_1/features/users/list_users/presentation/widgets/user_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
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
      unawaited(context.read<UsersListCubit>().loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.router.push(const CreateUserRoute());
          if (context.mounted) {
            unawaited(context.read<UsersListCubit>().refresh());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<UsersListCubit, UsersListState>(
        builder: (context, state) => switch (state) {
          UsersListInitial() => const SizedBox.shrink(),
          UsersListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          UsersListLoaded(:final users, :final loadMoreStatus) =>
            RefreshIndicator(
              onRefresh: () => context.read<UsersListCubit>().refresh(),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: users.length + _trailingCount(loadMoreStatus),
                itemBuilder: (context, index) {
                  if (index < users.length) {
                    final u = users[index];
                    return UserTile(
                      user: u,
                      onDetailsTap: () async {
                        await context.router.push(
                          UserDetailsRoute(username: u.username),
                        );
                        if (context.mounted) {
                          unawaited(
                            context.read<UsersListCubit>().refresh(),
                          );
                        }
                      },
                      onPostsTap: () {
                        unawaited(
                          context.router.push(
                            UserPostsRoute(username: u.username),
                          ),
                        );
                      },
                    );
                  }
                  return switch (loadMoreStatus) {
                    LoadMoreStatus.loading => const LoadMoreIndicator(),
                    LoadMoreStatus.error => LoadMoreError(
                      onRetry: () => unawaited(
                        context.read<UsersListCubit>().retryLoadMore(),
                      ),
                    ),
                    LoadMoreStatus.idle => const SizedBox.shrink(),
                  };
                },
              ),
            ),
          UsersListError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.common.error),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => context.read<UsersListCubit>().fetchUsers(),
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
