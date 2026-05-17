import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/posts/create_post/application/create_post_cubit.dart';
import 'package:flutter_application_1/features/posts/create_post/presentation/create_post_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class CreatePostPage extends StatelessWidget {
  const CreatePostPage({
    @PathParam('username') required this.username,
    super.key,
  });

  final String username;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreatePostCubit>(),
      child: CreatePostScreen(username: username),
    );
  }
}
