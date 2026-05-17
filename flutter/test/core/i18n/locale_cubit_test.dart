import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_application_1/core/i18n/locale_cubit.dart';
import 'package:flutter_application_1/core/i18n/locale_storage_port.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocaleStoragePort extends Mock implements LocaleStoragePort {}

void main() {
  late _MockLocaleStoragePort mockStorage;

  setUpAll(() {
    registerFallbackValue(AppLocale.en);
  });

  setUp(() {
    mockStorage = _MockLocaleStoragePort();
  });

  LocaleCubit buildCubit() => LocaleCubit(mockStorage);

  group('init()', () {
    blocTest<LocaleCubit, AppLocale>(
      'emits saved locale and calls saveLocale '
      'when loadLocale returns AppLocale.ru',
      build: buildCubit,
      setUp: () {
        when(
          () => mockStorage.loadLocale(),
        ).thenAnswer((_) async => AppLocale.ru);
        when(() => mockStorage.saveLocale(any())).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.init(),
      expect: () => [AppLocale.ru],
      verify: (_) {
        verify(() => mockStorage.saveLocale(AppLocale.ru)).called(1);
      },
    );

    blocTest<LocaleCubit, AppLocale>(
      'emits nothing when loadLocale returns null',
      build: buildCubit,
      setUp: () {
        when(() => mockStorage.loadLocale()).thenAnswer((_) async => null);
      },
      act: (cubit) => cubit.init(),
      expect: () => <AppLocale>[],
    );
  });

  group('setLocale()', () {
    blocTest<LocaleCubit, AppLocale>(
      'emits AppLocale.ru and calls saveLocale(AppLocale.ru)',
      build: buildCubit,
      setUp: () {
        when(() => mockStorage.saveLocale(any())).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.setLocale(AppLocale.ru),
      expect: () => [AppLocale.ru],
      verify: (_) {
        verify(() => mockStorage.saveLocale(AppLocale.ru)).called(1);
      },
    );

    blocTest<LocaleCubit, AppLocale>(
      'emits AppLocale.en and calls saveLocale(AppLocale.en)',
      build: buildCubit,
      setUp: () {
        when(() => mockStorage.saveLocale(any())).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.setLocale(AppLocale.en),
      expect: () => [AppLocale.en],
      verify: (_) {
        verify(() => mockStorage.saveLocale(AppLocale.en)).called(1);
      },
    );
  });
}
