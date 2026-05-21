import 'package:flutter_application_1/features/users/user_details/application/user_details_state.dart';
import 'package:flutter_application_1/features/users/user_details/domain/usecases/get_user_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class UserDetailsCubit extends Cubit<UserDetailsState> {
  UserDetailsCubit(this._getUser) : super(const UserDetailsState.initial());

  final GetUserUseCase _getUser;

  Future<void> load(String username) async {
    emit(const UserDetailsState.loading());
    final result = await _getUser(username);
    result.fold(
      (f) => emit(UserDetailsState.error(f)),
      (u) => emit(UserDetailsState.loaded(u)),
    );
  }

  Future<void> retry(String username) => load(username);

  void updateIsModerator(bool isModerator) {
    final current = state;
    if (current is UserDetailsLoaded) {
      emit(UserDetailsLoaded(current.user.copyWith(isModerator: isModerator)));
    }
  }
}
