import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_action.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_event_type.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_log_entry.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_state.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/ports/i_moderation_log_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPort extends Mock implements IModerationLogPort {}

final _entry = ModerationLogEntry(
  id: 1,
  eventType: ModerationEventType.moderatorReview,
  action: ModerationAction.approved,
  createdAt: DateTime(2024),
  actorUserId: 42,
  actorUsername: 'mod1',
);

void main() {
  late _MockPort port;

  setUp(() {
    port = _MockPort();
  });

  blocTest<ModerationLogCubit, ModerationLogState>(
    'load() success with entries → emits [loading, loaded(entries)]',
    build: () => ModerationLogCubit(port),
    setUp: () {
      when(() => port(any())).thenAnswer((_) async => Right([_entry]));
    },
    act: (cubit) => cubit.load('uuid-1'),
    expect: () => [
      const ModerationLogState.loading(),
      ModerationLogState.loaded([_entry]),
    ],
  );

  blocTest<ModerationLogCubit, ModerationLogState>(
    'load() with empty list → emits [loading, loaded([])]',
    build: () => ModerationLogCubit(port),
    setUp: () {
      when(() => port(any())).thenAnswer((_) async => const Right([]));
    },
    act: (cubit) => cubit.load('uuid-1'),
    expect: () => [
      const ModerationLogState.loading(),
      const ModerationLogState.loaded([]),
    ],
  );

  blocTest<ModerationLogCubit, ModerationLogState>(
    'load() failure → emits [loading, error(failure)]; second load() retries',
    build: () => ModerationLogCubit(port),
    setUp: () {
      var callCount = 0;
      when(() => port(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return const Left(Failure.network());
        }
        return Right([_entry]);
      });
    },
    act: (cubit) async {
      await cubit.load('uuid-1');
      await cubit.load('uuid-1');
    },
    expect: () => [
      const ModerationLogState.loading(),
      isA<ModerationLogError>(),
      const ModerationLogState.loading(),
      ModerationLogState.loaded([_entry]),
    ],
  );

  blocTest<ModerationLogCubit, ModerationLogState>(
    'load() called twice → second call is no-op (one loading emitted)',
    build: () => ModerationLogCubit(port),
    setUp: () {
      when(() => port(any())).thenAnswer((_) async => Right([_entry]));
    },
    act: (cubit) async {
      await cubit.load('uuid-1');
      await cubit.load('uuid-1');
    },
    expect: () => [
      const ModerationLogState.loading(),
      ModerationLogState.loaded([_entry]),
    ],
    verify: (_) {
      verify(() => port(any())).called(1);
    },
  );
}
