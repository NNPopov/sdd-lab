import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/posts/delete_post/presentation/delete_post_button.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/presentation/erase_db_post_button.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_cubit.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_state.dart';
import 'package:flutter_application_1/features/posts/post_details/presentation/widgets/post_status_chip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({
    required this.username,
    required this.id,
    super.key,
  });

  final String username;
  final int id;

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.posts.postDetails.title),
        actions: [
          BlocBuilder<PostDetailsCubit, PostDetailsState>(
            builder: (context, postState) {
              if (postState is! PostDetailsLoaded) {
                return const SizedBox.shrink();
              }
              return BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  final currentUser = authState is AuthAuthenticated
                      ? authState.currentUser
                      : null;
                  final isAuthor = currentUser?.username == widget.username;
                  final isSuperuser = currentUser?.isSuperuser ?? false;
                  final showErase = isSuperuser && !isAuthor;

                  if (!isAuthor && !showErase) {
                    return const SizedBox.shrink();
                  }
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAuthor) ...[
                        DeletePostButton(
                          username: widget.username,
                          id: widget.id,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: t.posts.editPost.title,
                          onPressed: () async {
                            final cubit = context.read<PostDetailsCubit>();
                            await context.router.push(
                              EditPostRoute(
                                post: postState.post,
                                username: widget.username,
                              ),
                            );
                            if (!mounted) return;
                            unawaited(
                              cubit.load(widget.username, widget.id),
                            );
                          },
                        ),
                      ],
                      if (showErase)
                        EraseDbPostButton(
                          username: widget.username,
                          id: widget.id,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<PostDetailsCubit, PostDetailsState>(
        builder: (context, state) => switch (state) {
          PostDetailsInitial() || PostDetailsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PostDetailsError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.posts.postDetails.loadError),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => unawaited(
                    context.read<PostDetailsCubit>().load(
                      widget.username,
                      widget.id,
                    ),
                  ),
                  child: Text(t.common.retry),
                ),
              ],
            ),
          ),
          PostDetailsLoaded(:final post) => BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final currentUser = authState is AuthAuthenticated
                  ? authState.currentUser
                  : null;
              final isAuthor =
                  post.username != null &&
                  currentUser?.username == post.username;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (isAuthor) ...[
                      const SizedBox(height: 8),
                      PostStatusChip(status: post.status),
                    ],
                    if (post.mediaUrl != null) ...[
                      const SizedBox(height: 12),
                      Image.network(
                        post.mediaUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 48),
                      ),
                    ],
                    const SizedBox(height: 12),
                    MarkdownBody(data: post.text),
                    const SizedBox(height: 12),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(post.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        },
      ),
    );
  }
}
