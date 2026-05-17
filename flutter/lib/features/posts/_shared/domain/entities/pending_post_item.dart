import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_log_entry.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';

class PendingPostItem {
  const PendingPostItem({
    required this.postUuid,
    required this.title,
    required this.text,
    required this.status,
    required this.createdAt,
    required this.authorUsername,
    required this.moderationLog,
    this.updatedAt,
    this.mediaUrl,
  });

  final String postUuid;
  final String title;
  final String text;
  final PostStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String authorUsername;
  final List<ModerationLogEntry> moderationLog;
  final String? mediaUrl;
}
