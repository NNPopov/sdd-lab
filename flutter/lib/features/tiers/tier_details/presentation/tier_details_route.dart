import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_cubit.dart';
import 'package:flutter_application_1/features/tiers/tier_details/presentation/tier_details_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class TierDetailsPage extends StatelessWidget {
  const TierDetailsPage({
    @PathParam('name') required this.tierName,
    super.key,
  });

  final String tierName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TierDetailsCubit>(),
      child: TierDetailsScreen(tierName: tierName),
    );
  }
}
