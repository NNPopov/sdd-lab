import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_state.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/usecases/get_tier_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class TierDetailsCubit extends Cubit<TierDetailsState> {
  TierDetailsCubit(this._usecase) : super(const TierDetailsState.initial());

  final GetTierUsecase _usecase;

  Future<void> load(int id) async {
    emit(const TierDetailsState.loading());
    final result = await _usecase(id);
    result.fold(
      (f) => emit(TierDetailsState.error(failure: f)),
      (tier) => emit(TierDetailsState.loaded(tier: tier)),
    );
  }

  Future<void> retry(int id) => load(id);
}
