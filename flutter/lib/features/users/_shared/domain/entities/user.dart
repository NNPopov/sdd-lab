import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
sealed class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String username,
    required String email,
    required bool isModerator,
    String? profileImageUrl,
    int? tierId,
  }) = _User;
}
