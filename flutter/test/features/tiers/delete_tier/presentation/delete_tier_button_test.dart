import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_state.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/presentation/delete_tier_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeleteTierCubit extends MockCubit<DeleteTierState>
    implements DeleteTierCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

void main() {
  late _MockDeleteTierCubit mockCubit;
  late _MockStackRouter mockRouter;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
  });

  setUp(() {
    mockCubit = _MockDeleteTierCubit();
    mockRouter = _MockStackRouter();
    when(() => mockRouter.pop()).thenAnswer((_) async => true);
    getIt.registerFactory<DeleteTierCubit>(() => mockCubit);
  });

  tearDown(() async {
    await getIt.unregister<DeleteTierCubit>();
  });

  Widget buildSubject({
    required DeleteTierState state,
    Stream<DeleteTierState>? stream,
  }) {
    when(() => mockCubit.state).thenReturn(state);
    when(() => mockCubit.stream).thenAnswer(
      (_) => stream ?? const Stream.empty(),
    );
    return TranslationProvider(
      child: StackRouterScope(
        stateHash: 0,
        controller: mockRouter,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: const [DeleteTierButton(tierId: 1, tierName: 'gold')],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5c — Delete-navigation regression
  // ---------------------------------------------------------------------------

  testWidgets(
    'on success calls pop() on the TiersTab router (not the root router)',
    (tester) async {
      final controller = StreamController<DeleteTierState>.broadcast();

      await tester.pumpWidget(
        buildSubject(
          state: const DeleteTierState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(const DeleteTierState.success());
      await tester.pumpAndSettle();

      verify(() => mockRouter.pop()).called(1);

      await controller.close();
    },
  );

  testWidgets(
    'on notFound calls pop() on the TiersTab router',
    (tester) async {
      final controller = StreamController<DeleteTierState>.broadcast();

      await tester.pumpWidget(
        buildSubject(
          state: const DeleteTierState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(const DeleteTierState.notFound());
      await tester.pumpAndSettle();

      verify(() => mockRouter.pop()).called(1);

      await controller.close();
    },
  );
}
