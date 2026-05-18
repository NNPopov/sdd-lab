import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_state.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_cubit.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_state.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/moderate_post_screen.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/widgets/moderation_panel.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/widgets/post_content_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockModeratePostCubit extends MockCubit<ModeratePostState>
    implements ModeratePostCubit {}

class _MockModerationLogCubit extends MockCubit<ModerationLogState>
    implements ModerationLogCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

final _post = PendingPostItem(
  postUuid: 'post-uuid-1',
  title: 'Test Post',
  text: 'Body text',
  status: PostStatus.pendingReview,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  authorUsername: 'author1',
  moderationLog: const [],
);

void main() {
  late _MockModeratePostCubit moderateCubit;
  late _MockModerationLogCubit logCubit;
  late _MockStackRouter mockRouter;

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.enUs);
  });

  setUp(() {
    moderateCubit = _MockModeratePostCubit();
    logCubit = _MockModerationLogCubit();
    mockRouter = _MockStackRouter();

    when(() => moderateCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => logCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockRouter.pop()).thenAnswer((_) async => true);
    when(() => logCubit.load(any())).thenAnswer((_) async {});
    when(
      () => moderateCubit.moderate(
        postUuid: any(named: 'postUuid'),
        action: any(named: 'action'),
        message: any(named: 'message'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await moderateCubit.close();
    await logCubit.close();
  });

  Widget buildWide({
    ModeratePostState moderateState = const ModeratePostState.initial(),
    ModerationLogState logState = const ModerationLogState.initial(),
    Stream<ModeratePostState>? moderateStream,
    Stream<ModerationLogState>? logStream,
  }) {
    when(() => moderateCubit.state).thenReturn(moderateState);
    when(() => logCubit.state).thenReturn(logState);
    if (moderateStream != null) {
      when(() => moderateCubit.stream).thenAnswer((_) => moderateStream);
    }
    if (logStream != null) {
      when(() => logCubit.stream).thenAnswer((_) => logStream);
    }
    return TranslationProvider(
      child: StackRouterScope(
        stateHash: 0,
        controller: mockRouter,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ModeratePostCubit>.value(value: moderateCubit),
                BlocProvider<ModerationLogCubit>.value(value: logCubit),
              ],
              child: ModeratePostScreen(
                postUuid: 'post-uuid-1',
                post: _post,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('wide: both panes rendered', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => logCubit.state).thenReturn(
      const ModerationLogState.loaded([]),
    );
    when(() => moderateCubit.state).thenReturn(
      const ModeratePostState.initial(),
    );

    await tester.pumpWidget(
      buildWide(
        logState: const ModerationLogState.loaded([]),
      ),
    );
    await tester.pump();

    expect(find.byType(PostContentView), findsOneWidget);
    expect(find.byType(ModerationPanel), findsOneWidget);
  });

  testWidgets('wide: Approve and Request Changes buttons present and enabled', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildWide(
        logState: const ModerationLogState.loaded([]),
      ),
    );
    await tester.pump();

    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Request Changes'), findsOneWidget);

    final approveBtn = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Approve'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(approveBtn.onPressed, isNotNull);
  });

  testWidgets('wide: buttons disabled when ModeratePostCubit is loading', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildWide(
        moderateState: const ModeratePostState.loading(),
        logState: const ModerationLogState.loaded([]),
      ),
    );
    await tester.pump();

    final approveBtn = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Approve'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(approveBtn.onPressed, isNull);

    final requestBtn = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Request Changes'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(requestBtn.onPressed, isNull);
  });

  testWidgets('wide: ModerationLogCubit.load() triggered on mount', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildWide());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => logCubit.load('post-uuid-1')).called(greaterThanOrEqualTo(1));
  });

  testWidgets('wide: success state triggers router.pop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StreamController<ModeratePostState>.broadcast();
    await tester.pumpWidget(
      buildWide(
        moderateStream: controller.stream,
      ),
    );
    await tester.pump();

    controller.add(
      const ModeratePostState.success(PostStatus.approved),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => mockRouter.pop()).called(1);
    await controller.close();
  });

  testWidgets('wide: error state shows snackbar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StreamController<ModeratePostState>.broadcast();
    await tester.pumpWidget(
      buildWide(
        moderateStream: controller.stream,
      ),
    );
    await tester.pump();

    controller.add(
      const ModeratePostState.error(Failure.forbidden(message: 'x')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('You do not have permission to moderate this post'),
      findsOneWidget,
    );
    await controller.close();
  });
}
