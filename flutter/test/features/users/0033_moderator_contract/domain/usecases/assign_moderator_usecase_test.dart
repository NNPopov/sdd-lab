import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/ports/moderator_management_port.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/usecases/assign_moderator_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPort extends Mock implements ModeratorManagementPort {}

void main() {
  late _MockPort port;
  late AssignModeratorUseCase useCase;

  setUp(() {
    port = _MockPort();
    useCase = AssignModeratorUseCase(port);
  });

  test('delegates to port.assignModerator and passes result through', () async {
    when(
      () => port.assignModerator(7),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase(7);

    expect(result, const Right<Failure, void>(null));
    verify(() => port.assignModerator(7)).called(1);
  });

  test('passes Left through from port on failure', () async {
    const failure = Failure.forbidden(message: 'denied');
    when(
      () => port.assignModerator(7),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(7);

    expect(result, const Left<Failure, void>(failure));
  });
}
