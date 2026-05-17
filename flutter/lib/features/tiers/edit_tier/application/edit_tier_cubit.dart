import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_state.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/entities/edit_tier_data.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/usecases/edit_tier_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class EditTierCubit extends Cubit<EditTierState> {
  EditTierCubit(this._useCase) : super(const EditTierState.initial());

  final EditTierUseCase _useCase;

  Future<void> submit({
    required EditTierData data,
    required bool isSuperuser,
  }) async {
    emit(const EditTierState.submitting());
    final result = await _useCase(data: data, isSuperuser: isSuperuser);
    result.fold(
      (failure) => emit(EditTierState.failure(failure)),
      (_) => emit(EditTierState.success(newName: data.newName)),
    );
  }
}
