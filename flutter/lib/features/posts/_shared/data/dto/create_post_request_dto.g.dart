// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_post_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreatePostRequestDto _$CreatePostRequestDtoFromJson(
  Map<String, dynamic> json,
) => _CreatePostRequestDto(
  title: json['title'] as String,
  text: json['text'] as String,
  mediaUrl: json['media_url'] as String?,
);

Map<String, dynamic> _$CreatePostRequestDtoToJson(
  _CreatePostRequestDto instance,
) => <String, dynamic>{
  'title': instance.title,
  'text': instance.text,
  'media_url': instance.mediaUrl,
};
