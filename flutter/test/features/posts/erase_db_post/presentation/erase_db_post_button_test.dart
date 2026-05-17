import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_cubit.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_state.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/presentation/erase_db_post_button.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/presentation/widgets/erase_db_post_confirmation_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEraseDbPostCubit extends MockCubit<EraseDbPostState>
    implements EraseDbPostCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

void main() {
  late _MockEraseDbPostCubit mockCubit;
  late _MockStackRouter mockRouter;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  setUp(() {
    mockCubit = _MockEraseDbPostCubit();
    mockRouter = _MockStackRouter();
    when(() => mockRouter.pop()).thenAnswer((_) async => true);
    getIt.registerFactory<EraseDbPostCubit>(() => mockCubit);
  });

  tearDown(() async {
    await getIt.unregister<EraseDbPostCubit>();
  });

  Widget buildSubject({
    required EraseDbPostState state,
    Stream<EraseDbPostState>? stream,
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
              actions: const [
                EraseDbPostButton(username: 'alice', id: 42),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders delete_forever icon when state is initial',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(state: const EraseDbPostState.initial()),
      );

      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'shows spinner and disables button when state is deleting',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(state: const EraseDbPostState.deleting()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final btn = tester.widget<IconButton>(find.byType(IconButton));
      expect(btn.onPressed, isNull);
    },
  );

  testWidgets(
    'tapping icon calls requestConfirmation',
    (tester) async {
      when(() => mockCubit.requestConfirmation()).thenReturn(null);

      await tester.pumpWidget(
        buildSubject(state: const EraseDbPostState.initial()),
      );
      await tester.tap(find.byIcon(Icons.delete_forever));

      verify(() => mockCubit.requestConfirmation()).called(1);
    },
  );

  testWidgets(
    'shows confirmation dialog when state becomes confirming',
    (tester) async {
      final controller = StreamController<EraseDbPostState>.broadcast();
      when(() => mockCubit.cancel()).thenReturn(null);

      await tester.pumpWidget(
        buildSubject(
          state: const EraseDbPostState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(const EraseDbPostState.confirming());
      await tester.pumpAndSettle();

      expect(find.byType(EraseDbPostConfirmationDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);

      await controller.close();
    },
  );

  testWidgets(
    'tapping Erase in dialog calls confirmAndErase',
    (tester) async {
      final controller = StreamController<EraseDbPostState>.broadcast();
      when(
        () => mockCubit.confirmAndErase(any(), any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildSubject(
          state: const EraseDbPostState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(const EraseDbPostState.confirming());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Erase'));
      await tester.pumpAndSettle();

      verify(() => mockCubit.confirmAndErase('alice', 42)).called(1);

      await controller.close();
    },
  );

  testWidgets(
    'tapping Cancel in dialog calls cancel',
    (tester) async {
      final controller = StreamController<EraseDbPostState>.broadcast();
      when(() => mockCubit.cancel()).thenReturn(null);

      await tester.pumpWidget(
        buildSubject(
          state: const EraseDbPostState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(const EraseDbPostState.confirming());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verify(() => mockCubit.cancel()).called(1);

      await controller.close();
    },
  );

  testWidgets(
    'shows success snackbar and calls router.pop on success',
    (tester) async {
      final controller = StreamController<EraseDbPostState>.broadcast();

      await tester.pumpWidget(
        buildSubject(
          state: const EraseDbPostState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(const EraseDbPostState.success());
      await tester.pumpAndSettle();

      expect(find.text('Post erased'), findsOneWidget);
      verify(() => mockRouter.pop()).called(1);

      await controller.close();
    },
  );

  testWidgets(
    'shows generic error snackbar on unknown failure',
    (tester) async {
      final controller = StreamController<EraseDbPostState>.broadcast();

      await tester.pumpWidget(
        buildSubject(
          state: const EraseDbPostState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(
        const EraseDbPostState.failure(Failure.unknown()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to erase post. Please try again.'),
        findsOneWidget,
      );

      await controller.close();
    },
  );

  testWidgets(
    'shows forbidden error snackbar on ForbiddenFailure',
    (tester) async {
      final controller = StreamController<EraseDbPostState>.broadcast();

      await tester.pumpWidget(
        buildSubject(
          state: const EraseDbPostState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(
        const EraseDbPostState.failure(
          Failure.forbidden(message: 'Forbidden'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('You do not have permission to erase posts'),
        findsOneWidget,
      );

      await controller.close();
    },
  );

  testWidgets(
    'icon is re-enabled after failure (onPressed is not null)',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(
          state: const EraseDbPostState.failure(Failure.unknown()),
        ),
      );

      final btn = tester.widget<IconButton>(find.byType(IconButton));
      expect(btn.onPressed, isNotNull);
    },
  );
}
