import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';

abstract interface class IModeratePostPort {
  Future<Either<Failure, PostStatus>> call({
    required String postUuid,
    required String action,
    String? message,
  });
}
