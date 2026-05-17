import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_cubit.dart';
import 'package:flutter_application_1/features/posts/edit_post/presentation/edit_post_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class EditPostPage extends StatelessWidget {
  const EditPostPage({
    required this.post,
    required this.username,
    super.key,
  });

  final Post post;
  final String username;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<EditPostCubit>()),
        BlocProvider(create: (_) => getIt<ModerationLogCubit>()),
      ],
      child: EditPostScreen(post: post, username: username),
    );
  }
}
