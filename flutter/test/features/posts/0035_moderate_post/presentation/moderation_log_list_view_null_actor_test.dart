import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_state.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_event_type.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_log_entry.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/widgets/moderation_log_list_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockModerationLogCubit extends MockCubit<ModerationLogState>
    implements ModerationLogCubit {}

void main() {
  late _MockModerationLogCubit logCubit;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
  });

  setUp(() {
    logCubit = _MockModerationLogCubit();
    when(() => logCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets(
    'renders without error when actorUsername is null — shows empty string',
    (tester) async {
      final entry = ModerationLogEntry(
        id: 1,
        eventType: ModerationEventType.moderatorReview,
        createdAt: DateTime(2026, 5, 16, 21, 3),
      );

      when(() => logCubit.state).thenReturn(
        ModerationLogState.loaded([entry]),
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: BlocProvider<ModerationLogCubit>.value(
                value: logCubit,
                child: const ModerationLogListView(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text(''), findsOneWidget);
    },
  );
}
