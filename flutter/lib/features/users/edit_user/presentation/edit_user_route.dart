import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/users/edit_user/application/edit_user_cubit.dart';
import 'package:flutter_application_1/features/users/edit_user/presentation/edit_user_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class EditUserPage extends StatelessWidget {
  const EditUserPage({
    @PathParam('username') required this.username,
    super.key,
  });

  final String username;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EditUserCubit>(),
      child: EditUserScreen(username: username),
    );
  }
}
