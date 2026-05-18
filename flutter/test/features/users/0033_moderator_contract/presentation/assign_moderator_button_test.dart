import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/users/moderator_contract/application/assign_moderator_cubit.dart';
import 'package:flutter_application_1/features/users/moderator_contract/application/assign_moderator_state.dart';
import 'package:flutter_application_1/features/users/moderator_contract/presentation/widgets/assign_moderator_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAssignModeratorCubit extends MockCubit<AssignModeratorState>
    implements AssignModeratorCubit {}

void main() {
  late _MockAssignModeratorCubit mockCubit;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
  });

  setUp(() {
    mockCubit = _MockAssignModeratorCubit();
    getIt.registerFactory<AssignModeratorCubit>(() => mockCubit);
  });

  tearDown(() async {
    await getIt.unregister<AssignModeratorCubit>();
  });

  Widget buildSubject({
    required AssignModeratorState state,
    required bool isModerator,
    Stream<AssignModeratorState>? stream,
  }) {
    when(() => mockCubit.state).thenReturn(state);
    when(() => mockCubit.stream).thenAnswer(
      (_) => stream ?? const Stream.empty(),
    );
    return TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              AssignModeratorButton(
                username: 'alice',
                isModerator: isModerator,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets(
    'isModerator:false → shows "Assign Moderator"',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const AssignModeratorState.initial(),
          isModerator: false,
        ),
      );
      await tester.pump();

      expect(find.text('Assign Moderator'), findsOneWidget);
      expect(find.text('Revoke Moderator'), findsNothing);
    },
  );

  testWidgets(
    'isModerator:true → shows "Revoke Moderator"',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const AssignModeratorState.initial(),
          isModerator: true,
        ),
      );
      await tester.pump();

      expect(find.text('Revoke Moderator'), findsOneWidget);
      expect(find.text('Assign Moderator'), findsNothing);
    },
  );

  testWidgets('loading state → shows CircularProgressIndicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        state: const AssignModeratorState.loading(),
        isModerator: false,
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state → shows snackbar with forbidden message', (
    tester,
  ) async {
    const failure = Failure.forbidden(message: 'denied');
    final controller = StreamController<AssignModeratorState>.broadcast();

    await tester.pumpWidget(
      buildSubject(
        state: const AssignModeratorState.initial(),
        isModerator: false,
        stream: controller.stream,
      ),
    );

    controller.add(const AssignModeratorState.error(failure));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('You do not have permission to manage moderators.'),
      findsOneWidget,
    );

    await controller.close();
  });

  testWidgets(
    'success state → label toggles to opposite (false→true)',
    (tester) async {
      final controller = StreamController<AssignModeratorState>.broadcast();

      await tester.pumpWidget(
        buildSubject(
          state: const AssignModeratorState.initial(),
          isModerator: false,
          stream: controller.stream,
        ),
      );

      expect(find.text('Assign Moderator'), findsOneWidget);

      controller.add(const AssignModeratorState.success(isModerator: true));
      await tester.pump();

      expect(find.text('Revoke Moderator'), findsOneWidget);
      expect(find.text('Assign Moderator'), findsNothing);

      await controller.close();
    },
  );
}
