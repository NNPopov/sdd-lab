import 'dart:io';

import 'package:flutter_application_1/core/i18n/hive_locale_storage_adapter.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late HiveLocaleStorageAdapter adapter;
  late _MockAppLogger mockLogger;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(dir.path);
    mockLogger = _MockAppLogger();
    adapter = HiveLocaleStorageAdapter(mockLogger);
  });

  tearDown(() async {
    await Hive.close();
  });

  group('saveLocale()', () {
    test('stores "en" in box for AppLocale.en', () async {
      await adapter.saveLocale(AppLocale.en);
      final box = await Hive.openBox<String>('locale');
      expect(box.get('locale'), 'en');
    });

    test('stores "ru" in box for AppLocale.ru', () async {
      await adapter.saveLocale(AppLocale.ru);
      final box = await Hive.openBox<String>('locale');
      expect(box.get('locale'), 'ru');
    });
  });

  group('loadLocale()', () {
    test('returns AppLocale.ru after saveLocale(AppLocale.ru)', () async {
      await adapter.saveLocale(AppLocale.ru);
      final result = await adapter.loadLocale();
      expect(result, AppLocale.ru);
    });

    test('returns null when box is empty', () async {
      final result = await adapter.loadLocale();
      expect(result, isNull);
    });

    test('returns null for unknown language code', () async {
      final box = await Hive.openBox<String>('locale');
      await box.put('locale', 'de');
      final result = await adapter.loadLocale();
      expect(result, isNull);
    });
  });
}
