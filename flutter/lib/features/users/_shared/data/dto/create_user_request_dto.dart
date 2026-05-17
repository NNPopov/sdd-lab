import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_user_request_dto.freezed.dart';
part 'create_user_request_dto.g.dart';

@freezed
sealed class CreateUserRequestDto with _$CreateUserRequestDto {
  const factory CreateUserRequestDto({
    required String name,
    required String username,
    required String email,
    required String password,
  }) = _CreateUserRequestDto;

  factory CreateUserRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateUserRequestDtoFromJson(json);
}
