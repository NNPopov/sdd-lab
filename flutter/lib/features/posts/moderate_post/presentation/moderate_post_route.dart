import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/moderate_post_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class ModeratePostPage extends StatelessWidget {
  const ModeratePostPage({
    @PathParam('post_uuid') required this.postUuid,
    required this.post,
    super.key,
  });

  final String postUuid;
  final PendingPostItem post;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ModeratePostCubit>()),
        BlocProvider(create: (_) => getIt<ModerationLogCubit>()),
      ],
      child: ModeratePostScreen(postUuid: postUuid, post: post),
    );
  }
}
