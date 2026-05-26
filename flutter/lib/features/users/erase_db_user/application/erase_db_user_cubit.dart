import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/features/users/erase_db_user/application/erase_db_user_state.dart';
import 'package:flutter_application_1/features/users/erase_db_user/domain/usecases/erase_db_user_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class EraseDbUserCubit extends Cubit<EraseDbUserState> {
  EraseDbUserCubit(this._eraseDbUser, this._authCubit)
    : super(const EraseDbUserState.initial());

  final EraseDbUserUseCase _eraseDbUser;
  final AuthCubit _authCubit;

  void requestConfirmation() {
    emit(const EraseDbUserState.confirming());
  }

  void cancel() {
    if (state is EraseDbUserConfirming) {
      emit(const EraseDbUserState.initial());
    }
  }

  Future<void> confirmAndDelete(int userId) async {
    emit(const EraseDbUserState.deleting());
    final result = await _eraseDbUser(
      userId: userId,
      isSuperuser: _authCubit.currentUser?.isSuperuser ?? false,
    );
    await result.fold(
      (f) async => emit(EraseDbUserState.failure(f)),
      (_) async {
        // Token is now blacklisted by the server. Perform local logout without
        // the "session expired" notification — caller shows its own snackbar.
        await _authCubit.forceLogout(notifyUser: false);
        emit(const EraseDbUserState.success());
      },
    );
  }
}
