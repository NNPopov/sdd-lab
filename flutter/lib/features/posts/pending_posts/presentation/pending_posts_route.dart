import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/pending_posts/presentation/pending_posts_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class PendingPostsPage extends StatelessWidget {
  const PendingPostsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<PendingPostsCubit>(),
    child: const PendingPostsScreen(),
  );
}
