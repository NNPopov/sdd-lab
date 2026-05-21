import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_cubit.dart';
import 'package:flutter_application_1/features/users/create_user/application/create_user_state.dart';
import 'package:flutter_application_1/features/users/create_user/presentation/create_user_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateUserCubit extends MockCubit<CreateUserState>
    implements CreateUserCubit {}

Widget _wrap({required CreateUserCubit cubit}) {
  return TranslationProvider(
    child: MaterialApp(
      home: BlocProvider<CreateUserCubit>.value(
        value: cubit,
        child: const CreateUserScreen(),
      ),
    ),
  );
}

void main() {
  late _MockCreateUserCubit cubit;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
  });

  setUp(() {
    cubit = _MockCreateUserCubit();
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.state).thenReturn(const CreateUserState.idle());
    when(() => cubit.clearError()).thenReturn(null);
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets(
    'CreateUserValidationError → error text below button, '
    'no TextFormField errorText',
    (tester) async {
      final controller = StreamController<CreateUserState>.broadcast();
      when(() => cubit.stream).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(_wrap(cubit: cubit));

      controller.add(
        const CreateUserState.validationError(message: 'Username taken'),
      );
      await tester.pump();

      expect(find.text('Username taken'), findsOneWidget);
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      for (final field in fields) {
        expect(field.decoration?.errorText, isNull);
      }

      await controller.close();
    },
  );

  testWidgets(
    'CreateUserConflict → snackbar with server message',
    (tester) async {
      final controller = StreamController<CreateUserState>.broadcast();
      when(() => cubit.stream).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(_wrap(cubit: cubit));

      controller.add(const CreateUserState.conflict(message: 'Conflict'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Conflict'), findsOneWidget);

      await controller.close();
    },
  );

  testWidgets(
    'CreateUserIdle after CreateUserValidationError → error text gone',
    (tester) async {
      final controller = StreamController<CreateUserState>.broadcast();
      when(() => cubit.stream).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(_wrap(cubit: cubit));

      controller.add(
        const CreateUserState.validationError(message: 'Username taken'),
      );
      await tester.pump();
      expect(find.text('Username taken'), findsOneWidget);

      controller.add(const CreateUserState.idle());
      await tester.pump();
      await tester.pump();
      expect(find.text('Username taken'), findsNothing);

      await controller.close();
    },
  );
}
