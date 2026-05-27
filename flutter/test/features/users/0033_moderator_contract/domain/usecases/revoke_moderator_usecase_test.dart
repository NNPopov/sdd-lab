import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/ports/moderator_management_port.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/usecases/revoke_moderator_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPort extends Mock implements ModeratorManagementPort {}

void main() {
  late _MockPort port;
  late RevokeModeratorUseCase useCase;

  setUp(() {
    port = _MockPort();
    useCase = RevokeModeratorUseCase(port);
  });

  test('delegates to port.revokeModerator and passes result through', () async {
    when(
      () => port.revokeModerator(7),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase(7);

    expect(result, const Right<Failure, void>(null));
    verify(() => port.revokeModerator(7)).called(1);
  });

  test('passes Left through from port on failure', () async {
    const failure = Failure.conflict(message: 'not a moderator');
    when(
      () => port.revokeModerator(7),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(7);

    expect(result, const Left<Failure, void>(failure));
  });
}
