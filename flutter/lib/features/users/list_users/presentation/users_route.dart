import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_cubit.dart';
import 'package:flutter_application_1/features/users/list_users/presentation/users_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<UsersListCubit>();
        unawaited(cubit.fetchUsers());
        return cubit;
      },
      child: const UsersScreen(),
    );
  }
}
