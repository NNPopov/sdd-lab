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
    registerFallbackValue(AppLocale.enUs);
  });

  setUp(() {
    mockStorage = _MockLocaleStoragePort();
  });

  LocaleCubit buildCubit() => LocaleCubit(mockStorage);

  group('init()', () {
    blocTest<LocaleCubit, AppLocale>(
      'emits saved locale and calls saveLocale '
      'when loadLocale returns AppLocale.ruRu',
      build: buildCubit,
      setUp: () {
        when(
          () => mockStorage.loadLocale(),
        ).thenAnswer((_) async => AppLocale.ruRu);
        when(() => mockStorage.saveLocale(any())).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.init(),
      expect: () => [AppLocale.ruRu],
      verify: (_) {
        verify(() => mockStorage.saveLocale(AppLocale.ruRu)).called(1);
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
      'emits AppLocale.ruRu and calls saveLocale(AppLocale.ruRu)',
      build: buildCubit,
      setUp: () {
        when(() => mockStorage.saveLocale(any())).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.setLocale(AppLocale.ruRu),
      expect: () => [AppLocale.ruRu],
      verify: (_) {
        verify(() => mockStorage.saveLocale(AppLocale.ruRu)).called(1);
      },
    );

    blocTest<LocaleCubit, AppLocale>(
      'emits AppLocale.enUs and calls saveLocale(AppLocale.enUs)',
      build: buildCubit,
      setUp: () {
        when(() => mockStorage.saveLocale(any())).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.setLocale(AppLocale.enUs),
      expect: () => [AppLocale.enUs],
      verify: (_) {
        verify(() => mockStorage.saveLocale(AppLocale.enUs)).called(1);
      },
    );

    blocTest<LocaleCubit, AppLocale>(
      'emits AppLocale.esEs and calls saveLocale(AppLocale.esEs)',
      build: buildCubit,
      setUp: () {
        when(() => mockStorage.saveLocale(any())).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.setLocale(AppLocale.esEs),
      expect: () => [AppLocale.esEs],
      verify: (_) {
        verify(() => mockStorage.saveLocale(AppLocale.esEs)).called(1);
      },
    );

    blocTest<LocaleCubit, AppLocale>(
      'emits AppLocale.ukUa and calls saveLocale(AppLocale.ukUa)',
      build: buildCubit,
      setUp: () {
        when(() => mockStorage.saveLocale(any())).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.setLocale(AppLocale.ukUa),
      expect: () => [AppLocale.ukUa],
      verify: (_) {
        verify(() => mockStorage.saveLocale(AppLocale.ukUa)).called(1);
      },
    );
  });
}
