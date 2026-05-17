import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_state.dart';
import 'package:flutter_application_1/features/posts/user_posts/presentation/widgets/post_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserPostsScreen extends StatefulWidget {
  const UserPostsScreen({required this.username, super.key});

  final String username;

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(
      context.read<UserPostsCubit>().load(widget.username),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      unawaited(
        context.read<UserPostsCubit>().loadMore(widget.username),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.posts.userPosts.title(username: widget.username),
        ),
      ),
      floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isOwner =
              authState is AuthAuthenticated &&
              authState.currentUser?.username == widget.username;
          if (!isOwner) return const SizedBox.shrink();
          return FloatingActionButton(
            tooltip: t.posts.createPost.fabTooltip,
            onPressed: () async {
              final cubit = context.read<UserPostsCubit>();
              await context.router.push(
                CreatePostRoute(username: widget.username),
              );
              if (!mounted) return;
              unawaited(cubit.refresh(widget.username));
            },
            child: const Icon(Icons.add),
          );
        },
      ),
      body: BlocBuilder<UserPostsCubit, UserPostsState>(
        builder: (context, state) => switch (state) {
          UserPostsInitial() => const SizedBox.shrink(),
          UserPostsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          UserPostsLoaded(:final posts, :final loadMoreStatus) =>
            posts.isEmpty
                ? Center(child: Text(t.posts.userPosts.empty))
                : RefreshIndicator(
                    onRefresh: () =>
                        context.read<UserPostsCubit>().refresh(widget.username),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: posts.length + _trailingCount(loadMoreStatus),
                      itemBuilder: (context, index) {
                        if (index < posts.length) {
                          return PostTile(
                            post: posts[index],
                            onOpenTap: () => context.router.push(
                              PostDetailsRoute(
                                username: widget.username,
                                id: posts[index].id,
                              ),
                            ),
                          );
                        }
                        return switch (loadMoreStatus) {
                          LoadMoreStatus.loading => const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          LoadMoreStatus.error => Center(
                            child: TextButton(
                              onPressed: () => unawaited(
                                context.read<UserPostsCubit>().loadMore(
                                  widget.username,
                                ),
                              ),
                              child: Text(t.common.retry),
                            ),
                          ),
                          LoadMoreStatus.idle => const SizedBox.shrink(),
                        };
                      },
                    ),
                  ),
          UserPostsError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.posts.userPosts.loadError),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => unawaited(
                    context.read<UserPostsCubit>().load(widget.username),
                  ),
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
