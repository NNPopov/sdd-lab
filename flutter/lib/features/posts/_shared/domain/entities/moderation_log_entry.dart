import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_action.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_event_type.dart';

class ModerationLogEntry {
  const ModerationLogEntry({
    required this.id,
    required this.eventType,
    required this.createdAt,
    required this.actorUserId,
    required this.actorUsername,
    this.action,
    this.message,
  });

  final int id;
  final ModerationEventType eventType;
  final ModerationAction? action;
  final String? message;
  final DateTime createdAt;
  final int actorUserId;
  final String actorUsername;
}
