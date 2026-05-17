import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';

abstract class EditPostPort {
  Future<Either<Failure, void>> call(UpdatedPostData data);
}
