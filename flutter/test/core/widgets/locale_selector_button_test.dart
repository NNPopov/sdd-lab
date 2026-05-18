import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/locale_cubit.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/widgets/locale_selector_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocaleCubit extends MockCubit<AppLocale> implements LocaleCubit {}

Widget _buildApp(_MockLocaleCubit cubit) {
  return MaterialApp(
    home: BlocProvider<LocaleCubit>.value(
      value: cubit,
      child: const Scaffold(
        body: LocaleSelectorButton(),
      ),
    ),
  );
}

void main() {
  late _MockLocaleCubit mockCubit;

  setUpAll(() {
    registerFallbackValue(AppLocale.enUs);
  });

  setUp(() {
    mockCubit = _MockLocaleCubit();
    when(() => mockCubit.setLocale(any())).thenAnswer((_) async {});
  });

  group('LocaleSelectorButton', () {
    testWidgets('displays "EN" when locale is AppLocale.enUs', (tester) async {
      whenListen(
        mockCubit,
        const Stream<AppLocale>.empty(),
        initialState: AppLocale.enUs,
      );

      await tester.pumpWidget(_buildApp(mockCubit));

      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('displays "RU" when locale is AppLocale.ruRu', (tester) async {
      whenListen(
        mockCubit,
        const Stream<AppLocale>.empty(),
        initialState: AppLocale.ruRu,
      );

      await tester.pumpWidget(_buildApp(mockCubit));

      expect(find.text('RU'), findsOneWidget);
    });

    testWidgets(
      'tap opens bottom sheet with "English" and "Русский"',
      (tester) async {
        whenListen(
          mockCubit,
          const Stream<AppLocale>.empty(),
          initialState: AppLocale.enUs,
        );

        await tester.pumpWidget(_buildApp(mockCubit));
        await tester.tap(find.text('EN'));
        await tester.pumpAndSettle();

        expect(find.text('English'), findsOneWidget);
        expect(find.text('Русский'), findsOneWidget);
      },
    );

    testWidgets(
      'tap "Русский" calls cubit.setLocale(AppLocale.ruRu)',
      (tester) async {
        whenListen(
          mockCubit,
          const Stream<AppLocale>.empty(),
          initialState: AppLocale.enUs,
        );

        await tester.pumpWidget(_buildApp(mockCubit));
        await tester.tap(find.text('EN'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Русский'));
        await tester.pumpAndSettle();

        verify(() => mockCubit.setLocale(AppLocale.ruRu)).called(1);
      },
    );

    testWidgets(
      'active locale has check icon, inactive does not',
      (tester) async {
        whenListen(
          mockCubit,
          const Stream<AppLocale>.empty(),
          initialState: AppLocale.enUs,
        );

        await tester.pumpWidget(_buildApp(mockCubit));
        await tester.tap(find.text('EN'));
        await tester.pumpAndSettle();

        // English row has check; Русский row does not
        final englishTile = find.ancestor(
          of: find.text('English'),
          matching: find.byType(ListTile),
        );
        final russianTile = find.ancestor(
          of: find.text('Русский'),
          matching: find.byType(ListTile),
        );

        expect(
          find.descendant(
            of: englishTile,
            matching: find.byIcon(Icons.check),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: russianTile,
            matching: find.byIcon(Icons.check),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('tap locale closes the bottom sheet', (tester) async {
      whenListen(
        mockCubit,
        const Stream<AppLocale>.empty(),
        initialState: AppLocale.enUs,
      );

      await tester.pumpWidget(_buildApp(mockCubit));
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsNothing);
    });
  });
}
