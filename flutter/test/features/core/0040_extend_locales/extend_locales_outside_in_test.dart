import 'dart:io';

import 'package:flutter_application_1/core/i18n/hive_locale_storage_adapter.dart';
import 'package:flutter_application_1/core/i18n/locale_cubit.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late Directory tempDir;
  late _MockAppLogger mockLogger;
  late HiveLocaleStorageAdapter adapter;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('extend_locales_oi_');
    Hive.init(tempDir.path);
    mockLogger = _MockAppLogger();
    adapter = HiveLocaleStorageAdapter(mockLogger);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'Scenario 1: es-ES locale is selected, persisted, and restored on restart',
    () async {
      // ── First launch ──────────────────────────────────────────────────────
      final cubit1 = LocaleCubit(adapter);
      final emitted1 = <AppLocale>[];
      final sub1 = cubit1.stream.listen(emitted1.add);

      await cubit1.setLocale(AppLocale.esEs);

      await sub1.cancel();
      await cubit1.close();

      expect(emitted1, [AppLocale.esEs]);

      final box = await Hive.openBox<String>('locale');
      expect(box.get('locale'), 'es-ES');

      verifyNever(
        () => mockLogger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      );

      // ── Simulated restart (same adapter + Hive dir, new cubit) ────────────
      final cubit2 = LocaleCubit(adapter);
      final emitted2 = <AppLocale>[];
      final sub2 = cubit2.stream.listen(emitted2.add);

      await cubit2.init();

      await sub2.cancel();
      await cubit2.close();

      expect(emitted2, [AppLocale.esEs]);
    },
  );

  test(
    'Scenario 2: legacy tag "en" stored in Hive falls back silently to default',
    () async {
      // Pre-populate Hive with the tag written by the app before the regional-code rename
      final box = await Hive.openBox<String>('locale');
      await box.put('locale', 'en');

      final cubit = LocaleCubit(adapter);
      final emitted = <AppLocale>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.init();

      await sub.cancel();
      await cubit.close();

      // _parseLocale("en") returns null → init() is a no-op → no state emitted
      expect(emitted, isEmpty);

      // null return is a normal code path, not an error
      verifyNever(
        () => mockLogger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      );
    },
  );
}
