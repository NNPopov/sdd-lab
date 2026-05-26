import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/post_details/domain/ports/post_details_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetPostUseCase {
  GetPostUseCase(this._port);
  final PostDetailsPort _port;

  Future<Either<Failure, Post>> call(int userId, int id) => _port(userId, id);
}
