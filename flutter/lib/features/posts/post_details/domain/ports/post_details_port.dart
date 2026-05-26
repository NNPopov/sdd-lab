import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';

abstract class PostDetailsPort {
  Future<Either<Failure, Post>> call(int userId, int id);
}
