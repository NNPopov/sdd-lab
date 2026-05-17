import 'package:flutter_application_1/features/posts/post_details/application/post_details_state.dart';
import 'package:flutter_application_1/features/posts/post_details/domain/usecases/get_post_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class PostDetailsCubit extends Cubit<PostDetailsState> {
  PostDetailsCubit(this._useCase) : super(const PostDetailsState.initial());
  final GetPostUseCase _useCase;

  Future<void> load(String username, int id) async {
    emit(const PostDetailsState.loading());
    final result = await _useCase(username, id);
    result.fold(
      (failure) => emit(PostDetailsState.error(failure: failure)),
      (post) => emit(PostDetailsState.loaded(post: post)),
    );
  }
}
