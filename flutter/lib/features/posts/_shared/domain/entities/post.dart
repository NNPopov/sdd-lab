import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';

class Post {
  const Post({
    required this.id,
    required this.title,
    required this.text,
    required this.createdAt,
    required this.createdByUserId,
    required this.postUuid,
    required this.status,
    this.mediaUrl,
    this.username,
  });

  final int id;
  final String title;
  final String text;
  final DateTime createdAt;
  final int createdByUserId;
  final String postUuid;
  final PostStatus status;
  final String? mediaUrl;
  final String? username;
}
