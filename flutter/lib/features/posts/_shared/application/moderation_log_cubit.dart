import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_state.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/ports/i_moderation_log_port.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class ModerationLogCubit extends Cubit<ModerationLogState> {
  ModerationLogCubit(this._port) : super(const ModerationLogState.initial());

  final IModerationLogPort _port;
  bool _loaded = false;

  Future<void> load(String postUuid) async {
    if (_loaded) return;
    _loaded = true;
    emit(const ModerationLogState.loading());
    final result = await _port(postUuid);
    result.fold(
      (f) {
        _loaded = false;
        emit(ModerationLogState.error(f));
      },
      (entries) => emit(ModerationLogState.loaded(entries)),
    );
  }
}
