// Outside-in test for slice 0044 — CreateUserScreen Widget Decomposition.
//
// Boundary: CreateUserScreen (public widget) driven by a mock CreateUserCubit.
// Wired real: create_user_screen.dart (including _CreateUserForm and _SubmitSection
// after the refactor).
// Mocked: CreateUserCubit — state stream is driven externally.
//
// These scenarios serve as the regression guard that confirms the widget
// decomposition (extracting _CreateUserForm and _SubmitSection) does not
// change any externally-observable behaviour.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_cubit.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_state.dart';
import 'package:flutter_application_1/features/users/create_user/domain/entities/new_user_data.dart';
import 'package:flutter_application_1/features/users/create_user/presentation/create_user_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateUserCubit extends MockCubit<CreateUserState>
    implements CreateUserCubit {}

Widget _wrap({required CreateUserCubit cubit}) => TranslationProvider(
  child: MaterialApp(
    home: BlocProvider<CreateUserCubit>.value(
      value: cubit,
      child: const CreateUserScreen(),
    ),
  ),
);

void main() {
  late _MockCreateUserCubit cubit;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
    registerFallbackValue(
      const NewUserData(name: '', username: '', email: '', password: ''),
    );
  });

  setUp(() {
    cubit = _MockCreateUserCubit();
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.state).thenReturn(const CreateUserState.idle());
    when(() => cubit.submit(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await cubit.close();
  });

  // Scenario 1 (tests.md §Scenario 1):
  // All fields valid — validators pass and cubit.submit is called with the
  // entered data.
  testWidgets(
    'scenario 1: all fields valid — validators pass and cubit.submit is called',
    (tester) async {
      await tester.pumpWidget(_wrap(cubit: cubit));

      // Locate the four TextFormField widgets by index (name, username, email, password).
      await tester.enterText(find.byType(TextFormField).at(0), 'Alice Example');
      await tester.enterText(find.byType(TextFormField).at(1), 'alice');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'alice@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'Password1!');

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // No field-level error text on any TextFormField.
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in textFields) {
        expect(
          field.decoration?.errorText,
          isNull,
          reason:
              'Expected no error text on any field when all inputs are valid',
        );
      }

      // cubit.submit called exactly once with the correct NewUserData.
      final captured = verify(
        () => cubit.submit(captureAny()),
      ).captured;
      expect(captured.length, 1);
      final data = captured.first as NewUserData;
      expect(data.name, 'Alice Example');
      expect(data.username, 'alice');
      expect(data.email, 'alice@example.com');
      expect(data.password, 'Password1!');
    },
  );

  // Scenario 2 (tests.md §Scenario 2):
  // CreateUserSubmitting state → submit button disabled, spinner present,
  // no validation error text, four TextFormFields still rendered.
  testWidgets(
    'scenario 2: CreateUserSubmitting — button disabled and spinner shown',
    (tester) async {
      final controller = StreamController<CreateUserState>.broadcast();
      when(() => cubit.stream).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(_wrap(cubit: cubit));

      controller.add(const CreateUserState.submitting());
      await tester.pump();

      // FilledButton is disabled (onPressed == null).
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.onPressed,
        isNull,
        reason: 'Submit button must be disabled when CreateUserSubmitting',
      );

      // CircularProgressIndicator is rendered inside the button.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // No validation error text below the button.
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in textFields) {
        expect(field.decoration?.errorText, isNull);
      }

      // All four TextFormFields are still present.
      expect(find.byType(TextFormField), findsNWidgets(4));

      await controller.close();
    },
  );
}
