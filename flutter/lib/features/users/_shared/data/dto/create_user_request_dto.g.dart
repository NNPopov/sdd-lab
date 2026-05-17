// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_user_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateUserRequestDto _$CreateUserRequestDtoFromJson(
  Map<String, dynamic> json,
) => _CreateUserRequestDto(
  name: json['name'] as String,
  username: json['username'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$CreateUserRequestDtoToJson(
  _CreateUserRequestDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'username': instance.username,
  'email': instance.email,
  'password': instance.password,
};
