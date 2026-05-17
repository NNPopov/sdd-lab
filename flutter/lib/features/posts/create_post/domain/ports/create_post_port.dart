import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/entities/new_post_data.dart';

abstract class CreatePostPort {
  Future<Either<Failure, void>> call(NewPostData data);
}
