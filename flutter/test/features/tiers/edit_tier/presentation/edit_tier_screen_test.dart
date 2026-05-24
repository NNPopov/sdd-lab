import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_cubit.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_state.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/entities/edit_tier_data.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/presentation/edit_tier_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEditTierCubit extends MockCubit<EditTierState>
    implements EditTierCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

const _superuser = CurrentUser(
  username: 'admin',
  email: 'admin@test.com',
  name: 'Admin',
  isSuperuser: true,
  isModerator: false,
);

void main() {
  late _MockEditTierCubit cubit;
  late _MockAuthCubit authCubit;
  late _MockStackRouter router;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
    registerFallbackValue(const EditTierData(tierId: 1, name: ''));
  });

  setUp(() {
    cubit = _MockEditTierCubit();
    authCubit = _MockAuthCubit();
    router = _MockStackRouter();

    when(() => authCubit.state).thenReturn(
      const AuthState.authenticated(currentUser: _superuser),
    );
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => router.maybePop<String>(any())).thenAnswer((_) async => true);
  });

  Widget buildSubject(
    EditTierState state, {
    Stream<EditTierState>? stream,
  }) {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream).thenAnswer(
      (_) => stream ?? const Stream.empty(),
    );
    return TranslationProvider(
      child: StackRouterScope(
        stateHash: 0,
        controller: router,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<EditTierCubit>.value(value: cubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: const MaterialApp(
            home: EditTierScreen(tierId: 1, tierName: 'free'),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'pre-filled form: text field shows current tier name',
    (tester) async {
      await tester.pumpWidget(buildSubject(const EditTierState.initial()));

      expect(find.widgetWithText(TextFormField, 'free'), findsOneWidget);
    },
  );

  testWidgets(
    'submit triggers cubit.submit with tierId and trimmed name',
    (tester) async {
      when(
        () => cubit.submit(
          data: any(named: 'data'),
          isSuperuser: any(named: 'isSuperuser'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildSubject(const EditTierState.initial()));

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      final captured = verify(
        () => cubit.submit(
          data: captureAny(named: 'data'),
          isSuperuser: true,
        ),
      ).captured;
      final editData = captured.first as EditTierData;
      expect(editData.tierId, 1);
      expect(editData.name, 'free');
    },
  );

  testWidgets(
    'success state: shows success snackbar',
    (tester) async {
      final controller = StreamController<EditTierState>.broadcast();
      addTearDown(controller.close);

      await tester.pumpWidget(
        buildSubject(
          const EditTierState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(const EditTierState.success(newName: 'updated'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Tier updated'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'failure(NotFoundFailure) state: shows notFound snackbar',
    (tester) async {
      final controller = StreamController<EditTierState>.broadcast();
      addTearDown(controller.close);

      await tester.pumpWidget(
        buildSubject(
          const EditTierState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(const EditTierState.failure(Failure.notFound()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Tier not found'),
        ),
        findsOneWidget,
      );
    },
  );
}
