import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/auth/login/presentation/login_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

Widget _wrap(Widget child, AuthCubit cubit) => TranslationProvider(
  child: MaterialApp(
    home: BlocProvider<AuthCubit>.value(
      value: cubit,
      child: child,
    ),
  ),
);

void main() {
  group('LoginScreen', () {
    late _MockAuthCubit cubit;

    setUp(() {
      cubit = _MockAuthCubit();
      when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
    });

    tearDown(() => cubit.close());

    Widget buildScreen() => _wrap(
      LoginScreen(onAuthenticated: () {}),
      cubit,
    );

    testWidgets('renders username and password fields', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byKey(const Key('usernameField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('empty fields show validation errors and login is not called', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      verifyNever(
        () => cubit.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('valid submission calls login with trimmed username', (
      tester,
    ) async {
      when(
        () => cubit.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildScreen());

      await tester.enterText(
        find.byKey(const Key('usernameField')),
        '  alice  ',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'secret123',
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      verify(
        () => cubit.login(username: 'alice', password: 'secret123'),
      ).called(1);
    });

    testWidgets('AuthAuthenticating disables button and shows spinner', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(const AuthState.authenticating());

      await tester.pumpWidget(buildScreen());

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'AuthError with InvalidCredentialsFailure shows inline error text',
      (tester) async {
        when(() => cubit.state).thenReturn(
          const AuthState.error(
            Failure.invalidCredentials(message: 'bad creds'),
          ),
        );

        await tester.pumpWidget(buildScreen());

        expect(find.text('Invalid username or password'), findsOneWidget);
      },
    );

    testWidgets(
      'AuthError with non-credentials failure does not show inline error',
      (tester) async {
        when(() => cubit.state).thenReturn(
          const AuthState.error(Failure.network()),
        );

        await tester.pumpWidget(buildScreen());

        expect(find.text('Invalid username or password'), findsNothing);
      },
    );
  });
}
