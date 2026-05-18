import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_cubit.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_state.dart';
import 'package:flutter_application_1/features/posts/delete_post/presentation/delete_post_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeletePostCubit extends MockCubit<DeletePostState>
    implements DeletePostCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

void main() {
  late _MockDeletePostCubit mockCubit;
  late _MockStackRouter mockRouter;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
  });

  setUp(() {
    mockCubit = _MockDeletePostCubit();
    mockRouter = _MockStackRouter();
    when(() => mockRouter.pop()).thenAnswer((_) async => true);
    getIt.registerFactory<DeletePostCubit>(() => mockCubit);
  });

  tearDown(() async {
    await getIt.unregister<DeletePostCubit>();
  });

  Widget buildSubject({
    required DeletePostState state,
    Stream<DeletePostState>? stream,
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
              actions: const [DeletePostButton(username: 'alice', id: 42)],
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
    'on success calls pop() on the active tab router (not the root router)',
    (tester) async {
      final controller = StreamController<DeletePostState>.broadcast();

      await tester.pumpWidget(
        buildSubject(
          state: const DeletePostState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(const DeletePostState.success());
      await tester.pumpAndSettle();

      verify(() => mockRouter.pop()).called(1);

      await controller.close();
    },
  );
}
