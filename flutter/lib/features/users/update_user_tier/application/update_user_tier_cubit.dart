import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_state.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/usecases/fetch_tiers_usecase.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/usecases/update_user_tier_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class UpdateUserTierCubit extends Cubit<UpdateUserTierState> {
  UpdateUserTierCubit(
    this._fetchTiers,
    this._updateTier,
    this._auth,
  ) : super(const UpdateUserTierState.initial());

  final FetchTiersUseCase _fetchTiers;
  final UpdateUserTierUseCase _updateTier;
  final AuthCubit _auth;

  Future<void> loadTiers() async {
    emit(const UpdateUserTierState.loadingTiers());
    final result = await _fetchTiers();
    result.fold(
      (f) => emit(UpdateUserTierState.error(f)),
      (tiers) => emit(UpdateUserTierState.tiersLoaded(tiers: tiers)),
    );
  }

  void selectTier(int tierId) {
    final s = state;
    if (s is UpdateUserTierTiersLoaded) {
      emit(s.copyWith(selectedTierId: tierId));
    }
  }

  Future<void> submit(String username) async {
    final s = state;
    if (s is! UpdateUserTierTiersLoaded || s.selectedTierId == null) return;
    final tierId = s.selectedTierId!;
    final isSuperuser = _auth.currentUser?.isSuperuser ?? false;

    emit(
      UpdateUserTierState.submitting(tiers: s.tiers, selectedTierId: tierId),
    );

    final result = await _updateTier(
      username: username,
      tierId: tierId,
      isSuperuser: isSuperuser,
    );

    result.fold(
      (f) => emit(UpdateUserTierState.error(f)),
      (_) => emit(const UpdateUserTierState.success()),
    );
  }

  void reset() => emit(const UpdateUserTierState.initial());
}
