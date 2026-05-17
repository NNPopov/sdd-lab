final class UserUpdate {
  const UserUpdate({
    this.name,
    this.username,
    this.email,
    this.profileImageUrl,
  });

  final String? name;
  final String? username;
  final String? email;
  final String? profileImageUrl;

  bool get isEmpty =>
      name == null &&
      username == null &&
      email == null &&
      profileImageUrl == null;
}
