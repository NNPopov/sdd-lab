import 'package:flutter_application_1/core/auth/data/dto/current_user_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrentUserDtoX.toDomain', () {
    test('maps the numeric id through to the domain entity', () {
      const dto = CurrentUserDto(
        id: 99,
        name: 'Ada Lovelace',
        username: 'ada',
        email: 'ada@example.com',
      );

      expect(dto.toDomain().id, 99);
    });

    test('carries the handle and all other fields through unchanged', () {
      const dto = CurrentUserDto(
        id: 99,
        name: 'Ada Lovelace',
        username: 'ada',
        email: 'ada@example.com',
        isSuperuser: true,
        isModerator: true,
        profileImageUrl: 'https://example.com/ada.png',
      );

      final user = dto.toDomain();

      expect(user.username, 'ada');
      expect(user.email, 'ada@example.com');
      expect(user.name, 'Ada Lovelace');
      expect(user.isSuperuser, isTrue);
      expect(user.isModerator, isTrue);
      expect(user.profileImageUrl, 'https://example.com/ada.png');
    });
  });
}
