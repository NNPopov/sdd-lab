import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_tier.freezed.dart';

@freezed
sealed class UserTier with _$UserTier {
  const factory UserTier({
    required String tierName,
    DateTime? tierCreatedAt,
  }) = _UserTier;
}
