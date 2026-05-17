import 'package:flutter_application_1/core/auth/infrastructure/token_holder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TokenHolder holder;

  setUp(() => holder = TokenHolder());

  test('current is null initially', () {
    expect(holder.current, isNull);
  });

  test('setting current stores the token', () {
    holder.current = 'abc';
    expect(holder.current, 'abc');
  });

  test('release clears current', () {
    holder
      ..current = 'abc'
      ..release();
    expect(holder.current, isNull);
  });

  test('assigning replaces previous token', () {
    holder
      ..current = 'first'
      ..current = 'second';
    expect(holder.current, 'second');
  });
}
