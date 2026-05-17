import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/theme/app_breakpoints.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_cubit.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_state.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_state.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/widgets/moderation_panel.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/widgets/post_content_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModeratePostScreen extends StatefulWidget {
  const ModeratePostScreen({
    required this.postUuid,
    required this.post,
    super.key,
  });

  final String postUuid;
  final PendingPostItem post;

  @override
  State<ModeratePostScreen> createState() => _ModeratePostScreenState();
}

class _ModeratePostScreenState extends State<ModeratePostScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final width = MediaQuery.of(context).size.width;
      if (width >= AppBreakpoints.medium) {
        unawaited(context.read<ModerationLogCubit>().load(widget.postUuid));
      }
    });
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      final logState = context.read<ModerationLogCubit>().state;
      if (logState is ModerationLogInitial) {
        unawaited(
          context.read<ModerationLogCubit>().load(widget.postUuid),
        );
      }
    }
  }

  String _errorMessage(Failure failure, Translations t) {
    return switch (failure) {
      ForbiddenFailure() => t.posts.moderatePost.errors.forbidden,
      NotFoundFailure() => t.posts.moderatePost.errors.notFound,
      ConflictFailure() => t.posts.moderatePost.errors.conflict,
      _ => t.posts.moderatePost.errors.generic,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocListener<ModeratePostCubit, ModeratePostState>(
      listener: (context, state) {
        if (state is ModeratePostSuccess) {
          context.router.pop();
        } else if (state is ModeratePostError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage(state.failure, t))),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(t.posts.moderatePost.title)),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= AppBreakpoints.medium) {
              return Row(
                children: [
                  Expanded(child: PostContentView(post: widget.post)),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: ModerationPanel(postUuid: widget.postUuid),
                  ),
                ],
              );
            }
            return Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: t.posts.moderatePost.tabs.post),
                    Tab(text: t.posts.moderatePost.tabs.moderation),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      PostContentView(post: widget.post),
                      ModerationPanel(postUuid: widget.postUuid),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
