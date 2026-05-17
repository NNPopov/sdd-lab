import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_state.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/domain/usecases/delete_tier_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteTierCubit extends Cubit<DeleteTierState> {
  DeleteTierCubit(this._deleteTier, this._authCubit)
    : super(const DeleteTierState.initial());

  final DeleteTierUseCase _deleteTier;
  final AuthCubit _authCubit;

  void requestConfirmation() => emit(const DeleteTierState.confirming());

  void cancel() {
    if (state is DeleteTierConfirming) {
      emit(const DeleteTierState.initial());
    }
  }

  Future<void> confirmAndDelete(String tierName) async {
    emit(const DeleteTierState.deleting());
    final isSuperuser = _authCubit.currentUser?.isSuperuser ?? false;
    final result = await _deleteTier(name: tierName, isSuperuser: isSuperuser);
    result.fold(
      (failure) => failure is NotFoundFailure
          ? emit(const DeleteTierState.notFound())
          : emit(DeleteTierState.failure(failure)),
      (_) => emit(const DeleteTierState.success()),
    );
  }
}
