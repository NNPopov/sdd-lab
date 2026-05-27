import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_state.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/entities/tier_option.dart';
import 'package:flutter_application_1/features/users/update_user_tier/presentation/update_user_tier_button.dart';
import 'package:flutter_application_1/features/users/update_user_tier/presentation/widgets/update_user_tier_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUpdateUserTierCubit extends MockCubit<UpdateUserTierState>
    implements UpdateUserTierCubit {}

// The viewed user whose tier is updated — identity is the integer id.
const _userId = 7;
const _tiers = <TierOption>[TierOption(id: 3, name: 'Gold')];

void main() {
  late _MockUpdateUserTierCubit cubit;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
  });

  setUp(() {
    cubit = _MockUpdateUserTierCubit();
    when(() => cubit.loadTiers()).thenAnswer((_) async {});
    when(() => cubit.submit(any())).thenAnswer((_) async {});
  });

  Widget buildSubject({
    required UpdateUserTierState state,
    Stream<UpdateUserTierState>? stream,
  }) {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream).thenAnswer(
      (_) => stream ?? const Stream.empty(),
    );
    return TranslationProvider(
      child: MaterialApp(
        home: BlocProvider<UpdateUserTierCubit>.value(
          value: cubit,
          child: Scaffold(
            appBar: AppBar(
              actions: const [UpdateUserTierButton(userId: _userId)],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'tapping the button triggers loadTiers and opens the sheet',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const UpdateUserTierState.tiersLoaded(tiers: _tiers),
        ),
      );

      await tester.tap(find.byIcon(Icons.manage_accounts));
      await tester.pumpAndSettle();

      verify(() => cubit.loadTiers()).called(1);
      expect(find.byType(UpdateUserTierSheet), findsOneWidget);
    },
  );

  testWidgets(
    'confirming in the sheet calls submit with the integer userId',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const UpdateUserTierState.tiersLoaded(
            tiers: _tiers,
            selectedTierId: 3,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.manage_accounts));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      verify(() => cubit.submit(_userId)).called(1);
    },
  );

  testWidgets('the sheet closes when the cubit reaches success', (
    tester,
  ) async {
    final controller = StreamController<UpdateUserTierState>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(
      buildSubject(
        state: const UpdateUserTierState.tiersLoaded(
          tiers: _tiers,
          selectedTierId: 3,
        ),
        stream: controller.stream,
      ),
    );

    await tester.tap(find.byIcon(Icons.manage_accounts));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateUserTierSheet), findsOneWidget);

    controller.add(const UpdateUserTierState.success());
    await tester.pumpAndSettle();

    expect(find.byType(UpdateUserTierSheet), findsNothing);
  });
}
