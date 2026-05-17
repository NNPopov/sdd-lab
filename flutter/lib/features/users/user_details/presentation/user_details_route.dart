import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/user_details/application/user_details_cubit.dart';
import 'package:flutter_application_1/features/users/user_details/presentation/user_details_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class UserDetailsPage extends StatelessWidget {
  const UserDetailsPage({
    @PathParam('username') required this.username,
    super.key,
  });

  final String username;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<UserDetailsCubit>()),
        BlocProvider(create: (_) => getIt<GetUserTierCubit>()),
        BlocProvider(create: (_) => getIt<UpdateUserTierCubit>()),
      ],
      child: UserDetailsScreen(username: username),
    );
  }
}
