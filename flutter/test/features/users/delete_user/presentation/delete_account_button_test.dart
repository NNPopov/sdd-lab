import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_cubit.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_state.dart';
import 'package:flutter_application_1/features/users/delete_user/presentation/delete_account_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeleteUserCubit extends MockCubit<DeleteUserState>
    implements DeleteUserCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

class _FakePageRouteInfo extends Fake implements PageRouteInfo<dynamic> {}

void main() {
  late _MockDeleteUserCubit mockCubit;
  late _MockStackRouter mockRouter;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
    registerFallbackValue(_FakePageRouteInfo());
    registerFallbackValue(<PageRouteInfo>[]);
  });

  setUp(() {
    mockCubit = _MockDeleteUserCubit();
    mockRouter = _MockStackRouter();
    when(() => mockRouter.replaceAll(any())).thenAnswer((_) async {});
    getIt.registerFactory<DeleteUserCubit>(() => mockCubit);
  });

  tearDown(() async {
    await getIt.unregister<DeleteUserCubit>();
  });

  Widget buildSubject({
    required DeleteUserState state,
    Stream<DeleteUserState>? stream,
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
              actions: const [DeleteAccountButton(userId: 1)],
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
    'on success calls replaceAll([UsersRoute()]) on the inner UsersTab router',
    (tester) async {
      final controller = StreamController<DeleteUserState>.broadcast();

      await tester.pumpWidget(
        buildSubject(
          state: const DeleteUserState.initial(),
          stream: controller.stream,
        ),
      );

      controller.add(const DeleteUserState.success());
      await tester.pumpAndSettle();

      final captured = verify(
        () => mockRouter.replaceAll(captureAny()),
      ).captured;
      final routes = captured.single as List<PageRouteInfo>;
      expect(routes.length, 1);
      expect(routes.single, isA<UsersRoute>());

      await controller.close();
    },
  );
}
