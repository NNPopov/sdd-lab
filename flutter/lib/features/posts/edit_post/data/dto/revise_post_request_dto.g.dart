// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revise_post_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RevisePostRequestDto _$RevisePostRequestDtoFromJson(
  Map<String, dynamic> json,
) => _RevisePostRequestDto(
  title: json['title'] as String?,
  text: json['text'] as String?,
  message: json['message'] as String,
);

Map<String, dynamic> _$RevisePostRequestDtoToJson(
  _RevisePostRequestDto instance,
) => <String, dynamic>{
  'title': instance.title,
  'text': instance.text,
  'message': instance.message,
};
