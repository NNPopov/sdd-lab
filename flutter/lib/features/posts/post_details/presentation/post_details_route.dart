import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_cubit.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_cubit.dart';
import 'package:flutter_application_1/features/posts/post_details/presentation/post_details_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class PostDetailsPage extends StatelessWidget {
  const PostDetailsPage({
    @PathParam('username') required this.username,
    @PathParam('id') required this.id,
    super.key,
  });

  final String username;
  final int id;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = getIt<PostDetailsCubit>();
            unawaited(cubit.load(username, id));
            return cubit;
          },
        ),
        BlocProvider(create: (_) => getIt<DeletePostCubit>()),
      ],
      child: PostDetailsScreen(username: username, id: id),
    );
  }
}
