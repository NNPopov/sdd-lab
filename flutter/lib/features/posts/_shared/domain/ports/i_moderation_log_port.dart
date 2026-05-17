import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_log_entry.dart';

abstract interface class IModerationLogPort {
  Future<Either<Failure, List<ModerationLogEntry>>> call(String postUuid);
}
