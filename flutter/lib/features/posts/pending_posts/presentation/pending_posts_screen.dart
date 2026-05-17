import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_state.dart';
import 'package:flutter_application_1/features/posts/pending_posts/presentation/widgets/pending_post_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PendingPostsScreen extends StatefulWidget {
  const PendingPostsScreen({super.key});

  @override
  State<PendingPostsScreen> createState() => _PendingPostsScreenState();
}

class _PendingPostsScreenState extends State<PendingPostsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(context.read<PendingPostsCubit>().load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(context.read<PendingPostsCubit>().loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.posts.pendingPosts.title)),
      body: BlocBuilder<PendingPostsCubit, PendingPostsState>(
        builder: (context, state) => switch (state) {
          PendingPostsInitial() => const SizedBox.shrink(),
          PendingPostsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PendingPostsLoaded(:final items, :final loadMoreStatus) =>
            items.isEmpty
                ? Center(child: Text(t.posts.pendingPosts.empty))
                : RefreshIndicator(
                    onRefresh: () =>
                        context.read<PendingPostsCubit>().refresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: items.length + _trailingCount(loadMoreStatus),
                      itemBuilder: (context, index) {
                        if (index < items.length) {
                          return PendingPostTile(
                            item: items[index],
                            onTap: () => context.router.push(
                              ModeratePostRoute(
                                postUuid: items[index].postUuid,
                                post: items[index],
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
                                context.read<PendingPostsCubit>().loadMore(),
                              ),
                              child: Text(t.common.retry),
                            ),
                          ),
                          LoadMoreStatus.idle => const SizedBox.shrink(),
                        };
                      },
                    ),
                  ),
          PendingPostsError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.posts.pendingPosts.loadError),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () =>
                      unawaited(context.read<PendingPostsCubit>().load()),
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
