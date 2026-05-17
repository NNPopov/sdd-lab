import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/presentation/edit_tier_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class EditTierPage extends StatelessWidget {
  const EditTierPage({
    @PathParam('name') required this.tierName,
    super.key,
  });

  final String tierName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EditTierCubit>(),
      child: EditTierScreen(tierName: tierName),
    );
  }
}
