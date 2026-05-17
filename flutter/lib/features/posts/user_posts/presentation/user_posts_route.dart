import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/user_posts/presentation/user_posts_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class UserPostsPage extends StatelessWidget {
  const UserPostsPage({
    @PathParam('username') required this.username,
    super.key,
  });

  final String username;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UserPostsCubit>(),
      child: UserPostsScreen(username: username),
    );
  }
}
