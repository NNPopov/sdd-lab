import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/application/list_tiers_cubit.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/presentation/list_tiers_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class ListTiersPage extends StatelessWidget {
  const ListTiersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<ListTiersCubit>();
        unawaited(cubit.load());
        return cubit;
      },
      child: const ListTiersScreen(),
    );
  }
}
