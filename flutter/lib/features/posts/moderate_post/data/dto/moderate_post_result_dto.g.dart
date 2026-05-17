// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderate_post_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModeratePostResultDto _$ModeratePostResultDtoFromJson(
  Map<String, dynamic> json,
) => _ModeratePostResultDto(
  postUuid: json['post_uuid'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$ModeratePostResultDtoToJson(
  _ModeratePostResultDto instance,
) => <String, dynamic>{
  'post_uuid': instance.postUuid,
  'status': instance.status,
};
