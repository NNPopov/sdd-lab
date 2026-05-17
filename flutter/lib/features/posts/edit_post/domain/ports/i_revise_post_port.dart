import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';

abstract interface class IRevisePostPort {
  Future<Either<Failure, void>> call(UpdatedPostData data);
}
