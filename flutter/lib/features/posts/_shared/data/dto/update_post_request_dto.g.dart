// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_post_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdatePostRequestDto _$UpdatePostRequestDtoFromJson(
  Map<String, dynamic> json,
) => _UpdatePostRequestDto(
  title: json['title'] as String,
  text: json['text'] as String,
  mediaUrl: json['media_url'] as String?,
);

Map<String, dynamic> _$UpdatePostRequestDtoToJson(
  _UpdatePostRequestDto instance,
) => <String, dynamic>{
  'title': instance.title,
  'text': instance.text,
  'media_url': instance.mediaUrl,
};
