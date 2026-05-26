import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrentUser identity includes id', () {
    const base = CurrentUser(
      id: 42,
      username: 'ada',
      email: 'ada@example.com',
      name: 'Ada Lovelace',
      isSuperuser: false,
      isModerator: false,
    );

    test('values identical except for id are not equal', () {
      const other = CurrentUser(
        id: 99,
        username: 'ada',
        email: 'ada@example.com',
        name: 'Ada Lovelace',
        isSuperuser: false,
        isModerator: false,
      );

      expect(base == other, isFalse);
      expect(base.hashCode == other.hashCode, isFalse);
    });

    test('values identical including id are equal with the same hashCode', () {
      const same = CurrentUser(
        id: 42,
        username: 'ada',
        email: 'ada@example.com',
        name: 'Ada Lovelace',
        isSuperuser: false,
        isModerator: false,
      );

      expect(base == same, isTrue);
      expect(base.hashCode == same.hashCode, isTrue);
    });

    test('the username handle remains part of identity alongside id', () {
      const sameIdOtherHandle = CurrentUser(
        id: 42,
        username: 'ada2',
        email: 'ada@example.com',
        name: 'Ada Lovelace',
        isSuperuser: false,
        isModerator: false,
      );

      expect(base == sameIdOtherHandle, isFalse);
      expect(base.hashCode == sameIdOtherHandle.hashCode, isFalse);
    });
  });
}
