import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';

class UpdatedPostData {
  const UpdatedPostData({
    required this.userId,
    required this.id,
    required this.postUuid,
    required this.status,
    required this.title,
    required this.text,
    this.mediaUrl,
    this.revisionMessage,
  });

  final int userId;
  final int id;
  final String postUuid;
  final PostStatus status;
  final String title;
  final String text;
  final String? mediaUrl;
  final String? revisionMessage;
}
