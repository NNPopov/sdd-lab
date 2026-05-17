import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/tiers/create_tier/application/create_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/create_tier/presentation/create_tier_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class CreateTierPage extends StatelessWidget {
  const CreateTierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreateTierCubit>(),
      child: const CreateTierScreen(),
    );
  }
}
