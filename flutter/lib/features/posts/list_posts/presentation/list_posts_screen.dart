import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_state.dart';
import 'package:flutter_application_1/features/posts/list_posts/presentation/widgets/list_post_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListPostsScreen extends StatefulWidget {
  const ListPostsScreen({super.key});

  @override
  State<ListPostsScreen> createState() => _ListPostsScreenState();
}

class _ListPostsScreenState extends State<ListPostsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(context.read<ListPostsCubit>().load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(context.read<ListPostsCubit>().loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.nav.posts)),
      floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) return const SizedBox.shrink();
          return FloatingActionButton(
            tooltip: t.posts.listPosts.fabTooltip,
            onPressed: () => context.router.push(
              CreatePostRoute(userId: authState.currentUser!.id),
            ),
            child: const Icon(Icons.add),
          );
        },
      ),
      body: BlocBuilder<ListPostsCubit, ListPostsState>(
        builder: (context, state) => switch (state) {
          ListPostsInitial() => const SizedBox.shrink(),
          ListPostsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ListPostsLoaded(:final posts, :final loadMoreStatus) =>
            posts.isEmpty
                ? Center(child: Text(t.posts.listPosts.empty))
                : RefreshIndicator(
                    onRefresh: () => context.read<ListPostsCubit>().refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: posts.length + _trailingCount(loadMoreStatus),
                      itemBuilder: (context, index) {
                        if (index < posts.length) {
                          return ListPostTile(
                            post: posts[index],
                            onOpenTap: () => context.router.push(
                              PostDetailsRoute(
                                userId: posts[index].createdByUserId,
                                id: posts[index].id,
                              ),
                            ),
                          );
                        }
                        return switch (loadMoreStatus) {
                          LoadMoreStatus.loading => const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          LoadMoreStatus.error => Center(
                            child: TextButton(
                              onPressed: () => unawaited(
                                context.read<ListPostsCubit>().loadMore(),
                              ),
                              child: Text(t.common.retry),
                            ),
                          ),
                          LoadMoreStatus.idle => const SizedBox.shrink(),
                        };
                      },
                    ),
                  ),
          ListPostsError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.posts.listPosts.loadError),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () =>
                      unawaited(context.read<ListPostsCubit>().load()),
                  child: Text(t.common.retry),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }

  int _trailingCount(LoadMoreStatus status) => switch (status) {
    LoadMoreStatus.loading || LoadMoreStatus.error => 1,
    LoadMoreStatus.idle => 0,
  };
}
