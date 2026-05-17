import 'package:flutter/foundation.dart';

@immutable
final class AuthSession {
  const AuthSession({required this.accessToken, required this.username});

  final String accessToken;
  final String username;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AuthSession) return false;
    return accessToken == other.accessToken && username == other.username;
  }

  @override
  int get hashCode => accessToken.hashCode ^ username.hashCode;
}
