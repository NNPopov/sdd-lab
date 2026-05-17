import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/logging/infrastructure/console_logger_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ConsoleLoggerAdapter logger;
  late List<String> printed;
  late DebugPrintCallback original;

  setUp(() {
    logger = ConsoleLoggerAdapter();
    printed = [];
    original = debugPrint;
    debugPrint = (m, {wrapWidth}) {
      if (m != null) printed.add(m);
    };
  });

  tearDown(() => debugPrint = original);

  test('info always prints message with tag', () {
    logger.info('hello');
    expect(printed, contains('[INFO] hello'));
  });

  test('warning prints message without error/stack when not provided', () {
    logger.warning('something odd');
    expect(printed, contains('[WARNING] something odd'));
    expect(printed.any((s) => s.contains('error:')), isFalse);
    expect(printed.any((s) => s.contains('stack:')), isFalse);
  });

  test('warning prints error and stack when provided', () {
    final err = Exception('warn-err');
    final st = StackTrace.current;
    logger.warning('watch out', error: err, stackTrace: st);
    expect(printed.any((s) => s.contains('[WARNING] watch out')), isTrue);
    expect(printed.any((s) => s.contains('warn-err')), isTrue);
    expect(printed.any((s) => s.contains('stack:')), isTrue);
  });

  test('error prints message, error, and stack when provided', () {
    final err = Exception('boom');
    final st = StackTrace.current;
    logger.error('failed', error: err, stackTrace: st);
    expect(printed.any((s) => s.contains('[ERROR] failed')), isTrue);
    expect(printed.any((s) => s.contains('boom')), isTrue);
    expect(printed.any((s) => s.contains('stack:')), isTrue);
  });

  test('error prints only message when error and stack not provided', () {
    logger.error('plain error');
    expect(printed, contains('[ERROR] plain error'));
    expect(printed.any((s) => s.contains('error:')), isFalse);
    expect(printed.any((s) => s.contains('stack:')), isFalse);
  });
}
