import 'package:meta/meta.dart';

@immutable
final class CurrentUser {
  const CurrentUser({
    required this.username,
    required this.email,
    required this.name,
    required this.isSuperuser,
    required this.isModerator,
    this.profileImageUrl,
  });

  final String username;
  final String email;
  final String name;
  final String? profileImageUrl;
  final bool isSuperuser;
  final bool isModerator;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentUser &&
          username == other.username &&
          email == other.email &&
          name == other.name &&
          profileImageUrl == other.profileImageUrl &&
          isSuperuser == other.isSuperuser &&
          isModerator == other.isModerator;

  @override
  int get hashCode => Object.hash(
    username,
    email,
    name,
    profileImageUrl,
    isSuperuser,
    isModerator,
  );
}
