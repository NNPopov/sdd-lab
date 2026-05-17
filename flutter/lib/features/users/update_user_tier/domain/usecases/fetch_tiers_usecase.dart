import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/entities/tier_option.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/ports/fetch_tiers_port.dart';
import 'package:injectable/injectable.dart';

@injectable
class FetchTiersUseCase {
  const FetchTiersUseCase(this._port);
  final FetchTiersPort _port;

  Future<Either<Failure, List<TierOption>>> call() => _port();
}
